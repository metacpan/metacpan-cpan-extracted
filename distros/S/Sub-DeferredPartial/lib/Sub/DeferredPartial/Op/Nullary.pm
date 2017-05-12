package Sub::DeferredPartial::Op::Nullary;

our $VERSION = '0.01';

use Sub::DeferredPartial(); @ISA = 'Sub::DeferredPartial';
use Carp;

# -----------------------------------------------------------------------------
sub new
# -----------------------------------------------------------------------------
{
  my $class = shift;
  my $Op    = shift;

  bless { Op => $Op } => $class;
}
# -----------------------------------------------------------------------------
sub Apply
# -----------------------------------------------------------------------------
{
  my $self = shift;

  confess 'Apply not possible';
}
# -----------------------------------------------------------------------------
sub Eval
# -----------------------------------------------------------------------------
{
  my $self = shift;

  return $self->{Op};
}
# -----------------------------------------------------------------------------
sub Free
# -----------------------------------------------------------------------------
{
  my $self = shift;

  return {};
}
# -----------------------------------------------------------------------------
sub Describe
# -----------------------------------------------------------------------------
{
  my $self = shift;

  return "( $self->{Op} )";
}
# -----------------------------------------------------------------------------
1;

=head1 NAME

Sub::DeferredPartial::Op::Nullary - Nullary operator (constant).

=head1 AUTHOR

Steffen Goeldner <sgoeldner@cpan.org>

=head1 COPYRIGHT

Copyright (c) 2004 Steffen Goeldner. All rights reserved.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
