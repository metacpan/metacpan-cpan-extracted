package String::Random::Regexp::regxstring;

# we rely on having T_AVREF_REFCOUNT_FIXED
use 5.016;

use strict;
use warnings;

our $VERSION = '1.04';

use Exporter;
# export our only sub by default:
our @ISA = qw(Exporter);
our @EXPORT = ('generate_random_strings');
# load XS functions
use XSLoader;
XSLoader::load(__PACKAGE__, $VERSION);

# It generates $N random strings given a regular expression.
# $regx is a string containing a regular expression
#       or a Regexp object constructed, e.g., via qr/.../
# $N    is optional, it is the number of random strings to generate, default is 1.
# $debug is optional, it can be 0 or 1 denoting name-like behaviour.
# The sub returns undef on failure (e.g. bad parameters)
# On success, it returns an array of $N random strings 
sub generate_random_strings {
	my ($regx, $N, $debug) = @_;

	if( ! defined $regx ){ print STDERR "generate_random_strings() : error, at least an input regular expression (either as a string or as a Regexp object) is expected.\n"; return undef }

	my $regx_str;
	if( ref($regx) eq '' ){ $regx_str = $regx }
	elsif( ref($regx) eq 'Regexp' ){
		# stringifying a regexp object results in the string regexp
		$regx_str = "".$regx;
		# perl -e 'print qr/^(abc)/' prints (?^:^(abc)) and we dont like it
		# sometimes (?^u:...)
		# TODO: do this properly!!!! without subst hack
		$regx_str =~ s/^\(\?\^.*?\://;
		$regx_str =~ s/\)$//;
	} else { print STDERR "generate_random_strings() : error, input regular expression must either be a string or a Regexp object (created via qr/.../) and not '".ref($regx)."'.\n"; return undef }

	# default values if optional params are not specified:
	$N //= 1;
	$debug //= 0;

	my $ret = generate_random_strings_xs(
		$regx_str,
		$N,
		$debug
	);
	if( ! defined $ret ){ print STDERR "generate_random_strings() : error, call to XS code 'generate_random_strings_xs()' has failed.\n"; return undef }
	return $ret
}


=pod

=head1 NAME

String::Random::Regexp::regxstring - Generate random strings from a regular expression

=head1 VERSION

Version 1.04

=head1 SYNOPSIS

This module provides functionality for generating random strings from a
regular expression by bridging
to the L<regxstring C++ library by daidodo|https://github.com/daidodo/regxstring>
via XS.

    use String::Random::Regexp::regxstring;

    my $strings = generate_random_strings(
	'^([A-Z]|[0-9]){10}\d{5}xxx(\d{3})?',
	3
    );
    # generates 3 random strings based on the regexp
    #   3F3YR2W22947580xxx
    #   N5HHM8LW0K59719xxx957
    #   G2DQL6JF1E91086xxx

    # or provide it with a Regexp object
    my $strings = generate_random_strings(
	qr/^([A-Z]|[0-9]){10}\d{5}xxx(\d{3})?/,
	3
    );

    # or enable debug
    my $strings = generate_random_strings(
	qr/^([A-Z]|[0-9]){10}\d{5}xxx(\d{3})?/,
	3,
        1
    );

=head1 EXPORT

=over 4

=item * C<generate_random_strings> : generates random strings. This sub is exported by default.

=back

=head1 SUBROUTINES


=head2 C<generate_random_strings>

    my $strings = generate_random_strings($regexp [, $N, $debug])


Arguments:

=over 4

=item * C<$regexp> : a regular expression either as a string
or as a Regexp object created via e.g. C<qr/.../>

=item * C<$N> : optionally specify the number of random strings to generate. Default is 1.

=item * C<$debug> : optionally enable debug, if set to 1. By default it is turned off.

=back

Given a regular expression, this subroutine will generate
C<$N> random strings which are guaranteed to be matched by
the specified regular expression.

The generated random strings will be returned back as an ARRAY ref.

C<undef> is returned on error, e.g. when no regular expression was
specified or when the number of random strings to generate is not positive.

=head1 THE C++ LIBRARY regxstring by daidodo

