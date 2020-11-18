#$Id$
package REST::Neo4p::Agent::LWP::UserAgent;
use base qw/LWP::UserAgent REST::Neo4p::Agent/;
use LWP::Authen::Basic;
use LWP::ConnCache;
use strict;
use warnings;
BEGIN {
  $REST::Neo4p::Agent::LWP::UserAgent::VERSION = '0.4000';
}
sub new {
  my ($class,@args) = @_;
  my $self = $class->SUPER::new(@_);
  #This really helps server not to be blown by TIME_WAIT'ed sockets.
  #If load is high - even if 1 thread is used -
  #with disabled keep-alive sockets are screwed on the server side.
  my $cache = LWP::ConnCache->new;
  #TODO FIXME This number should be configurable in some comfortable way
  $cache->total_capacity([30]);
  $self->conn_cache($cache);
  return $self;
}
sub add_header { shift->default_headers->header(@_) }
sub remove_header { shift->default_headers->remove_header($_[0]) }
sub credentials {
  my $self = shift;
  my ($host, $realm, $user, $pass) = @_;
  if ($user && $pass) {
    $self->default_header(
      Authorization => LWP::Authen::Basic->auth_header($user, $pass)
    );
  }
}
1;
