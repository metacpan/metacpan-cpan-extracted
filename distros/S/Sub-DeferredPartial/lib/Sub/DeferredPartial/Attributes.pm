package Sub::DeferredPartial::Attributes;

our $VERSION = '0.01';

my %Subs = ();
# -----------------------------------------------------------------------------
sub import
# -----------------------------------------------------------------------------
{
  my $class  = shift;
  my $caller = shift || caller;
  my $isa    = $caller . '::ISA';

  push @$isa, $class;
}
# -----------------------------------------------------------------------------
sub MODIFY_CODE_ATTRIBUTES
# -----------------------------------------------------------------------------
{
  my $Pkg = shift;
  my $Sub = shift;

  $Subs{$Sub} = [ @_ ];

  return ();
}
# -----------------------------------------------------------------------------
sub Hash
# -----------------------------------------------------------------------------
{
  my $class = shift;
  my $Sub   = shift;
  my %Atts;

  @Atts{@{$Subs{$Sub}}} = ();

  return \%Atts;
}
# -----------------------------------------------------------------------------
1;

=head1 NAME

Sub::DeferredPartial::Attributes - A simple subroutine attribute handler.

=head1 AUTHOR

Steffen Goeldner <sgoeldner@cpan.org>

=head1 COPYRIGHT

Copyright (c) 2004 Steffen Goeldner. All rights reserved.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
