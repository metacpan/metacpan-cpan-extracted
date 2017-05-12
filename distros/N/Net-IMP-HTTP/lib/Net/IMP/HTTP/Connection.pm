use strict;
use warnings;

package Net::IMP::HTTP::Connection;
use base 'Net::IMP::Base';
use fields qw(dispatcher pos);
use Net::IMP::HTTP;
use Net::IMP;
use Carp 'croak';

# just define a typical set, maybe need to be redefined in subclass
sub RTYPES { 
    my $factory = shift;
    return (IMP_PASS, IMP_PREPASS, IMP_REPLACE, IMP_DENY, IMP_LOG) 
}

sub INTERFACE {
    my $factory = shift;
    my @rtx = my @rt = $factory->RTYPES;
    push @rtx, IMP_DENY if ! grep { IMP_DENY == $_ } @rtx;
    return (
	[ IMP_DATA_HTTP, \@rt ],
	[ IMP_DATA_HTTPRQ, \@rt ],
	[ IMP_DATA_STREAM, \@rtx, 'Net::IMP::Adaptor::STREAM2HTTPConn' ],
    );
}

sub set_interface {
    my ($factory,$interface) = @_;
    my $newf = $factory->SUPER::set_interface($interface)
	or return;
    return $newf if $newf != $factory;

    # original factory, set dispatcher based on input data type
    if ( $interface->[0] == IMP_DATA_HTTP ) {
	$factory->{dispatcher} = {
	    IMP_DATA_HTTP_HEADER+0  => [ 
		$factory->can('request_hdr'),
		$factory->can('response_hdr'),
	    ],
	    IMP_DATA_HTTP_BODY+0 => [ 
		$factory->can('request_body'),
		$factory->can('response_body'),
	    ],
	    IMP_DATA_HTTP_CHKHDR+0 => [ 
		undef, 
		$factory->can('rsp_chunk_hdr') 
	    ],
	    IMP_DATA_HTTP_CHKTRAILER+0 => [ 
		undef, 
		$factory->can('rsp_chunk_trailer') 
	    ],
	    IMP_DATA_HTTP_DATA+0 => $factory->can('any_data'),
	    IMP_DATA_HTTP_JUNK+0 => $factory->can('junk_data')
	}
    } elsif ( $interface->[0] == IMP_DATA_HTTPRQ ) {
	$factory->{dispatcher} = {
	    # HTTP request interface
	    IMP_DATA_HTTPRQ_HEADER+0  => [ 
		$factory->can('request_hdr'),
		$factory->can('response_hdr'),
	    ],
	    IMP_DATA_HTTPRQ_CONTENT+0 => [ 
		$factory->can('request_body'),
		$factory->can('response_body'),
	    ],
	    IMP_DATA_HTTPRQ_DATA+0 => $factory->can('any_data'),
	}
    } else {
	die "unknown input data type $interface->[0]"
    }

    return $factory;
}

sub new_analyzer {
    my ($factory,%args) = @_;
    my $analyzer = $factory->SUPER::new_analyzer(%args);
    $analyzer->{dispatcher} = $factory->{dispatcher};
    return $analyzer;
}


# we can overide data to handle the types directly, but per default we
# dispatch to seperate methods
sub data {
    my ($self,$dir,$data,$offset,$type) = @_;
    $self->{pos}[$dir] = $offset if $offset;
    $self->{pos}[$dir] += length($data);
    my $disp = $self->{dispatcher};
    my $sub = $disp->{$type+0} or croak("cannot dispatch type $type".Data::Dumper::Dumper($disp));
    if ( ref($sub) eq 'ARRAY' ) {
	$sub = $sub->[$dir] or croak("cannot dispatch type $type dir $dir");
	$sub->($self,$data,$offset);
    } else {
	$sub->($self,$dir,$data,$offset);
    }
}

sub offset {
    my ($self,$dir) = @_;
    return $self->{pos}[$dir] // 0;
}

###########################################################################
# public interface
# most of these methods need to be implemented in subclass
###########################################################################

for my $subname ( 
    'request_hdr',        # ($self,$hdr)
    'request_body',       # ($self,$data,[$offset])
    'response_hdr',       # ($self,$hdr)
    'response_body',      # ($self,$data,[$offset])
    'rsp_chunk_hdr',      # ($self,$hdr)
    'rsp_chunk_trailer',  # ($self,$hdr)
    'any_data',           # ($self,$dir,$data,[$offset])
) {
    no strict 'refs';
    *$subname = sub { croak("$subname needs to be implemented") }
}

# by default simply ignore junk data (leading \n before message header)
sub junk_data {
    my ($self,$dir,$data,$offset) = @_;
    return
}



1;
__END__

=head1 NAME 

Net::IMP::HTTP::Connection - base class for HTTP connection specific IMP plugins

=head1 SYNOPSIS

    package myHTTPAnalyzer;
    use base 'Net::IMP::HTTP::Connection';

    # implement methods for the various parts of an HTTP traffic
    sub request_hdr ...
    sub request_body ...
    sub response_hdr ...
    sub response_body ...
    sub rsp_chunk_hdr ...
    ...

=head1 DESCRIPTION

Net::IMP::HTTP::Connection is a base class for HTTP connection specific IMP
plugins.
It provides a way to use such plugins in HTTP aware applications, like
L<App::HTTP_Proxy_IMP>, but with the help of
L<Net::IMP::Adaptor::STREAM2HTTPConn> also in applications using only an
untyped data stream.

You can either redefine the C<data> method (common to all IMP plugins) or use
the default implementation, which dispatches to various method based on the
type of the received data. In this case you need to implement:

=over 4

=item request_hdr($self,$hdr)

This method gets the header of the HTTP request.

=item request_body($self,$data,[$offset])

This method is called for parts of the request body.
For the final part it will be called with C<$data> set to C<''>.

=item response_hdr($self,$hdr)

This method gets the header of the HTTP response.

=item response_body($self,$data,[$offset])

This method is called for parts of the response body.
For the final part it will be called with C<$data> set to C<''>.

=item rsp_chunk_hdr($self,$hdr) 

This method gets called with the chunk header on chunked transfer encoding of
the body.

=item rsp_chunk_trailer($self,$hdr) 

This method gets called with the chunk trailer on chunked transfer encoding of
the body. Will not be called, if there is no trailer.

=item any_data($self,$dir,$data,[$offset])

This method gets called on all data chunks after connection upgrades (e.g.
Websocket, CONNECT request...). For end of data C<''> is send as C<$data>.

=item junk_data($self,$dir,$data,[$offset])

This method gets called on junk data (e.g. newlines before request etc), which
are allowed for HTTP but have no semantic. The default implementation does
nothing with these data.

=back

Also an C<RTYPES> method should be implemented for the factory object and
return a list of the supported return types. These will be used to construct
the proper C<interface> method.