This is a L<regxstring C++ library by daidodo|https://github.com/daidodo/regxstring>
which produces random strings from a regular expresssion. According to the
author, "I<... most Perl 5 supported regular expressions are also supported by regxstring, as showing bellow:>"

    Meta-character(s)   Description
    --------------------------------
    \                   Quote the next meta-character
    ^                   Match the beginning of the line
    $                   Match the end of the line (or before newline at the end)
    ?                   Match 1 or 0 times
    +                   Match 1 or more times
    *                   Match 0 or more times
    {n}                 Match exactly n times
    {n,}                Match at least n times
    {n,m}               Match at least n but not more than m times
    .                   Match any character (except newline)
    (pattern)           Grouping
    (?:pattern)         This is for clustering, not capturing; it groups sub-expressions like "()", but doesn't make back-references as "()" does
    (?=pattern)         A zero-width positive look-ahead assertion, e.g., \w+(?=\t) matches a word followed by a tab, without including the tab
    (?!pattern)         A zero-width negative look-ahead assertion, e.g., foo(?!bar) matches any occurrence of "foo" that isn't followed by "bar"
    |                   Alternation
    [xyz]               Matches a single character that is contained within the brackets
    [^xyz]              Matches a single character that is not contained within the brackets
    [a-z]               Matches a single character that is in a given range
    [^a-z]              Matches a single character that is not in a given range
    \f                  Form feed
    \n                  Newline
    \r                  Return
    \t                  Tab
    \v                  Vertical white space
    \d                  Digits, [0-9]
    \D                  Non-digits, [^0-9]
    \s                  Space and tab, [ \t\r\n\f]
    \S                  Non-white space characters, [^ \t\r\n\f]
    \w                  Alphanumeric characters plus '_', [0-9a-zA-Z_]
    \W                  Non-word characters, [^0-9a-zA-Z_]
    \N                  Matches what the Nth marked sub-expression matched, where N is a digit from 1 to 9

The library provides an executable which may be run from the command line.
It takes a regular expression
from the standard input
and dumps the random strings.

=head1 ALTERNATIVES

There are at least two alternative modules at CPAN which I have tested.

L<String::Random> and L<Regexp::Genex>. Both fail with rudimentary
regular expressions.

The former does not support groups and therefore
all parentheses have to be removed from the regular expression first.
But this is not a trivial task. For example:

  use String::Random qw/random_regex/;
  print random_regex('[A-HN-SW]\d{7}[A-J]ES[A-HN-SW]\d{7}[A-J](?:xx)?');
  # '(' not implemented.  treating literally.

The latter fails randomly on large regular expressions, e.g. C<[A-HN-SW]\d{7}[A-J]xxx>
but succeeds with the shorter C<[A-HN-SW]\d{7}[A-J]>


=head1 AUTHOR

Andreas Hadjiprocopis, C<< <bliako at cpan.org> >>

=head1 DEDICATIONS

!Almaz!

=head1 CAVEATS

The XS function for generating random strings accepts
the input regular expression as a string. This means
that if a Regexp object was supplied to L<generate_random_strings>,
the regular expression as a string must be extracted. And this
is done by stringifying the Regexp object, e.g. C<my $str = "".qr/abc/>
However, the stringification encloses the regular expression within
a C<(?^:> and C<)>. For example:

  print "".qr/^(abc)/
  # prints (?^:^(abc))

Currently, the subroutine will remove this "enclosure".
It remains to be seen whether this is 100% successful.

I have not tested the statistical distribution of the results in
regular expressions like C<a|b|c|d>. They must appear equally often.


=head1 BUGS

Please report any bugs or feature requests to C<bug-string-random-regexp-regxstring at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=String-Random-Regexp-regxstring>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SEE ALSO

L<Mock::Data::Regex> which is implemented in Pure-Perl.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc String::Random::Regexp::regxstring


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=String-Random-Regexp-regxstring>

=item * Review this module at PerlMonks

L<https://perlmonks.org/?node_id=11160309>

=item * Search CPAN

L<https://metacpan.org/release/String-Random-Regexp-regxstring>

=back


=head1 ACKNOWLEDGEMENTS

The core functionality to this module is provided by the C++
library for generating random strings from regular expressions
located at L<https://github.com/daidodo|https://github.com/daidodo>.
The author is DoZerg / daidodo. The Licence is Apache v2.0.

The source code of this library is included in the current module.

I have provided C++ harness code, the XS interface and the Perl module.


=head1 LICENSE AND COPYRIGHT

This software (except the C++ files) is Copyright (c) 2024 by Andreas Hadjiprocopis.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

The C++ files are Copyright (c) by L<daidodo|https://github.com/daidodo> and are L<licensed under Apache v2.0|https://github.com/daidodo/regxstring/blob/master/LICENSE>.


=cut

1; # End of String::Random::Regexp::regxstring
