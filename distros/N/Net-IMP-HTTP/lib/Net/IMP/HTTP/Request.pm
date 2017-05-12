use strict;
use warnings;

package Net::IMP::HTTP::Request;
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
    my @rt = $factory->RTYPES;
    return (
	[ IMP_DATA_HTTPRQ, \@rt ],
	[ IMP_DATA_STREAM, \@rt, 'Net::IMP::Adaptor::STREAM2HTTPReq' ],
    );
}

# we can overide data to handle the types directly, but per default we
# dispatch to seperate methods
sub data {
    my ($self,$dir,$data,$offset,$type) = @_;

    $self->{pos}[$dir] = $offset if $offset;
    $self->{pos}[$dir] += length($data);

    my $disp = $self->{dispatcher} ||= {
	IMP_DATA_HTTPRQ_HEADER+0  => [ 
	    $self->can('request_hdr'),
	    $self->can('response_hdr'),
	],
	IMP_DATA_HTTPRQ_CONTENT+0 => [ 
	    $self->can('request_body'),
	    $self->can('response_body'),
	],
	IMP_DATA_HTTPRQ_DATA+0 => $self->can('any_data')
    };
    my $sub = $disp->{$type+0} or croak("cannot dispatch type $type");
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
    'any_data',           # ($self,$dir,$data,[$offset])
) {
    no strict 'refs';
    *$subname = sub { croak("$subname needs to be implemented in $_[0]") }
}


1;
__END__

=head1 NAME 

Net::IMP::HTTP::Base - base class for HTTP connection specific IMP plugins

=head1 SYNOPSIS

    package myHTTPAnalyzer;
    use base 'Net::IMP::HTTP::Request';

    # implement methods for the various parts of an HTTP traffic
    sub request_hdr ...
    sub request_body ...
    sub response_hdr ...
    sub response_body ...
    sub any_data ...

=head1 DESCRIPTION

Net::IMP::HTTP::Request is a base class for HTTP request specific IMP plugins.
It provides a way to use such plugins in HTTP aware applications, like
L<App::HTTP_Proxy_IMP>, but with the help of
L<Net::IMP::Adaptor::STREAM2HTTPReq> also in applications using only an
untyped data stream.

Return values are the same as in other IMP plugins but are all related to the
request. This means especially, that IMP_MAXOFFSET means end of request, not
end of HTTP connection.

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

=item any_data($self,$dir,$data,[$offset])

This method gets called on all data chunks after connection upgrades (e.g.
Websocket, CONNECT request...). For end of data C<''> is send as C<$data>.

=back

If you use the default implementation of C<data> you can also use the method
C<offset(dir)> to find out the current offset (e.g. position in byte stream
after the given data). 

Also an C<RTYPES> method should be implemented for the factory object and
return a list of the supported return types. These will be used to construct
the proper C<interface> method.
