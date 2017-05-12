package PXP::ExtensionPointClass;

=pod

=head1 NAME

  PXP::ExtensionPointClass - Basic logic and Mandatory interfaces for L<PXP::ExtensionPoint>s.

=head1 SYNOPSIS

  use base qw(PXP::ExtensionPointClass);
  ...
  # overload basic methods
  sub register {
  }

=head1 DESCRIPTION

The PXP::ExtensionPointClass helps implement new C<ExtensionPoint>s. It provides basic methods and logic for dealing with C<Extensions>.

=cut

use strict;
use warnings;


sub new {
  my $class = shift;
  my $self = {};

  bless $self, $class;

  return $self->init(@_);
}

sub init {
  my $self = shift;
  my $plugin = shift;

  my %opts = @_;

  return $self;
}

=pod "

=item I<register>

The I<register> method is called by C<Extension>s to add themselves to the extension directory maintained by the C<ExtensionPoint>.

An C<ExtensionPoint> must overload this method, use its own data structure and check that only valid extensions try to register.

Return 'undef' if the extension is invalid.

Return the extension itself if it has been successfully added to the internal registry.

=cut "

sub register {
  my $self = shift;
  my $extension = shift;
  my $node = shift;

  # please overload this method
  die "please redefine the register func.";
}

1;
