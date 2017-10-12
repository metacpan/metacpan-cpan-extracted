package Muster::Hook;
$Muster::Hook::VERSION = '0.62';
use Mojo::Base -base;
use Muster::LeafFile;

use Carp 'croak';

=encoding utf8

=head1 NAME

Muster::Hook - Muster hook base class

=head1 VERSION

version 0.62

=head1 SYNOPSIS

  # CamelCase plugin name
  package Muster::Hook::MyHook;
  use Mojo::Base 'Muster::Hook';

  sub register {
      my $self = shift;
      my $hookmaster = shift;
      my $conf = $shift;

      return $self;
  }

  sub process {
    my $self = shift;
    my %args = @_;

    # Magic here! :)

    return $leaf;
  }

=head1 DESCRIPTION

L<Muster::Hook> is an abstract base class for L<Muster> hooks.

A hook will be used in both the scanning phase and the assembly phase, so it needs to be told which it is.

=head1 METHODS

L<Muster::Hook> inherits all methods from L<Mojo::Base> and implements
the following new ones.

=head2 register

Initialize, and register hooks.

=cut
sub register {
    my $self = shift;
    my $hookmaster = shift;
    my $conf = shift;

    return $self;
} # register

=head2 process

Process (scan or modify) a leaf object.  In scanning phase, it may update the
meta-data, in modify phase, it may update the content.  May leave the leaf
untouched.

  my $new_leaf = $self->process(leaf=>$leaf,phase=>$phase);

=cut

sub process { 
    my $self = shift;
    my %args = @_;

    my $leaf = $args{leaf};
    my $phase = $args{phase};

    return $leaf;
}

1;
