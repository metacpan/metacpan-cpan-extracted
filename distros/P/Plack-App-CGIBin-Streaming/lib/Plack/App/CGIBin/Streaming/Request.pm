package Plack::App::CGIBin::Streaming::Request;

use 5.014;
use strict;
use warnings;
no warnings 'uninitialized';
use Carp;

my %trace=
   (
    # new=>sub {warn "NEW: @_"},
    # header=>sub {warn "HEADER: @_"},
    # flush=>sub {warn "FLUSH: @_"},
    # status_out=>sub {warn "STATUS OUT: @_"},
    # content=>sub {warn "CONTENT: @_"},
    # finalize_start=>sub {warn "FINALIZE START: @_"},
    # finalize_end=>sub {warn "FINALIZE END: @_"},
   );
use constant TRACE=>0; do {
    no warnings 'void';
    sub {
        my $what=shift;
        local $SIG{__WARN__};
        $trace{$what} and $trace{$what}->(@_);
    };
};

our @attr;

our $DEFAULT_CONTENT_TYPE='text/plain';
our $DEFAULT_MAX_BUFFER=8000;

BEGIN {
    @attr=(qw/env responder writer _buffer _buflen _headers max_buffer
              content_type filter_before filter_after on_status_output
              parse_headers _header_buffer status notes on_flush on_finalize
              suppress_flush binmode_ok/);
    for (@attr) {
        my $attr=$_;
        no strict 'refs';
        *{__PACKAGE__.'::'.$attr}=sub : lvalue {
            my $I=$_[0];
            $I->{$attr}=$_[1] if @_>1;
            $I->{$attr};
        };
    }
}

sub new {
    my $class=shift;
    $class=ref($class) || $class;
    my $self=bless {
                    content_type=>$DEFAULT_CONTENT_TYPE,
                    max_buffer=>$DEFAULT_MAX_BUFFER,
                    filter_before=>sub{},
                    filter_after=>sub{},
                    on_status_output=>sub{},
                    on_flush=>sub{},
                    on_finalize=>sub{},
                    notes=>+{},
                    _headers=>[],
                    _buffer=>[],
                    _buflen=>0,
                    status=>200,
                   }, $class;

    for( my $i=0; $i<@_; $i+=2 ) {
        my $method=$_[$i];
        $self->$method($_[$i+1]);
    }

    if (TRACE) {
        (ref(TRACE) eq 'CODE'
         ? TRACE->(new=>$self)
         : warn "NEW $self");
    }

    return $self;
}

sub print_header {
    my $self = shift;

    croak "KEY => VALUE pairs expected" if @_%2;
    croak "It's too late to set a HTTP header" if $self->{writer};

    if (TRACE) {
        (ref(TRACE)
         ? TRACE->(header=>$self, @_)
         : warn "print_header $self: @_");
    }

    push @{$self->{_headers}}, @_;
}

sub print_content {
    my $self = shift;

    if ($self->{parse_headers}) {
        $self->{_header_buffer}.=join('', @_);
        while( $self->{_header_buffer}=~s/\A(\S+)[ \t]*:[ \t]*(.+?)\r?\n// ) {
            my ($hdr, $val)=($1, $2);
            if ($hdr=~/\Astatus\z/i) {
                $self->{status}=$val;
            } elsif ($hdr=~/\Acontent-type\z/i) {
                $self->{content_type}=$val;
            } else {
                $self->print_header($hdr, $val);
            }
        }
        if ($self->{_header_buffer}=~s/\A\r?\n//) {
            delete $self->{parse_headers}; # done
            $self->print_content(delete $self->{_header_buffer})
                if length $self->{_header_buffer};
        }
        return;
    }

    my @data=@_;
    $self->{filter_before}->($self, \@data);

    my $len = 0;
    $len += length $_ for @data;

    if (TRACE) {
        (ref(TRACE)
         ? TRACE->(content=>$self, @data)
         : warn "print_content $self: $len bytes");
    }

    push @{$self->{_buffer}}, @data;
    $len += $self->{_buflen};
    $self->{_buflen}=$len;

    if ($len > $self->{max_buffer}) {
        local $self->{suppress_flush};
        $self->flush;
    }

    $self->filter_after->($self, \@data);
}

