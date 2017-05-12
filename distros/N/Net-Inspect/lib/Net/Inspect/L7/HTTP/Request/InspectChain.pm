############################################################################
# deep inspection into HTTP response
# umcompresses, updates response header and provides hooks to manipulate
# request and response header and body
############################################################################

use strict;
use warnings;
package Net::Inspect::L7::HTTP::Request::InspectChain;
use base 'Net::Inspect::Flow';
use fields qw(conn meta rqhdr rphdr hooks info);
use Hash::Util 'lock_keys';
use Carp;
use HTTP::Request;
use HTTP::Response;
use Compress::Raw::Zlib;
use Net::Inspect::Debug qw(debug trace $DEBUG);
use Scalar::Util 'weaken';

############################################################################
# creation of object, adding hooks etc
############################################################################

# initialize or clone hooks on creation
sub new {
    my $class = shift;
    my $self = $class->SUPER::new(@_);
    my %hooks;
    if ( ! ref($class)) {
	%hooks = (
	    request_header  => undef,
	    request_body    => undef,
	    response_header => undef,
	    response_body   => undef,
	    chunk_header    => undef,
	    chunk_trailer   => undef,
	);
    } else {
	# clone hooks
	while ( my ($k,$v) = each %{ $class->{hooks} } ) {
	    if ( ! $v ) {
		$hooks{$k} = $v
	    } else {
		$hooks{$k} = [ map { [ @$_ ] } @$v ];
	    }
	}
    }

    lock_keys(%hooks);
    $self->{hooks} = \%hooks;
    return $self;
}

# create new request, set conn to connection of request so we can
# better react when fatal
{
    sub new_request {
	my ($self,$meta,$conn) = @_;
	my $obj = $self->new;
	if ($obj->{upper_flow}) {
	    $obj->{upper_flow} = $obj->{upper_flow}->new_request($meta)
		or return;
	}
	weaken($obj->{conn} = $conn);
	$obj->{meta} = $meta;
	return $obj;
    }
}

# forward fatal to connection
sub fatal {
    my ($self,$reason,$dir,$time) = @_;
    return $self->{conn}->fatal($self->{meta}{reqid}.' '.$reason,$dir,$time);
}

sub xdebug {
    $DEBUG or return;
    my $self = shift;
    my $msg = shift;
    $msg = "$$.$self->{conn}{connid}.$self->{meta}{reqid} $msg";
    unshift @_,$msg;
    goto &debug;
}

sub xtrace {
    my $self = shift;
    my $msg = shift;
    $msg = "$$.$self->{conn}{connid}.$self->{meta}{reqid} $msg";
    unshift @_,$msg;
    goto &trace;
}

# for logging
sub id {
    my $self = shift;
    return "$$.$self->{conn}{connid}.$self->{meta}{reqid}";
}

# add inspection hook
my %predefined_hooks = (
    'uncompress_ce' => {
	request_header  => \&_rqhdr_uncompress_ce,
	response_header => \&_rphdr_uncompress_ce,
	response_body   => undef, # reserve place
    },
    'uncompress_te' => {
	response_header => \&_rphdr_uncompress_te,
	response_body   => undef, # reserve place
    },
    'unchunk'    => {
	response_header => \&_rphdr_unchunk,
	chunk_header    => undef,
	chunk_trailer   => undef,
    },
);
sub add_hooks {
    my ($self,@hooks) = @_;
    my ($pos,%wpos,%opt);
    for( my $i=0;$i<@hooks;$i++) {
	my ($hook,$name);
	if ( ref($hooks[$i]) ) {
	    $hook = $hooks[$i];
	} elsif ( $hooks[$i] =~ m{^(\d+)$} ) {
	    $pos = $1;
	    %wpos = ();
	    next;
	} elsif ( $hooks[$i] =~ m{^-[\w_-]+$} ) {
	    # option with value
	    $opt{$hooks[$i]} = $hooks[$i+1];
	    $i++;
	    next;
	} else {
	    $hook = $predefined_hooks{$hooks[$i]}
		or croak "no predefined hook $hooks[$i]";
	    $name = $hooks[$i]
	}
	$name ||= $hook->{name};
	while (my ($where,$cb) = each %$hook) {
	    $where eq 'name' and next;
	    my @c = caller(0);
	    my $h = $self->{hooks}{$where}||= [];
	    if ( ! defined $wpos{$where} ) {
		$wpos{$where} = defined($pos) && $pos < @$h ? $pos : @$h;
	    }
	    splice(@$h,$wpos{$where},0, [
		$name,
		'',
		! $cb ? undef: (ref($cb) eq 'CODE') ? $cb : @$cb,
		%opt,
	    ]);
	    $wpos{$where}++;
	}
    }
}

