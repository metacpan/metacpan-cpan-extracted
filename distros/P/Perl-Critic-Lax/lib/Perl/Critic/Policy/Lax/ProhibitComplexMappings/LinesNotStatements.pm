use strict;
use warnings;
package Perl::Critic::Policy::Lax::ProhibitComplexMappings::LinesNotStatements 0.014;
# ABSTRACT: prohibit multiline maps, not multistatement maps

#pod =head1 DESCRIPTION
#pod
#pod Yes, yes, don't go nuts with map and use it to implement the complex multi-pass
#pod fnordsort algorithm.  But, come on, people!  What's wrong with this:
#pod
#pod   my @localparts = map { my $addr = $_; $addr =~ s/\@.+//; $addr } @addresses;
#pod
#pod Nothing, that's what!
#pod
#pod The assumption behind this module is that while the above is okay, the bellow
#pod is Right Out:
#pod
#pod   my @localparts = map {
#pod     my $addr = $_;
#pod     $addr =~ s/\@.+//;
#pod     $addr
#pod   } @addresses;
#pod
#pod Beyond the fact that it's really ugly, it's just a short step from there to a
#pod few included loop structures and then -- oops! -- a return statement.
#pod Seriously, people, they're called subroutines.  We've had them since Perl 3.
#pod
#pod =cut

use Perl::Critic::Utils;
use parent qw(Perl::Critic::Policy);

my $DESCRIPTION = q{The block given to map should fit on one line.};
my $EXPLANATION = "If it doesn't fit on one line, turn it into a subroutine.";

sub default_severity { $SEVERITY_MEDIUM    }
sub default_themes   { qw(lax complexity)  }
sub applies_to       { 'PPI::Token::Word'  }

sub violates {
  my ($self, $element, undef) = @_;

  return if $element ne 'map';
  return if !is_function_call($element);

  my $sib = $element->snext_sibling();
  return if !$sib;

  my $arg = $sib;
  if ($arg->isa('PPI::Structure::List')) {
    $arg = $arg->schild(0);

  # Forward looking: PPI might change in v1.200 so schild(0) is a
  # PPI::Statement::Expression
    if ($arg && $arg->isa('PPI::Statement::Expression')) {
      $arg = $arg->schild(0);
    }
  }

  # If it's not a block, it's an expression-style map, which is only one
  # statement by definition
  return if !$arg;
  return if !$arg->isa('PPI::Structure::Block');

  # The moment of truth: does the block contain any newlines?
  return unless $arg =~ /[\x0d\x0a]/;

  # more than one child statements
  return $self->violation($DESCRIPTION, $EXPLANATION, $element);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Perl::Critic::Policy::Lax::ProhibitComplexMappings::LinesNotStatements - prohibit multiline maps, not multistatement maps

=head1 VERSION

version 0.014

=head1 DESCRIPTION

Yes, yes, don't go nuts with map and use it to implement the complex multi-pass
fnordsort algorithm.  But, come on, people!  What's wrong with this:

  my @localparts = map { my $addr = $_; $addr =~ s/\@.+//; $addr } @addresses;

Nothing, that's what!

The assumption behind this module is that while the above is okay, the bellow
is Right Out:

  my @localparts = map {
    my $addr = $_;
    $addr =~ s/\@.+//;
    $addr
  } @addresses;

Beyond the fact that it's really ugly, it's just a short step from there to a
few included loop structures and then -- oops! -- a return statement.
Seriously, people, they're called subroutines.  We've had them since Perl 3.

=head1 PERL VERSION

This library should run on perls released even a long time ago.  It should work
on any version of perl released in the last five years.

Although it may work on older versions of perl, no guarantee is made that the
minimum required version will not be increased.  The version may be increased
for any reason, and there is no promise that patches will be accepted to lower
the minimum required perl.

=head1 AUTHOR

Ricardo Signes <cpan@semiotic.systems>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2022 by Ricardo Signes <cpan@semiotic.systems>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
