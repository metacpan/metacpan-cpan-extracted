package Mojolicious::Sessions::ThreeS::SidGen;
$Mojolicious::Sessions::ThreeS::SidGen::VERSION = '0.004';
use Mojo::Base -base;
use Carp;

=head1 NAME

Mojolicious::Sessions::ThreeS::SidGen - Session ID generator base class

=head1 SYNOPSIS

This is an abstract class that you can inherit from to implement session ID generation.

To use this, inherit from it using C<Mojo::Base> and implement the methods marked as ABSTRACT.

=cut

=head2 generate_sid

ABSTRACT

Generates a brand new session ID.

Called with the current mojolicious controller by the framework:

  my $new_sid = $this->generate_sid( $controller );

=cut

sub generate_sid{
    confess("Implement this");
}

1;