sub update_hook {
    my ($self,$name,$hook,%opt) = @_;
    while (my ($where,$cb) = each %$hook) {
	$where eq 'name' and next;
	my $wh = $self->{hooks}{$where} or next;
	my $found;
	for(@$wh) {
	    $_->[0] eq $name or next;
	    @$_ = (
		$name,
		$_->[1],
		! $cb ? undef : (ref($cb) eq 'CODE') ? $cb : @$cb,
		%opt,
	    );
	    $found = 1;
	    last;
	}
	die "no hook $name found for $where" if ! $found;
    }
}


############################################################################
# helper for hooks
############################################################################

# returns request header as HTTP::Request
# can also be used to set header
sub request_header {
    my $self = shift;
    $self->{rqhdr} = shift if @_;
    my $hdr = $self->{rqhdr} or croak("no request header known");
    if ( ! ref($hdr)) {
	$hdr = eval { HTTP::Request->parse($hdr) }
	    or return $self->fatal("cannot parse HTTP header: $@");
	$self->{rqhdr} = $hdr;
    }
    return $hdr;
}

# returns response header as HTTP::Response
# can also be used to set header
sub response_header {
    my $self = shift;
    $self->{rphdr} = shift if @_;
    my $hdr = $self->{rphdr} or croak("no response header known");
    if ( ! ref($hdr)) {
	$hdr = eval { HTTP::Response->parse($hdr) }
	    or return $self->fatal("cannot parse HTTP header: $@");
	$self->{rphdr} = $hdr;
    }
    return $hdr;
}

############################################################################
# redefined in_* methods which apply hooks before calling original method
############################################################################

sub in_data {
    my ($self,$dir,$data,$eof,$time) = @_;
    # will ignore all SSL, Websockets... stuff for now
    return length($data);
}

sub in_request_header {
    my ($self,$data,$time) = @_;
    $self->{rqhdr} = $data;
    if ( my $hooks = $self->{hooks}{request_header} ) {
	# hooks might be dynamically added inside a previous hook
	for(my $i=0;$i<@$hooks;$i++) {
	    my (undef,undef,$sub,@arg) = @{ $hooks->[$i] };
	    $sub or next;
	    my $changed = $sub->($self,\$data,$time,@arg);
	    defined $changed or return;
	    $self->{rqhdr} = $data if $changed; # re-parse
	}
    }
    return $self->{upper_flow}->in_request_header($data,$time)
	if $self->{upper_flow};
    return 1;
}

sub in_response_header {
    my ($self,$data,$time) = @_;
    $self->{rphdr} = $data;
    if ( my $hooks = $self->{hooks}{response_header} ) {
	# hooks might be dynamically added inside a previous hook
	for(my $i=0;$i<@$hooks;$i++) {
	    my (undef,undef,$sub,@arg) = @{ $hooks->[$i] };
	    $sub or next;
	    my $changed = $sub->($self,\$data,$time,@arg);
	    defined $changed or return;
	    $self->{rphdr} = $data if $changed; # re-parse
	}
    }
    return $self->{upper_flow}->in_response_header($data,$time)
	if $self->{upper_flow};
    return 1;
}