sub _status_out {
    my $self = shift;
    my $is_done = shift;

    if (TRACE) {
        (ref(TRACE)
         ? TRACE->(status_out=>$self, $is_done)
         : warn "status_out $self: $self->{status}");
    }

    $self->print_header('Content-Type', $self->{content_type});
    $self->print_header('Content-Length', $self->{_buflen})
        if $is_done;
    $self->on_status_output->($self);

    $self->{writer}=$self->{responder}->([$self->{status},
                                          $self->{_headers},
                                          $is_done ? $self->{_buffer}: ()]);
}

sub status_written {
    my $self = shift;
    return !!$self->{writer};
}

sub flush {
    my $self = shift;
    return 0 unless @{$self->{_buffer}};

    if (TRACE) {
        (ref(TRACE)
         ? TRACE->(flush=>$self)
         : warn "flush $self");
    }

    $self->_status_out unless $self->{writer};

    $self->{writer}->write(join '', @{$self->{_buffer}});
    @{$self->{_buffer}}=();
    $self->{_buflen}=0;

    $self->{on_flush}->($self);

    return 0;
}

sub finalize {
    my $self = shift;

    if (TRACE) {
        (ref(TRACE)
         ? TRACE->(finalize_start=>$self)
         : warn "finalize start $self");
    }

    $self->{on_finalize}->($self);
    if ($self->{writer}) {
        $self->{writer}->write(join '', @{$self->{_buffer}});
        $self->{writer}->close;
    } else {
        $self->_status_out(1);
    }

    if (TRACE) {
        (ref(TRACE)
         ? TRACE->(finalize_end=>$self)
         : warn "finalize end $self");
    }

    %$self=();
    bless $self, 'Plack::App::CGIBin::Streaming::Request::Demolished';
}

package                         # prevent CPAN indexing
    Plack::App::CGIBin::Streaming::Request::Demolished;
use strict;

sub AUTOLOAD {
    our $AUTOLOAD;
    die "Calling $AUTOLOAD on a demolished request.";
}

sub flush {}
sub finalize {}
sub DESTROY {}

1;

__END__

=encoding utf-8

=head1 NAME

Plack::App::CGIBin::Streaming::Request - a helper module for
Plack::App::CGIBin::Streaming

=head1 SYNOPSIS

 my $r=Plack::App::CGIBin::Streaming::Request->new(
     env => $env,               # set the PSGI environment
     responder => $responder,   # set the responder (streaming protocol)
     max_buffer => 20000,
     parse_headers => 1,
     content_type => 'text/html; charset=utf-8',
     filter_before => sub {...},
     filter_after => sub {...},
     on_status_output => sub {...},
     on_flush => sub {...},
     on_finalize => sub {...},
 );

 $r->writer=$writer;            # set the writer (streaming protocol)

 $r->notes->{key}=$value;
 $r->status=404;
 $r->content_type='text/html; charset=iso-8859-15';
 $r->parse_headers=1;

 $r->print_header(key=>$value, ...);
 $r->print_content(@content);
 $r->flush;
 warn "It's too late to set the HTTP status" if $r->status_written;

 $r->finalize;

 $r->env;                       # access the PSGI environment

=head1 DESCRIPTION

Every object of this class represents an HTTP request in the
L<Plack::App::CGIBin::Streaming> environment.

An L<Plack::App::CGIBin::Streaming> application creates the object. It is
then accessible by the actual CGI script.

To write a normal CGI script you don't need to know about this module.

=head2 Methods

The methods of this module can be categorized into several groups:

=over 4

=item * public methods to be used by CGI scripts

=item * methods or parameters mainly passed to the constructor

=item * methods to be used by the L<Plack::App::CGIBin::Streaming> system

=item * private stuff

=back

=head3 Public Methods

=over 4

=item $r-E<gt>status($status)

represents the current HTTP status of the request. You can assign new values
at any time. However, to have any effect on the HTTP response it must be
called before C<status_written> becomes true.

=item $r-E<gt>status_written

returns false if C<print_header>, C<status> or C<content_type> affect the
HTTP response seen by the client.

=item $r-E<gt>content_type($type)

represents the current C<Content-Type> of the request. You can assign new values
at any time. However, to have any effect on the HTTP response it must be
called before C<status_written> becomes true.

