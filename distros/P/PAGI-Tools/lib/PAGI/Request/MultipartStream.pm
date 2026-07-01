package PAGI::Request::MultipartStream;
$PAGI::Request::MultipartStream::VERSION = '0.002001';
use strict;
use warnings;

use Future::AsyncAwait;
use Carp qw(croak);
use HTTP::MultiPartParser;

=head1 NAME

PAGI::Request::MultipartStream - Pull-based streaming multipart/form-data engine

=head1 SYNOPSIS

    use PAGI::Request::MultipartStream;
    use Future::AsyncAwait;

    # Usually obtained via $req->multipart_stream, not constructed directly:
    my $stream = $req->multipart_stream;

    while (defined(my $part = await $stream->next)) {
        if ($part->is_file) {
            await $part->stream_to_file($path);
        }
        else {
            my $value = await $part->value;  # raw bytes; you decode
        }
    }

=head1 DESCRIPTION

A pull-based streaming parser for C<multipart/form-data> request bodies. Each
part of the body is exposed in turn as a L<PAGI::Request::Part> via C<next>,
and B<the application decides where each part goes>: you choose its sink (a
file, an object store, an async transform) per part, rather than accepting the
buffered, spool-each-upload-to-a-temp-file behaviour of C<form_params> and
C<upload> in L<PAGI::Request>.

Because you own the sink, it can be fully asynchronous: C<stream_to> awaits a
sink that returns a Future, so a slow downstream naturally backpressures the
read. This is what the buffered multipart path cannot offer -- its spool to a
temp file is blocking.

Internally this drives L<HTTP::MultiPartParser> on demand, bridging its
push-based callbacks onto an internal event queue that C<next> and the part
methods consume.

B<Mutually exclusive with the buffered body methods.> An HTTP request body can
only be consumed once. Once you create a multipart stream you cannot also call
C<body>/C<text>/C<json>/C<form_params>/C<uploads>, and a stream cannot be
created if the body was already read; see L<PAGI::Request/multipart_stream>.

=cut

our $MAX_FILES        = 1000;
our $MAX_FIELDS       = 1000;
our $MAX_FIELD_SIZE   = 1024 * 1024;          # buffered per-field cap
our $MAX_FILE_SIZE    = 100 * 1024 * 1024;
our $MAX_REQUEST_BODY = 1024 * 1024 * 1024;   # defense-in-depth; server max_body_size is primary

=head1 CONSTRUCTOR

=head2 new

    my $stream = PAGI::Request::MultipartStream->new(
        receive          => $receive,   # required: PAGI receive callback
        boundary         => $boundary,  # required: multipart boundary
        max_files        => 1000,       # optional limits (defaults shown)
        max_fields       => 1000,
        max_field_size   => 1024 * 1024,
        max_file_size    => 100 * 1024 * 1024,
        max_request_body => 1024 * 1024 * 1024,
    );

Creates a new streaming multipart engine. Most applications do not call this
directly -- they obtain a ready-built stream from
L<PAGI::Request/multipart_stream>, which extracts the boundary from the
request's C<Content-Type> and passes through the same limit options.

C<receive> and C<boundary> are required. The remaining options cap the body to
bound memory and resource use:

=over 4

=item * C<max_files> - Maximum number of file parts. Default: 1000.

=item * C<max_fields> - Maximum number of non-file (field) parts. Default: 1000.

=item * C<max_field_size> - Maximum size, in bytes, of any single field part.
Default: 1 MiB (1024 * 1024).

=item * C<max_file_size> - Maximum size, in bytes, of any single file part.
Default: 100 MiB (100 * 1024 * 1024).

=item * C<max_request_body> - Maximum total bytes read from the request body.
Default: 1 GiB (1024 * 1024 * 1024). This is a per-stream defence-in-depth
cap; the PAGI server's C<max_body_size> is the primary aggregate limit on the
request body.

=back

=cut

sub new {
    my ($class, %args) = @_;
    croak "receive is required"  unless $args{receive};
    croak "boundary is required" unless defined $args{boundary} && length $args{boundary};
    my $self = bless {
        receive          => $args{receive},
        boundary         => $args{boundary},
        max_files        => $args{max_files}        // $MAX_FILES,
        max_fields       => $args{max_fields}       // $MAX_FIELDS,
        max_field_size   => $args{max_field_size}   // $MAX_FIELD_SIZE,
        max_file_size    => $args{max_file_size}    // $MAX_FILE_SIZE,
        max_request_body => $args{max_request_body} // $MAX_REQUEST_BODY,
        _queue       => [],        # FIFO: ['part',\%meta] | ['body',$chunk]
        _file_count  => 0,
        _field_count => 0,
        _bytes_total => 0,
        _cur_is_file => 0,
        _cur_bytes   => 0,
        _cur_name    => undef,
        _current     => undef,     # current Part
        _exhausted   => 0,
        _parser_finished => 0,     # guard: finish() is called at most once
        _failed      => undef,     # sticky failure message (poisons the stream)
    }, $class;
    $self->{_parser} = $self->_build_parser;
    return $self;
}