sub in_request_body {
    my ($self,$data,$eof,$time) = @_;
    croak "gaps not supported in_request_body" if ref($data);
    my $bytes = length($data);
    my $hooks = $self->{hooks}{request_body};
    my $lasthook;
    if ( $hooks ) {
	$self->xdebug("got hooks");
	# hooks might be dynamically added inside a previous hook
	my $ref = \$data;
	for(my $i=0;$i<@$hooks;$i++) {
	    my (undef,undef,$sub,@arg) = @{ $hooks->[$i] };
	    $sub or next;
	    my $processed = $sub->($self,$ref,$eof,$time,@arg);
	    $bytes -= length($$ref) if $i == 0;
	    defined $processed or return;
	    $hooks->[$i][1].= $processed;
	    $ref = \$hooks->[$i][1];
	    $lasthook = $i;
	}
	$data = $$ref if defined $lasthook;
    } else {
	$self->xdebug("no hooks");
    }
    my $n = $self->{upper_flow} ?
	$self->{upper_flow}->in_request_body($data,$eof,$time) : -1;
    if ( defined $lasthook ) {
	if (!$n) {
	} elsif ($n<0) {
	    $hooks->[$lasthook][1] = '';
	} else {
	    substr($hooks->[$lasthook][1],0,$n,'');
	}
	if ( $eof && grep { $_->[1] ne '' } @$hooks ) {
	    die "out-buffer in hook not empty at in_request_body(eof)";
	}
	return $bytes;
    }
    return $n;
}

sub in_response_body {
    my ($self,$data,$eof,$time) = @_;
    croak "gaps not supported in_response_body" if ref($data);
    my $bytes = length($data);
    my $hooks = $self->{hooks}{response_body};
    my $lasthook;
    if ( $hooks ) {
	# hooks might be dynamically added inside a previous hook
	my $ref = \$data;
	for(my $i=0;$i<@$hooks;$i++) {
	    my (undef,undef,$sub,@arg) = @{ $hooks->[$i] };
	    $sub or next;
	    my $processed = $sub->($self,$ref,$eof,$time,@arg);
	    $bytes -= length($$ref) if $i == 0;
	    defined $processed or return;
	    $hooks->[$i][1].= $processed;
	    $ref = \$hooks->[$i][1];
	    $lasthook = $i;
	}
	$data = $$ref if defined $lasthook;
    }
    my $n = $self->{upper_flow} ?
	$self->{upper_flow}->in_response_body($data,$eof,$time) : -1;
    if ( defined $lasthook ) {
	if (!$n) {
	} elsif ($n<0) {
	    $hooks->[$lasthook][1] = '';
	} else {
	    substr($hooks->[$lasthook][1],0,$n,'') if $n;
	}
	if ( $eof && grep { $_->[1] ne '' } @$hooks ) {
	    die "out-buffer in hook not empty at in_response_body(eof)".Dumper($self); use Data::Dumper;
	}
	return $bytes;
    }
    return $n;
}

sub in_chunk_header {
    my ($self,$dir,$data,$time) = @_;
    my $bytes = length($data);
    if ( my $hooks = $self->{hooks}{chunk_header} ) {
	# hooks might be dynamically added inside a previous hook
	for(my $i=0;$i<@$hooks;$i++) {
	    my (undef,undef,$sub,@arg) = @{ $hooks->[$i] };
	    $sub or next;
	    defined $sub->($self,$dir,\$data,$time,@arg) or return;
	    $data eq '' and return $bytes;
	}
    }
    $self->{upper_flow}->in_chunk_header($dir,$data,$time)
	if $self->{upper_flow};
    return $bytes;
}

sub in_chunk_trailer {
    my ($self,$dir,$data,$time) = @_;
    my $bytes = length($data);
    if ( my $hooks = $self->{hooks}{chunk_trailer} ) {
	# hooks might be dynamically added inside a previous hook
	for(my $i=0;$i<@$hooks;$i++) {
	    my (undef,undef,$sub,@arg) = @{ $hooks->[$i] };
	    $sub or next;
	    defined $sub->($self,$dir,\$data,$time,@arg) or return;
	    $data eq '' and return $bytes;
	}
    }
    $self->{upper_flow}->in_chunk_trailer($dir,$data,$time)
	if $self->{upper_flow};
    return $bytes;
}

############################################################################
# Builtin named hooks
############################################################################
############################################################################
# 'unchunk' hook
# removes 'chunked' from response header and ignores chunk framing
############################################################################
sub _rphdr_unchunk {
    my ($self,$hdr_ref,$time,%opt) = @_;
    my $hdr = $self->response_header;

    # remove chunked from Transfer-Encoding
    my $ote = my $te = $hdr->header('Transfer-Encoding') or return 0;
    $te =~s{\s*\bchunked\b\s*}{}i or return 0;
    if ( $te ne '' ) {
	$hdr->header('Transfer-Encoding' => $te);
    } else {
	$hdr->remove_header('Transfer-Encoding');
    }
    if ( my $prefix = $opt{'-original-header-prefix'} ) {
	$hdr->push_header( $prefix.'Transfer-Encoding' => $ote)
    }

    $$hdr_ref = $hdr->as_string;

    my $ignore = sub {
	my ($self,$dir,$data_ref) = @_;
	$$data_ref = '';
	return 1;
    };
    $self->update_hook('unchunk',{
	chunk_trailer => $ignore,
	chunk_header  => $ignore,
    });

    $self->{info}{chunked}++;
    return 1;
}

