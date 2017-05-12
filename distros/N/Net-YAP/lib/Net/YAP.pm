package Net::YAP;

$VERSION = 0.6;

use strict;
use base qw(Net::OAuth::Simple);

use JSON::Any;

our $AUTH_URL = "https://api.login.yahoo.com/oauth/v2/request_auth";
our $REQ_URL  = "https://api.login.yahoo.com/oauth/v2/get_request_token";
our $ACC_URL  = "https://api.login.yahoo.com/oauth/v2/get_token";

=head1 NAME

Net::YAP - Module used as a conduit to communicate with the Yahoo! 
Application Platform

=head1 FUNCTIONS

=cut

=head1 PUBLIC METHODS

=head2 new

Creates a new Net::YAP object. The following arguments must be passed
to the constructor in order to ensure access is gained to the Yahoo! user's 
details (location, age, etc).

  KEY                   VALUE
  -----------           --------------------
  consumer_key          This key is defined in the YAP dashboard
  consumer_secret       This key is defined in the YAP dashboard
  access_token          Contained in the incoming request arguments
  access_token_secret   Contained in the incoming request arguments

The consumer_key and consumer_secret are both unique to a YAP project.

=cut

sub new {
	my $class  = shift;
    my %tokens = @_;
    return $class->SUPER::new( tokens => \%tokens, 
                               protocol_version => '1.0a', 
                               urls   => {
                                        authorization_url => $AUTH_URL,
                                        request_token_url => $REQ_URL,
                                        access_token_url  => $ACC_URL,
                               });
}



=head2 get_user_guid

This method returns the guid of the Yahoo! user who has made a request to the
YAP application.

=cut


sub get_user_guid {
    my $self   = shift;
    my %params = @_;
    my $url    = URI->new('http://social.yahooapis.com/v1/me/guid');
    my $res = $self->make_restricted_request("$url", 'GET', format => 'json');
    my $data = eval { JSON::Any->new->from_json($res->content) };

    return $data->{guid}->{value};
}


=head2 get_user_profile

This method returns the profile data of the Yahoo! user who has made a request
to the YAP application.

The data is returned as a hash reference.

=cut


sub get_user_profile {
    my $self   = shift;
    my $guid = shift;
    my %params = @_;
    my $url = "http://social.yahooapis.com/v1/user/$guid/profile";
    $url    = URI->new( $url );
    my $res = $self->make_restricted_request("$url", 'GET', format => 'json');
    my $data = eval { JSON::Any->new->from_json($res->content) };

    return $data->{profile};
}


=head1 AUTHOR

The code for this module is largely adapted from Simon Wistow's L<Net::FireEagle>.

Rewritten and packaged by Alistair Francis <opensource@alizta.com>


=head1 SEE ALSO

L<Net::OAuth>, L<Net::OAuth::Simple> 

=cut


1;