=item $r-E<gt>print_header($headername, $headervalue, ...)

sets HTTP headers.

Both, C<headername> and C<headervalue>, must not contain wide characters.

=item $r-E<gt>print_content($content, ...)

prints to the response body. This output is buffered up to the first
C<flush> call. The buffer is automatically flushed when its size exceeds
C<max_buffer> bytes.

The printed content must not contain wide characters.

In the L<Plack::App::CGIBin::Streaming> environment, this method is
automatically called when you print to C<STDOUT>. To be UTF8-safe, best
if you push the utf8 PerlIO layer and use C<print>.

 binmode STDOUT, ':utf8';

=item $r-E<gt>flush

flushes the currently buffered output. The first flush operation also
sends out the HTTP headers and the response status.

If nothing is currently buffered, C<flush> returns immediately. It won't
send out only the HTTP headers. If you really want to do that, use
C<< $r->_status_out >>.

=item $r-E<gt>notes

returns a hash reference where you can store data that is to be thrown away
when the request is finished. (similar to C<< $r->pnotes >> in modperl)

=item $r-E<gt>env

returns the PSGI environment hash of the request.

=back

=head3 Constructor Parameters

All of these parameters are also accessible as lvalue methods on the object.
If called with a value, the value is assigned to the parameter. In any case
the parameter value is returned and in lvalue context can be assigned to.

So,

 $r->flag=$val

and

 $r->flag($val)

is the same, except that former is probably a bit faster. You could even

 $r->flag($dummy)=$val

However, that does not make much sense.

=over 4

=item status

=item content_type

=item env

=item notes

These methods are implemented as constructor parameters. That's why they are
mentioned here. They are documented already above.

Default values for C<status> and C<content_type> are C<200> and C<text/plain>.
They can be changed by means of the C<request_params> parameter in the
F<*.psgi> file like:

 Plack::App::CGIBin::Streaming->new(
     root=>...,
     request_params=>[
         status=>404,
         content_type=>'text/html; charset=utf-8',
         ...
     ]
 )->to_app;

The default content type can also be set by assigning to
C<$Plack::App::CGIBin::Streaming::Request::DEFAULT_CONTEN_TYPE>.

=item max_buffer

The max. amount of data buffered by C<print_content>. For best performance,
you need to find a trade-off between RAM consumption and buffering.

A HTTP/1.1 server like L<Starman> will use C<chunked> transfer encoding
if at the time the HTTP header fields are sent the content length is
not determined. This usually shows worse performance than sending the whole
response in one go.

If your response body is shorter that C<max_buffer> bytes and you never
call C<flush>, the request object will figure out the content length for
you and send the response in one chunk.

The default value for C<max_buffer> is 8000. This is enough for most AJAX
responses but probably far too low for HTML pages.

Usually the value is set as configuration parameter in the F<*.psgi>
file like

 Plack::App::CGIBin::Streaming->new(
     root=>...,
     request_params=>[
         max_buffers=>50000,
         ...
     ]
 )->to_app;

Though, you can set it at any time. It will affect all subsequent
C<print_content> calls.

=item parse_headers

to have any effect this option must be set before the first
C<print_content> call. Usually it is set as configuration parameter in
the F<*.psgi> file like

 Plack::App::CGIBin::Streaming->new(
     root=>...,
     request_params=>[
         parse_headers=>1,
         ...
     ]
 )->to_app;

If set, the request object parses the data stream passed to C<print_content>
for HTTP header fields. When the header block is parsed, the parameter is
automatically reset to false to prevent further parsing. This means the
value changes over the lifetime of the request.

If set, you can send your response including HTTP headers like this:

 print STDOUT <<'EOF';
 Status: 404
 X-reason: the device is currently not mounted

 <html>
 ...
 </html>
 EOF

=item filter_before

=item filter_after

These 2 parameters can be used to filter the print output. Both are assigned
coderefs like

 Plack::App::CGIBin::Streaming->new(
     root=>...,
     request_params=>[
         filter_before=>sub {
             my ($request, $list);
             ...
         },
         filter_after=>sub {
             my ($request, $list);
             ...
         },
         ...
     ]
 )->to_app;

The coderefs are called with 2 parameters. The first one is the request
object, the 2nd one is an array of strings to be printed.

