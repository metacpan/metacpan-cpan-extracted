package OpenAI::API::UserAgentRole;

use Types::Standard qw(Int Num);

use Moo::Role;
use strictures 2;
use namespace::clean;

has timeout  => ( is => 'rw', isa => Num, default => sub { 60 } );
has retry    => ( is => 'rw', isa => Int, default => sub { 3 } );
has sleep    => ( is => 'rw', isa => Num, default => sub { 1 } );

has user_agent => ( is => 'lazy' );

sub _build_user_agent {
    my ($self) = @_;
    $self->{user_agent} = LWP::UserAgent->new( timeout => $self->timeout );
}

1;