############################################################################
# 'uncompress_ce' and 'uncompress_te' hooks
# Handling of gzip and deflate content
# the hook _rphdr_uncompress_* is added to respone_header and if it finds
# a matching content-encoding/transfer_encoding it will remove it and add
# _rpbody_uncompress as a hook for response_body
# To make sure we can decompress we have to either prohibit range requests
# or prohibit compression if Range request occured.
# This is done in _rqhdr_uncompress_ce
#
# We might actually have the content compressed twice: transfer-encoding
# and content-encoding. Does not make much sense, but there are a lot of
# nonsense responses out there
#
# Browser handling of transfer-encoding: gzip etc is ambiguous,
# they mostly ignore the header (MSIE, Chrome, FF) but some support it
# (Opera, rekonq, konqueror)
############################################################################
sub _rphdr_uncompress_ce {
    my ($self,$hdr_ref,$time,%opt) = @_;
    my $hdr = $self->response_header;
    my $oce = my $ce = $hdr->header('Content-Encoding') or return 0;
    $ce =~s{\s*\b(?:x-)?(gzip|deflate)\b\s*}{}i or return 0;
    $self->{info}{"ce_$1"}++;
    $self->update_hook('uncompress_ce',{
	response_body => [\&_rpbody_uncompress,{ typ => lc($1) }]
    });

    if ( $hdr->header('Content-Range')) {
	# should not happen, we blocked it!
	$self->fatal('got content-range header with compression',1,$time);
	return;
    }
    if ( $ce ne '' ) {
	$hdr->header('Content-Encoding' => $ce);
    } else {
	$hdr->remove_header('Content-Encoding');
    }
    my $prefix = $opt{'-original-header-prefix'};
    $hdr->push_header( $prefix.'Content-Encoding' => $oce) if $prefix;

    # Content-length changes so it needs to be removed
    if ( my @l = $hdr->remove_header('Content-length') and $prefix) {
	$hdr->push_header( $prefix.'Content-Length' => $_) for @l;
    }

    # the MD5 over the content changes too
    if ( my @m = $hdr->remove_header('Content-MD5') and $prefix ) {
	$hdr->push_header( $prefix.'Content-MD5' => $_) for @m;
    }

    # update header string
    $$hdr_ref = $hdr->as_string;

    return 1;
}

sub _rphdr_uncompress_te {
    my ($self,$hdr_ref,$time,%opt) = @_;
    my $hdr = $self->response_header;
    my $te = $hdr->header('Transfer-Encoding') or return 0;
    my $ote = $te =~s{\s*\b(?:x-)?(gzip|deflate)\b\s*}{}i or return 0;
    $self->{info}{"te_$1"}++;
    $self->update_hook('uncompress_te',{
	response_body => [\&_rpbody_uncompress,{ typ => lc($1) }]
    });
    if ( $te ne '' ) {
	$hdr->header('Transfer-Encoding' => $te);
    } else {
	$hdr->remove_header('Transfer-Encoding');
    }

    my $prefix = $opt{'-original-header-prefix'};
    $hdr->push_header( $prefix.'Transfer-Encoding' => $ote) if $prefix;

    # Content-length changes so it needs to be removed
    if ( my @l = $hdr->remove_header('Content-length') and $prefix) {
	$hdr->push_header( $prefix.'Content-Length' => $_) for @l;
    }

    # update header string
    $$hdr_ref = $hdr->as_string;
    return 1;
}

sub _rqhdr_uncompress_ce {
    my ($self,$hdr_ref) = @_;
    my $hdr = $self->request_header;
    $hdr->header('Range') or return 0;
    # on range header remove compression from supported content-encodings
    # unfortunatly some server switch on compression anyways because of
    # user-agent :(
    $hdr->header('Accept-Encoding' => 'identity');
    $$hdr_ref = $hdr->as_string;
    return 1;
}

