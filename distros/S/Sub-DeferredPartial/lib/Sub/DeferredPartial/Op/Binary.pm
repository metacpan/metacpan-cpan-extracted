package Sub::DeferredPartial::Op::Binary;

our $VERSION = '0.01';

use Sub::DeferredPartial(); @ISA = 'Sub::DeferredPartial';
use Carp;

our %Ops = map { $_ => eval "sub { \$_[0] $_ \$_[1] }" }
  qw( + - * / % ** << >> x . & | ^ <=> cmp < <= > >= == != lt le gt ge eq ne );
# -----------------------------------------------------------------------------
sub new
# -----------------------------------------------------------------------------
{
  my $class = shift;
  my $Op    = shift;
  my $Op1   = shift;
  my $Op2   = shift;

  confess "Operator '$Op' not implemented" unless exists $Ops{$Op};

  bless { Op => $Op, Op1 => $Op1, Op2 => $Op2 } => $class;
}
# -----------------------------------------------------------------------------
sub Apply
# -----------------------------------------------------------------------------
{
  my $self  = shift;
  my %Args  = @_;
  my $Free  = $self->Free;
  my %Args1 = (); my $n1 = 0; my $Free1 = $self->{Op1}->Free;
  my %Args2 = (); my $n2 = 0; my $Free2 = $self->{Op2}->Free;

  while ( my ( $k, $v ) = each %Args )
  {
    confess "Not a free parameter: $k" unless exists $Free->{$k};
    $Args1{$k} = $Args{$k}, $n1++ if exists $Free1->{$k};
    $Args2{$k} = $Args{$k}, $n2++ if exists $Free2->{$k};
  }
  my $Op1 = $n1 ? $self->{Op1}->Apply( %Args1 ) : $self->{Op1};
  my $Op2 = $n2 ? $self->{Op2}->Apply( %Args2 ) : $self->{Op2};

  return ref( $self )->new( $self->{Op}, $Op1, $Op2 );
}
# -----------------------------------------------------------------------------
sub Eval
# -----------------------------------------------------------------------------
{
  my $self = shift;

  return $Ops{$self->{Op}}->( $self->{Op1}->Eval, $self->{Op2}->Eval );
}
# -----------------------------------------------------------------------------
sub Free
# -----------------------------------------------------------------------------
{
  my $self = shift;

  return { %{$self->{Op1}->Free}, %{$self->{Op2}->Free} };
}
# -----------------------------------------------------------------------------
sub Describe
# -----------------------------------------------------------------------------
{
  my $self = shift;

  return "( $self->{Op1} $self->{Op} $self->{Op2} )";
}
# -----------------------------------------------------------------------------
1;

=head1 NAME

Sub::DeferredPartial::Op::Binary - Binary operator.

=head1 AUTHOR

Steffen Goeldner <sgoeldner@cpan.org>

=head1 COPYRIGHT

Copyright (c) 2004 Steffen Goeldner. All rights reserved.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