# Parse the on_header arrayref of header lines into
# {name,filename,content_type,encoding,headers}. is_file := defined(filename).
sub _disposition {
    my ($lines) = @_;

    # $lines is an arrayref of raw header lines, e.g.
    # 'Content-Disposition: form-data; name="x"'
    my %headers;
    for my $line (@$lines) {
        if ($line =~ /^([^:]+):\s*(.*)$/) {
            $headers{lc($1)} = $2;
        }
    }

    my $disposition = _parse_content_disposition(\%headers);

    return {
        name         => $disposition->{name},
        filename     => $disposition->{filename},
        content_type => $headers{'content-type'} // 'text/plain',
        encoding     => $headers{'content-transfer-encoding'},
        headers      => \%headers,
    };
}

sub _parse_content_disposition {
    my ($headers) = @_;
    my $cd = $headers->{'content-disposition'} // '';

    my %result;

    # Parse name="value" pairs
    while ($cd =~ /(\w+)="([^"]*)"/g) {
        $result{$1} = $2;
    }
    # Also handle unquoted values
    while ($cd =~ /(\w+)=([^;\s"]+)/g) {
        $result{$1} //= $2;
    }

    return \%result;
}

sub _build_parser {
    my ($self) = @_;
    return HTTP::MultiPartParser->new(
        boundary  => $self->{boundary},
        on_header => sub {
            my ($headers) = @_;
            return if $self->{_failed};
            my $meta = _disposition($headers);
            my $is_file = defined $meta->{filename} ? 1 : 0;
            if ($is_file) {
                $self->{_failed} = "Too many file parts (max $self->{max_files})"
                    if ++$self->{_file_count} > $self->{max_files};
            } else {
                $self->{_failed} = "Too many field parts (max $self->{max_fields})"
                    if ++$self->{_field_count} > $self->{max_fields};
            }
            return if $self->{_failed};
            $self->{_cur_is_file} = $is_file;
            $self->{_cur_bytes}   = 0;
            $self->{_cur_name}    = $meta->{name};
            push @{$self->{_queue}}, ['part', $meta];
        },
        on_body => sub {
            my ($chunk, $final) = @_;
            return if $self->{_failed};
            $self->{_cur_bytes} += length $chunk;
            my $max = $self->{_cur_is_file} ? $self->{max_file_size} : $self->{max_field_size};
            if ($self->{_cur_bytes} > $max) {
                $self->{_failed} = sprintf("%s part '%s' too large (max %d bytes)",
                    ($self->{_cur_is_file} ? 'File' : 'Field'), ($self->{_cur_name} // ''), $max);
                return;                                  # stop enqueuing -- bounds the queue
            }
            push @{$self->{_queue}}, ['body', $chunk];
        },
        on_error => sub { $self->{_failed} //= "Multipart parse error: $_[0]" },
    );
}

# Feed exactly one network message. Returns true if it fed data, false at exhaustion.
async sub _pump {
    my ($self) = @_;
    return 0 if $self->{_exhausted};
    my $msg = await $self->{receive}->();
    if (!$msg || !$msg->{type} || $msg->{type} eq 'http.disconnect') {
        $self->{_exhausted} = 1;
        $self->_finish_parser if $self->{_bytes_total} > 0;   # 0 bytes => empty stream, clean EOF
        return 0;
    }
    if (defined $msg->{body} && length $msg->{body}) {
        $self->{_bytes_total} += length $msg->{body};
        if ($self->{_bytes_total} > $self->{max_request_body}) {
            $self->{_failed} = "Request body exceeded max_request_body ($self->{max_request_body} bytes)";
            $self->{_exhausted} = 1;
            return 0;
        }
        $self->{_parser}->parse($msg->{body});           # fires callbacks (enqueue + bookkeep)
    }
    unless ($msg->{more}) { $self->{_exhausted} = 1; $self->_finish_parser if $self->{_bytes_total} > 0; }
    return 1;
}

# Finalize the parser once bytes have been fed and the stream has ended.
# HTTP::MultiPartParser->finish on a complete stream (closing boundary already
# parsed) is a clean no-op; called mid-part it signals truncation. The parser
# routes that end-of-stream condition through on_error (which records into the
# sticky _failed) rather than dying, so the eval guard is defence-in-depth in
# case finish ever throws. When finish is what introduces the failure we reword
# it to a clear "incomplete upload" message; a pre-existing failure (e.g. a
# size-limit hit) is preserved untouched.
sub _finish_parser {
    my ($self) = @_;
    return if $self->{_parser_finished};
    $self->{_parser_finished} = 1;
    my $had_failure = defined $self->{_failed};
    eval { $self->{_parser}->finish; 1 } or $self->{_failed} //= "Multipart parse error (finish): $@";
    if (!$had_failure && defined $self->{_failed}) {   # finish introduced it => truncation
        $self->{_failed} = "Incomplete multipart upload: client disconnected or stream ended before the closing boundary";
    }
    return;
}

=head1 METHODS

=head2 next

    my $part = await $stream->next;

Returns a Future resolving to the next L<PAGI::Request::Part>, or C<undef> when
the stream is exhausted (end of body).

Advancing past a part whose body you have not fully consumed auto-drains the
remainder of that part first, so you can always loop on C<next> without
reading every part. To discard a part deliberately (and signal that intent),
call C<< $part->skip >>.

Croaks if a size or count limit is breached, or if the upload is truncated
(see L</LIMITS AND ERRORS>).

=cut

async sub next {
    my ($self) = @_;
    croak $self->{_failed} if $self->{_failed};
    if ($self->{_current} && !$self->{_current}{_done}) { await $self->{_current}->skip; }  # auto-drain
    while (1) {
        croak $self->{_failed} if $self->{_failed};
        shift @{$self->{_queue}} while @{$self->{_queue}} && $self->{_queue}[0][0] eq 'body';  # defensive
        if (@{$self->{_queue}} && $self->{_queue}[0][0] eq 'part') {
            my (undef, $meta) = @{ shift @{$self->{_queue}} };
            $self->{_current} = PAGI::Request::Part->new(stream => $self, meta => $meta);
            return $self->{_current};
        }
        last unless await $self->_pump;
    }
    croak $self->{_failed} if $self->{_failed};   # truncation surfaces via _failed (set by finish)
    return undef;
}

# Next body chunk for the current part: the chunk, or undef when the part ends.
async sub _next_chunk {
    my ($self) = @_;
    while (1) {
        croak $self->{_failed} if $self->{_failed};
        if (@{$self->{_queue}}) {
            my $kind = $self->{_queue}[0][0];
            if ($kind eq 'body') { my $ev = shift @{$self->{_queue}}; return $ev->[1]; }
            return undef if $kind eq 'part';             # next part began -> current done
        }
        if (!(await $self->_pump)) {
            croak $self->{_failed} if $self->{_failed};  # truncation surfaces via _failed (set by finish)
            return undef;                                # clean EOF (complete body, then disconnect)
        }
    }
}

package PAGI::Request::Part;
use strict;
use warnings;

use Future::AsyncAwait;
use Carp qw(croak);
use Fcntl qw(O_WRONLY O_CREAT O_EXCL O_NOFOLLOW);

=head1 NAME

PAGI::Request::Part - A single part of a streaming multipart request

=head1 DESCRIPTION

A value object representing one part yielded by
L<PAGI::Request::MultipartStream>. It carries the part's metadata (name,
filename, headers) and provides the methods that consume the part's body: pull
it chunk by chunk, buffer it whole, or drain it to a sink of your choosing.

A part's body must be consumed before the next part is fetched. Calling
C<< $stream->next >> while a part is only partially read drains the rest of
the current part automatically.

=head1 CONSTRUCTOR

=head2 new

    my $part = PAGI::Request::Part->new(stream => $stream, meta => \%meta);

Constructs a part bound to its owning stream. Parts are normally created by
L<PAGI::Request::MultipartStream/next>, not by application code.

=head1 METHODS

=head2 name

    my $name = $part->name;

The part's form field name, taken from its C<Content-Disposition> header.

=head2 filename

    my $filename = $part->filename;

The part's filename from C<Content-Disposition>, or C<undef> for non-file
(field) parts.

=head2 content_type

    my $type = $part->content_type;

The part's C<Content-Type> header. Defaults to C<text/plain> if the part sent
no C<Content-Type>.

=head2 encoding

    my $encoding = $part->encoding;

The part's C<Content-Transfer-Encoding> header, or C<undef> if not present.

=head2 headers

    my $headers = $part->headers;

A hashref of all the part's headers, keyed by lower-cased header name.

=head2 is_file

    if ($part->is_file) { ... }

True if the part has a filename (i.e. is a file upload), false otherwise.

=head2 type

    my $type = $part->type;   # 'file' or 'field'

Returns the string C<'file'> for file parts and C<'field'> for non-file parts.

=head2 next_chunk

    my $chunk = await $part->next_chunk;

Returns this part's next body chunk as raw bytes, or C<undef> once the part's
body is exhausted. This is the low-level primitive; C<value>, C<stream_to>,
and C<stream_to_file> are built on it.

=head2 value

    my $bytes = await $part->value;

Buffers and returns the part's entire body as B<raw bytes> -- no decoding is
applied, so a text field encoded as UTF-8 (or any other charset) must be
decoded by the caller. Intended for small field parts; the buffered size is
bounded by the relevant per-part size limit (C<max_field_size> for fields,
C<max_file_size> for files), which croaks if exceeded.

=head2 stream_to

    my $count = await $part->stream_to($cb);
    my $count = await $part->stream_to(async sub ($chunk) { await $sink->write($chunk) });

Drains the rest of the part to a sink callback, returning the number of bytes
processed. The callback is invoked with each chunk of raw bytes and may be
asynchronous: if it returns a Future, C<stream_to> awaits it before reading
the next chunk, giving the sink natural backpressure over the network read.

If the sink callback throws, the error poisons the stream -- a later
C<< $stream->next >> will croak -- and the failed part is B<not> auto-drained,
since the application has signalled it is aborting. The exception is re-thrown
to the caller.

=head2 stream_to_file

    my $count = await $part->stream_to_file($path);

Writes the part's body to a B<new> file at C<$path>, returning the number of
bytes written. The file is opened with C<O_CREAT|O_EXCL|O_NOFOLLOW>: the call
B<refuses to overwrite an existing path or to follow a symlink>, croaking
instead. The result of C<close> is checked. On any error -- a write failure, a
limit breach, a truncated upload, or a failed C<close> -- the partially
written file is unlinked before the method croaks.

=head2 skip

    await $part->skip;

Drains and discards any remaining body of this part. Use this to deliberately
ignore a part; C<< $stream->next >> would otherwise drain it for you anyway.

=head1 LIMITS AND ERRORS

Size and count limits are enforced as bytes arrive from the network, before
your sink ever sees them, so an oversized part cannot stream partway into your
sink before being rejected. A per-part size overflow names the offending part
in its error message (for example, C<< File part 'avatar' too large >>).
Exceeding C<max_files>, C<max_fields>, or C<max_request_body> likewise causes
the next C<next>/consume call to croak.

A client disconnect that truncates a part mid-stream croaks with an
C<"Incomplete multipart upload"> message (the closing boundary was never
seen). By contrast, a complete body -- or an entirely empty one -- followed by
a disconnect ends cleanly, with C<next> simply returning C<undef>.

=head1 SEE ALSO

L<PAGI::Request>, L<PAGI::Request::BodyStream>

=cut

sub new { my ($c,%a)=@_; bless { stream=>$a{stream}, meta=>$a{meta}, _done=>0 }, $c }
sub name         { $_[0]{meta}{name} }
sub filename     { $_[0]{meta}{filename} }
sub content_type { $_[0]{meta}{content_type} }
sub encoding     { $_[0]{meta}{encoding} }
sub headers      { $_[0]{meta}{headers} }
sub is_file      { defined $_[0]{meta}{filename} ? 1 : 0 }
sub type         { $_[0]->is_file ? 'file' : 'field' }
async sub skip   { my $s=shift; 1 while defined(await $s->{stream}->_next_chunk); $s->{_done}=1; return; }

async sub next_chunk {
    my ($self) = @_;
    return undef if $self->{_done};
    my $chunk = await $self->{stream}->_next_chunk;
    $self->{_done} = 1 unless defined $chunk;
    return $chunk;
}

async sub value {                              # buffer the whole part (small fields). RAW BYTES.
    my ($self) = @_;
    my $buf = '';
    while (defined(my $c = await $self->next_chunk)) { $buf .= $c }
    return $buf;
}

async sub stream_to {                          # drain to a (possibly async) sink callback
    my ($self, $cb) = @_;
    croak "callback is required" unless $cb;
    my $n = 0;
    my $ok = eval {
        while (defined(my $c = await $self->next_chunk)) {
            my $r = $cb->($c);
            await $r if ref $r && $r->can('get');  # allow an async sink (returns a Future)
            $n += length $c;
        }
        1;
    };
    if (!$ok) {
        my $err = $@;
        # poison the stream so a later ->next croaks; do NOT auto-drain (the app aborted)
        $self->{stream}{_failed} //= "sink error: $err";
        die $err;
    }
    return $n;
}

async sub stream_to_file {
    my ($self, $path) = @_;
    croak "path is required" unless defined $path;
    sysopen(my $fh, $path, O_WRONLY|O_CREAT|O_EXCL|O_NOFOLLOW, 0600)
        or croak "Cannot create $path: $!";
    binmode $fh;
    my $written = 0;
    my $ok = eval {
        while (defined(my $c = await $self->next_chunk)) {
            print $fh $c or die "write to $path failed: $!\n";
            $written += length $c;
        }
        1;
    };
    my $err      = $@;
    my $close_ok = close $fh;
    if (!$ok) { unlink $path; croak $err; }                       # write/limit/disconnect error wins
    unless ($close_ok) { unlink $path; croak "Cannot close $path: $!"; }
    return $written;
}

1;
