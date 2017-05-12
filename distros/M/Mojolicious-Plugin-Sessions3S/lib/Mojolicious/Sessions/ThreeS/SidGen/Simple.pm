package Mojolicious::Sessions::ThreeS::SidGen::Simple;
$Mojolicious::Sessions::ThreeS::SidGen::Simple::VERSION = '0.004';
use Mojo::Base qw/Mojolicious::Sessions::ThreeS::SidGen/;

use Digest::SHA qw//;

=head1 NAME

Mojolicious::Sessions::ThreeS::SidGen::Simple - A simple and fast Session ID generation.

=cut

=head2 generate_sid

See L<Mojolicious::Sessions::ThreeS::SidGen>

=cut

sub generate_sid{
    my ($self, $controller) = @_;
    return Digest::SHA::sha256_hex( rand() . $$ . {} . time );
}

1;