C<filter_before> is called before actually printing. If you need to modify
the output, that's the place to do it. Just modify the C<$list>.

C<filter_after> is called after the printing. It can be used for example to
flush after the C<< <head> >> section is put out.

There is no filter queue. If you need to implement that, best if you
daisy-chain the filters like:

 sub insert_before_filter {
     my $app=shift;
     my $filter=shift;

     unless ($app->request_params) {
         $app->request_params=[filter_before=$filter];
         return;
     }
     my $list=$app->request_params;
     for (my $i=0; $i<@$list; $i+=2) {
         if ($list->[$i] eq 'filter_before') {
             my $old_filter=$list->[$i+1];
             $list->[$i+1]=sub {
                 my ($r, $data)=@_;
                 $filter->($r, $data);
                 $old_filter->($r, $data);
             }
             return;
         }
     }
     push @$list, filter_before=>$filter;
     return;
 }

Alternatively, you can implement a new module that inherits from this one
and pass the name as C<request_class> to the app constructor like:

 Plack::App::CGIBin::Streaming->new(
     root=>...,
     request_class=>'My::Request::Class',
 )->to_app;

To remove a filter just assign an empty subroutine:

 $r->filter_before=sub {};

This can also be done from within a filter when you know you are done.

=item on_status_output

=item on_flush

=item on_finalize

These parameters are also coderefs. All of them are called with one parameter,
the request object.

C<on_status_output> is called just before the HTTP status and the HTTP
header fields are sent to the client. It can be used to inspect the
headers one last time and to perhaps append another one.

There is one use case in particular where you might want to this hook.
Proxy servers like nginx usually also buffer your response body. But
they allow to turn that off by means of a HTTP output header.

 Plack::App::CGIBin::Streaming->new(
     root=>...,
     request_params=>[
         on_status_out=>sub {
             my $r=$_[0];

             $r->print_header('X-Accel-Buffering', 'no')
                 if $r->status==200 and $r->content_type=~m!^text/html!i;
         },
         ...
     ]
 )->to_app;

C<on_flush> is called after every flush operation.

C<on_finalize> is called before the request is finished. Actually, it's
the first step of the C<finalize> operation. At this stage you are still able
to print stuff. So, it's a good place to add a footer or similar.

=item suppress_flush

In Perl, there is a number of operations that implicitly preform flush
operations on file handles, like C<system>.

If you want complete control over when flush is issued, set this to a true
value. It does not affect C<< $r->flush >> calls or implicit flushes caused
by overflowing the output buffer (see C<max_buffer>). This flag only affects
flushes caused by the PerlIO layer. So, if true, output is buffered even if
C<$|> (autoflush) is true for the file handle.

Note, this requires the L<Plack::App::CGIBin::Streaming::IO> PerlIO layer
to be pushed onto the file handle. In the L<Plack::App::CGIBin::Streaming>
environment, this is usually the case for C<STDOUT>.

=back

=head3 Methods mainly used by the L<Plack::App::CGIBin::Streaming> system

=over 4

=item responder

=item writer

Here the responder and write callbacks are stored that implement the
PSGI streaming protocol.

=item finalize

This method is called by L<Plack::App::CGIBin::Streaming> after the compiled
CGI script returns. It prints out the remaining buffers and it makes the
request object almost unusable. So, even if you by accident save the request
object in a closure or similar, you cannot print to it. This is achieved by
reblessing the object into another class and scraping out the guts of the
object.

The only methods allowed on the reblessed object are C<flush>, C<finalize>
and C<DESTROY>.

=back

=head3 Internal Methods

=over 4

=item _buffer

=item _buflen

=item _headers

=item _header_buffer

these are just internal variables

=item _status_out

this method is called to put out the HTTP status and header fields.

=back

=head1 AUTHOR

Torsten Förtsch E<lt>torsten.foertsch@gmx.netE<gt>

=head1 COPYRIGHT

Copyright 2014 Binary.com

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). A copy of the full
license is provided by the F<LICENSE> file in this distribution and can
be obtained at

L<http://www.perlfoundation.org/artistic_license_2_0>

=head1 SEE ALSO

=over 4

=item * L<Plack::App::CGIBin::Streaming>

=back

=cut
