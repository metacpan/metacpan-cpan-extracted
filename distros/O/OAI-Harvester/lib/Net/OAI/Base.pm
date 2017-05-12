package Net::OAI::Base;

use strict;
use warnings;
use Carp qw ( croak );
our $VERSION = "1.20";

=head1 NAME

Net::OAI::Base - A base class for all OAI-PMH responses

=head1 SYNOPSIS

    if ( $object->resumptionToken() ) { 
	...
    }

    if ( $object->error() ) { 
	print "verb action resulted in error code:" . $object->errorCode() . 
	    " message:" . $object->errorString() . "\n";
    }

    print "xml response can be found here: " . $obj->file() . "\n";
    print "the response xml is " . $obj->xml(); 

=head1 DESCRIPTION

Net::OAI::Base is the base class for all the OAI-PMH verb responses. It is
used to provide similar methods to all the responses. The following 
classes inherit from Net::OAI::Base.

=over 4

=item * 

Net::OAI::GetRecord

=item *

Net::OAI::Identify

=item * 

Net::OAI::ListIdentifiers

=item *

Net::OAI::ListMetadataFormats

=item *

Net::OAI::ListRecords

=item * 

Net::OAI::ListSets

=back

=head1 METHODS

=head2 responseDate()

Returns the content of the mandatory responseDate element.

=cut

sub responseDate {
    my $self = shift;
    return ($self->{ responseDate }->[0] || undef) if exists $self->{ responseDate };
    return ($self->{ error }->{ _responseDate } || undef) if exists $self->{ error }->{ _responseDate };
    return undef;
}


=head2 request()

In scalar context this method returns just the base URL (text content)
of the mandatory OAI request element.

 $requestText = $OAI->request();

In array context a hash with the delivered attributes of the OAI request
element (mirroring the valid query parameters) is appended.

  my ($requestURI, %requestParams) = $OAI->request();
  print STDERR "Repository URL: ", $requestURI, "\n";
  print STDERR "verb was: ", $requestParams->{'verb'}, "\n";

Returns C<undef> / C<()> if the OAI response could not be parsed or did not 
contain the mandatory response element.

=cut

sub request {
    my $self = shift;
    if ( wantarray () ) {
        if ( exists $self->{ requestContent } ) {
            return $self->{ requestContent }->[0] || "", %{$self->{ requestAttrs }->[0]}}
        elsif ( exists $self->{ error }->{ _requestContent } ) {
            return $self->{ error }->{ _requestContent } || "", %{$self->{ error }->{ _requestAttrs }}}
        else {
            return ();
        }
    }
    else {
        if ( exists $self->{ requestContent } ) {
            return $self->{ requestContent }->[0] || ""}
        elsif ( exists $self->{ error }->{ _requestContent } ) {
            return $self->{ error }->{ _requestContent } || ""}
        else {
            return undef;
        }
    }
}


=head2 is_error()

Returns -1 for HTTP or XML errors, 1 for OAI error respones, 0 for no errors;

=cut

sub is_error {
    my $self = shift;
    return undef unless exists $self->{ error };
    return 0 unless my $c = $self->{ error }->errorCode();
    return -1 if $self->{ error }->HTTPError();
    return -1 if $c =~ /^xml/;
    return 1;
}

=head2 errorCode()

Returns an error code associated with the verb result.

=cut

sub errorCode {
    my $self = shift;
    if ( $self->{ error }->errorCode() ) { 
	return( $self->{ error }->errorCode() );
    }
    return( undef );
}

=head2 errorString()

Returns an error message associated with an error code.

=cut

sub errorString {
    my $self = shift;
    if ( $self->{ error }->errorCode() ) {
	return( $self->{ error }->errorString() );
    }
    return( undef );
}

=head2 HTTPRetryAfter()

Returns the HTTP Retry-After header in case of HTTP level errors.

=cut

sub HTTPRetryAfter {
    my ( $self ) = @_;
    return undef unless $self->{ error };
    return $self->{ error }->HTTPRetryAfter();
}


=head2 HTTPError()

Returns the HTTP::Response object in case of HTTP level errors.

=cut

sub HTTPError {
    my ( $self ) = @_;
    return $self->{ error }->HTTPError();
}


=head2 resumptionToken() 

Returns a Net::OAI::ResumptionToken object associated with the call. If 
there was no resumption token returned in the response then you will 
be returned undef.

=cut

sub resumptionToken {
    my $self = shift;
    return( $self->{ token } );
}

=head2 xml()

Returns a reference to a scalar that contains the raw content of the response 
as XML.

=cut 

sub xml {
    my(  $self, %args ) = shift;
    return undef unless $self->{ file };    # not set eg. after HTTP error
    open( XML, $self->{ file } ) or croak "unable to open file ".$self->{ file };
    ## slurp entire file into $xml
    local $/ = undef;
    my $xml = <XML>;
    close(XML);            # prevent tempfile leak on Win32
    return( $xml );
}

=head2 file()

Returns the path to a file that contains the complete XML response.

=cut

sub file {
    my $self = shift;
    return( $self->{ file } );
}

# called by next() methods in ListRecords and ListIdentifiers
# listAllIdentifiers and listAllRecords store a reference into $self->{harvester}
sub handleResumptionToken {
    my ( $self, $method ) = @_;

    my $harvester = exists( $self->{ harvester } ) ? $self->{ harvester } : 0;
    return() unless $harvester && $harvester->isa('Net::OAI::Harvester');

    my $rToken = $self->resumptionToken();
    if ( $rToken ) { 
	my $new = $harvester->$method(
            resumptionToken => $rToken->token(), 
            metadataHandler => $self->{ metadataHandler },
              recordHandler => $self->{ recordHandler },
          );
	$new->{ harvester } = $harvester;
	%$self = %$new; 
	return( $self->next() );
    }

    return();
}

=head1 TODO

=head1 SEE ALSO

=head1 AUTHORS

Ed Summers <ehs@pobox.com>

=cut

1;
