package Sub::DeferredPartial::Op::Unary;

our $VERSION = '0.01';

use Sub::DeferredPartial(); @ISA = 'Sub::DeferredPartial';
use Carp;

our %Ops = map { $_ => eval "sub { $_ \$_[0] }" }
  qw( neg ! ~ abs sqrt exp log sin cos );
$Ops{neg} = eval "sub {  - \$_[0] }";
# -----------------------------------------------------------------------------
sub new
# -----------------------------------------------------------------------------
{
  my $class = shift;
  my $Op    = shift;
  my $Op1   = shift;

  confess "Operator '$Op' not implemented" unless exists $Ops{$Op};

  bless { Op => $Op, Op1 => $Op1 } => $class;
}
# -----------------------------------------------------------------------------
sub Apply
# -----------------------------------------------------------------------------
{
  my $self = shift;

  return ref( $self )->new( $self->{Op}, $self->{Op1}->Apply( @_ ) );
}
# -----------------------------------------------------------------------------
sub Eval
# -----------------------------------------------------------------------------
{
  my $self = shift;

  return $Ops{$self->{Op}}->( $self->{Op1}->Eval );
}
# -----------------------------------------------------------------------------
sub Free
# -----------------------------------------------------------------------------
{
  my $self = shift;

  return $self->{Op1}->Free;
}
# -----------------------------------------------------------------------------
sub Describe
# -----------------------------------------------------------------------------
{
  my $self = shift;

  return "( $self->{Op} $self->{Op1} )";
}
# -----------------------------------------------------------------------------
1;

=head1 NAME

Sub::DeferredPartial::Op::Unary - Unary operator.

=head1 AUTHOR

Steffen Goeldner <sgoeldner@cpan.org>

=head1 COPYRIGHT

Copyright (c) 2004 Steffen Goeldner. All rights reserved.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
