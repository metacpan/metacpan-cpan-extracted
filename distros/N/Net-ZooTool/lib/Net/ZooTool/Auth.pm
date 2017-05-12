package Net::ZooTool::Auth;

use Moose;
use namespace::autoclean;

our $VERSION = '0.003';

has apikey    => ( isa => 'Str', is => 'ro', required => 1, );
has apisecret => ( isa => 'Str', is => 'ro', );
has user      => ( is => 'ro', required => 0, );
has password  => ( is => 'ro', required => 0, );

sub BUILD {
    my $self = shift;
}


no Moose;
__PACKAGE__->meta->make_immutable;

1;
