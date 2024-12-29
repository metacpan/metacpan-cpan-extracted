package Perl::Critic::Policy::Community::SplitQuotedPattern;

use strict;
use warnings;

use Perl::Critic::Utils qw(:severities :classification :ppi);
use parent 'Perl::Critic::Policy';

our $VERSION = 'v1.0.4';

use constant DESC => 'split() called with a quoted pattern';
use constant EXPL => 'The first argument to split() is a regex pattern, not a string (other than the space character special case). Use slashes to quote the pattern argument.';

sub supported_parameters {
	(
		{
			name           => 'allow_unquoted_patterns',
			description    => 'Allow unquoted expressions as the pattern argument to split',
			default_string => '0',
			behavior       => 'boolean',
		},
	)
}
sub default_severity { $SEVERITY_LOWEST }
sub default_themes { 'community' }
sub applies_to { 'PPI::Token::Word' }

sub violates {
	my ($self, $elem) = @_;
	return () unless $elem eq 'split' and is_function_call $elem;
	
	my @args = parse_arg_list $elem;
	return () unless @args;
	
	my $pattern = $args[0][0];
	return $self->violation(DESC, EXPL, $elem)
		unless $pattern->isa('PPI::Token::Regexp::Match')
		or $pattern->isa('PPI::Token::QuoteLike::Regexp')
		or ($pattern->isa('PPI::Token::Quote') and (!length $pattern->string or $pattern->string eq ' '))
		or ($self->{_allow_unquoted_patterns} and !$pattern->isa('PPI::Token::Quote'));
	
	return ();
}

1;

=head1 NAME

Perl::Critic::Policy::Community::SplitQuotedPattern - Quote the split() pattern
argument with regex slashes

=head1 DESCRIPTION

The first argument to the C<split()> function is a regex pattern, not a string.
It is commonly passed as a quoted string which does not make this clear, and
can lead to bugs when the string unintentionally contains unescaped regex
metacharacters. Regardless of the method of quoting, it will be parsed as a
pattern (apart from the space character special case described below). Use
slashes to quote this argument to make it clear that it is a regex pattern.

Note that the special case of passing a single space character must be passed
as a quoted string, not a pattern. Additionally, this policy does not warn
about passing an empty string as this is a common idiom to split a string into
individual characters which does not risk containing regex metacharacters.

By default, this policy also prohibits unquoted patterns such as scalar
variables, since this does not indicate that the argument is interpreted as a
regex pattern and not a string (unless it is a string containing a single space
character).

  split 'foo', $string;  # not ok
  split '.', $string;    # not ok
  split $pat, $string;   # not ok
  split /foo/, $string;  # ok
  split /./, $string;    # ok
  split /$pat/, $string; # ok
  split qr/./, $string;  # ok
  split ' ', $string;    # ok (and distinct from split / /)

This policy is similar to the core policy
L<Perl::Critic::Policy::BuiltinFunctions::ProhibitStringySplit>, but
additionally allows empty string split patterns, and disallows unquoted split
patterns by default.

=head1 AFFILIATION

This policy is part of L<Perl::Critic::Community>.

=head1 CONFIGURATION

This policy can be configured to allow passing unquoted patterns (such as
scalar variables), by putting an entry in a F<.perlcritic> file like this:

  [Community::SplitQuotedPattern]
  allow_unquoted_patterns = 1

=head1 AUTHOR

Dan Book, C<dbook@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright 2024, Dan Book.

This library is free software; you may redistribute it and/or modify it under
the terms of the Artistic License version 2.0.

=head1 SEE ALSO

L<Perl::Critic>