sub _rpbody_uncompress {
    my ($self,$data_ref,$eof,$time,$zlib) = @_;
    if ( ! $zlib->{inflate} ) {
	# initialisation

	my $wb;
	if ( $zlib->{typ} eq 'gzip' ) {
	    # remove GZip header first
	    my $len = length($$data_ref);
	    my $hdr = 10;  # minimum header length
	    return $eof ? undef: '' if $len < $hdr;

	    my ($magic,$method,$flags) = unpack( 'vCC',$$data_ref );
	    if ( $magic != 0x8b1f or $method != Z_DEFLATED or $flags & 0xe0 ) {
		trace("error decoding content-encoding gzip - bad gzip header");
		$zlib->{inflate} =
		    Net::Inspect::L7::HTTP::Request::InspectChain::IgnoreBadGzip->new;
		goto bad_gzip;
	    }
	    if ( $flags & 4 ) {
		# skip extra
		return 0 if $len < ( $hdr+=2 );
		$hdr+= unpack( 'x10v',$$data_ref );
		return $eof ? undef: '' if $len < $hdr;
	    }
	    if ( $flags & 8 ) {
		# skip file name
		my $o = index( $$data_ref,"\0",$hdr );
		return $eof ? undef: '' if  $o == -1; # file name end not found
		$hdr = $o+1;
	    }
	    if ( $flags & 16 ) {
		# skip comment
		my $o = index( $$data_ref,"\0",$hdr );
		return $eof ? undef: '' if  $o == -1; # comment end not found
		$hdr = $o+1;
	    }
	    if ( $flags & 2 ) {
		# skip CRC
		return $eof ? undef: '' if $len < ( $hdr+=2 );
	    }
	    # remove header
	    substr( $$data_ref,0,$hdr,'' );
	    $self->xdebug( "removed gzip header of $hdr bytes" );

	    $zlib->{gzip_csum} = 8; # 8 byte adler32 at end
	    $wb = -MAX_WBITS(); # see Compress::Raw::Zlib

	}  else {
	    # deflate
	    # lets see if it looks like a zlib header
	    # check for CM=8, CMID<=7 in first byte and valid FCHECK in
	    # seconds byte
	    return $eof ? undef: '' if length($$data_ref)<2;

	    my $byte = unpack( "C", substr($$data_ref,0,1));
	    if (
		( $byte & 0b1111 ) == 8                           # CM = 8
		and $byte >> 4 <= 7                               # CMID <=7
		and unpack( 'n',substr($$data_ref,0,2)) % 31 == 0 # valid FCHECK
		) {
		# could be zlib header
		$self->xdebug( "looks like zlib" );
		$wb = +MAX_WBITS(); # see Compress::Raw::Zlib
	    } else {
		# raw deflate
		$self->xdebug( "no zlib, assume raw deflate" );
		$wb = -MAX_WBITS(); # see Compress::Raw::Zlib
	    }
	}
	$zlib->{inflate} = Compress::Raw::Zlib::Inflate->new(
	    -WindowBits => $wb,
	    -AppendOutput => 1,
	    -ConsumeInput => 1
	) or die "cannot create inflation stream";

	bad_gzip:
	1;
    }

    return '' if $$data_ref eq '';

    my $data = '';
    my $stat = $zlib->{inflate}->inflate( $data_ref,\$data );
    if ( $stat == Z_STREAM_END ) {
	if ( $zlib->{gzip_csum} ) {
	    # TODO - check checksum?
	    return '' if length($$data_ref)<8;
	    substr($$data_ref,0,8,'');
	    $zlib->{gzip_csum} = 0;
	}
    } elsif ( $stat != Z_OK ) {
	$self->fatal("bad status $stat while inflating stream",1,$time);
	return;
    }
    return $data
}

# fake inflater to handle invalid gzip as plain text
# some server send Content-type: gzip with plain data when confronted
# with a request for identity :(
package Net::Inspect::L7::HTTP::Request::InspectChain::IgnoreBadGzip;
use Compress::Raw::Zlib;
sub new { return bless {},shift };
sub inflate {
    my ($self,$in,$out) = @_;
    return Z_STREAM_END if $$in eq '';
    $$out .= $$in;
    $$in = '';
    return Z_OK;
}


