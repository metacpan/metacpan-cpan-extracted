use strict;
use warnings;
package Perl::Critic::Policy::Lax::ProhibitEmptyQuotes::ExceptAsFallback 0.014;
# ABSTRACT: empty quotes are okay as the fallback on the rhs of ||

#pod =head1 DESCRIPTION
#pod
#pod Sure, C<""> can be confusing when crammed into the middle of a big list of
#pod values, and a bunch of spaces is even worse.  It's really common, though, to
#pod write this code to get a default, false, defined string:
#pod
#pod   my $value = $got || '';
#pod
#pod It's got a certain charm about it that just isn't manifested by these:
#pod
#pod   my $value = $got || $EMPTY;
#pod   my $value = $got || q{};
#pod
#pod This policy prohibits all-whitespace strings constructed by single or double
#pod quotes, except for the empty string when it follows the high-precedence "or" or "defined or" operators.
#pod
#pod =cut

use Perl::Critic::Utils;
use parent qw(Perl::Critic::Policy);

my $DESCRIPTION = q{Quotes used with an empty string, and not as a fallback};
my $EXPLANATION = "Unless you're using the ||'' idiom, use a quotish form.";

my $empty_rx = qr{\A ["'] (\s*) ['"] \z}x;

sub default_severity { $SEVERITY_LOW       }
sub default_themes   { qw(lax)             }
sub applies_to       { 'PPI::Token::Quote' }

sub violates {
  my ($self, $element, undef) = @_;

  my ($content) = $element =~ $empty_rx;
  return unless defined $content;

  # If the string is truly empty and comes after || or //, that's cool.
  if (not length $content and my $prev = $element->sprevious_sibling) {
    return if $prev->isa('PPI::Token::Operator')
           && grep { $prev eq $_ } ('||', '//');
  }

  return $self->violation($DESCRIPTION, $EXPLANATION, $element);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Perl::Critic::Policy::Lax::ProhibitEmptyQuotes::ExceptAsFallback - empty quotes are okay as the fallback on the rhs of ||

=head1 VERSION

version 0.014

=head1 DESCRIPTION

Sure, C<""> can be confusing when crammed into the middle of a big list of
values, and a bunch of spaces is even worse.  It's really common, though, to
write this code to get a default, false, defined string:

  my $value = $got || '';

It's got a certain charm about it that just isn't manifested by these:

  my $value = $got || $EMPTY;
  my $value = $got || q{};

This policy prohibits all-whitespace strings constructed by single or double
quotes, except for the empty string when it follows the high-precedence "or" or "defined or" operators.

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
