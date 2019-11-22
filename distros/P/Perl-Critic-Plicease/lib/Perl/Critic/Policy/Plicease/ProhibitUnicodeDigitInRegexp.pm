package Perl::Critic::Policy::Plicease::ProhibitUnicodeDigitInRegexp;

use strict;
use warnings;
use 5.008001;
use Perl::Critic::Utils qw( $SEVERITY_LOW );
use base qw( Perl::Critic::Policy );

# ABSTRACT: Prohibit non-ASCII \d in regular expressions
our $VERSION = '0.01'; # VERSION


use constant DESC => 'Using non-ASCII \d';
use constant EXPL => 'The character class \d matches non-ASCI unicode digits.  ' .
                     'Use [0-9] or the /a modifier (Perl 5.14+) instead.';

sub supported_parameters { ()                          }
sub default_severity     { $SEVERITY_LOW               }
sub default_themes       { ()                          }
sub applies_to           { return 'PPI::Token::Regexp' }

sub violates
{
  my($self, $elem) = @_;

  my %mods = $elem->get_modifiers();

  # if the whole expression uses /a then we are in the clear.
  return if $mods{'a'};

  my $match = $elem->get_match_string;
  if($match =~ /\\d/)
  {
    return $self->violation( DESC, EXPL, $elem );
  }

  return;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Perl::Critic::Policy::Plicease::ProhibitUnicodeDigitInRegexp - Prohibit non-ASCII \d in regular expressions

=head1 VERSION

version 0.01

=head1 DESCRIPTION

The character class C<\d> in a regular expression matches all unicode digit character, which
might not be what you expect if you are testing if a string can be used as a number in Perl.
Instead use either C<[0-9]>, or if you are on Perl 5.14 or better you can use the C</a>
modifier.

 /\d/;      # not ok
 /\d/a;     # ok

=head1 AFFILIATION

None.

=head1 CONFIGURATION

This policy is not configurable except for the standard options.

=head1 CAVEATS

This is a policy that should not be applied toward all applications without some thought.
This is generally true for all L<Perl::Critic> policies, but especially so for this policy.

In the general the ability to match against unicode digits is a useful ability, and doesn't
constitute bad code.  Some applications don't ever need to match non-ASCII digit characters,
and incorrectly rely on C<\d> to validate as a number.

This policy doesn't take into account using the L<re> pragma.

 use re '/a';

 /\d/;  # (still) not ok

=head1 AUTHOR

Graham Ollis <plicease@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by Graham Ollis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