1;
__END__

=head1 NAME

Net::Inspect::L7::HTTP::Request::InspectChain - chained inspection
and modification of HTTP request and response

=head1 DESCRIPTION

With this class one can deeply analyze and modify a HTTP request, like
unchunking and uncompressing the content and adding custom functions to modify
request and response header and content.

It provides all hooks required from C<Net::Inspect::L7::HTTP> and will require
the same hooks for the attached upper flow, which will receive the modified
header and content.

The following methods are provided for adding inspection and modification:

=over 4

=item add_hooks([$pos],[%opt],@hooks,[$pos],[%opt],@hooks...)

adds the given inspection/modification hooks.
A hook is either a string for predefined hooks or a hash ref with the name of
the hookable place as key and a code ref or array-ref with code-ref and
arguments implementing the hook as the value.
The key 'name' can be used to give the hook a name, which later can be used in
C<update_hook>.

The hooks will be applied in the given order.
With C<pos> the position in the list can be defined, e.g. 0 will insert at the
beginning, undef will add at the end. Adding at the end is the default.
Note that the order of the hooks is really important!

Option keys in C<%opt> start with '-'. All options will be added to the
following hooks.

The following hookable places exist and require the given kind of hook code:

=over 8

=item request_header => sub($self,\$hdr,$time,@hook_args)

This hook is called after reading the request header. The header as a string is
given as a scalar-ref and can be modified. Using C<request_header> method the
header can be accessed as L<HTTP::Request> object.

The hook should return 1 if the header was changed and 0 if not.
If it returns undef the processing will stop and it will be expected, that the
hook already called C<< $self->fatal >> in this case to propagate the error.

=item request_body => sub($self,\$data,$eof,$time,@hook_args)

This hook is called whenever new data arrive for the request body.
It should modify C<$data> to remove all processed content and returns the
processed content.

If content remains in C<$data> it will be still in it when the hook is called
again when new data arrive. This means especially, that nothing should remain in
C<$data> if C<$eof> is true, because no more data will arrive. If this condition
is not met the code will C<die()>.

=item response_header => sub($self,\$hdr,$time,@hook_args)

This is similar to C<request_header>, except that is applied to the response
header.

=item response_body => sub($self,\$data,$eof,$time,@hook_args)

This is similar to C<request_body>, except that is applied to the response
body. It will only be called on the content, not on the framing of chunked
encoding.

=item chunked_header => sub($self,$dir,\$hdr,$time,@hook_args)

This will be called for each header of the framing in chunked encoding.
One can modify C<$hdr>. The hook should return undef on error, otherwise
something defined.

=item chunked_trailer => sub($self,$dir,\$trailer,$time,@hook_args)

This will be called for the trailer of the framing in chunked encoding.
One can modify C<$trailer>. The hook should return undef on error, otherwise
something defined.

=back

The following predefined hooks exist:

=over 8

=item unchunk

will hook into C<response_header>. If it says, that the response is chunked it
will remove the chunked info from C<Transfer-Encoding> header and update hooks
in C<chunk_header> and C<chunk_trailer> to remove the chunk framing.

If the chunking was found and removed it will set C<$self->{info}{chunked}>.

If option C<-original-header-prefix> is given it will preserver the original
header for alle changed headers with the given prefix.


=item uncompress_ce

will hook into C<response_header>. If it says, that the response has a
C<Content-Encoding> of gzip or deflate it will remove the info from the header
and update hook in C<response_body> to uncompress content.

If compression was found and removed it will set C<$self->{info}{ce_gzip}> or
C<$self->{info}{ce_deflate}>.

If option C<-original-header-prefix> is given it will preserver the original
header for alle changed headers with the given prefix.

=item uncompress_te

same as uncompress_ce, but for C<Transfer-Encoding>.

=back

=item update_hook($name,\%hook)

will update the hook with with name C<$name> with the given definition.
Hookable places not given in C<%hook> will be kept.

=item request_header([$hdr_string])

helper function which will return HTTP::Request object for the request header.
Can also be used to set new header.


=item response_header([$hdr_string])

helper function which will return HTTP::Response object for the response header
Can also be used to set new header.

=back

=head1 LIMITS

Only gzip and deflate are supported for uncompression, no 'uncompress'
