#$Id$
package REST::Neo4p::Agent::LWP::UserAgent;
use base qw/LWP::UserAgent REST::Neo4p::Agent/;
use MIME::Base64;
use strict;
use warnings;
BEGIN {
  $REST::Neo4p::Agent::LWP::UserAgent::VERSION = "0.3012";
  $REST::Neo4p::Agent::LWP::UserAgent::VERSION = "0.3012";
}
sub new {
  my ($class,@args) = @_;
  my $self = $class->SUPER::new(@_);
  return $self;
}
sub add_header { shift->default_headers->header(@_) }
sub remove_header { shift->default_headers->remove_header($_[0]) }
sub credentials {
  my $self = shift;
  my ($host, $realm, $user, $pass) = @_;
  if ($user && $pass) {
    $self->default_header( 'Authorization' => encode_base64("$user:$pass",'') )
  }
}
1;

