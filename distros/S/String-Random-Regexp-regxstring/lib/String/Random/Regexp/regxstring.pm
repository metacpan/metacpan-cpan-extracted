package String::Random::Regexp::regxstring;

# we rely on having T_AVREF_REFCOUNT_FIXED
use 5.16.0;

use strict;
use warnings;

use vars qw($VERSION @ISA);

our @ISA = qw(Exporter);
# the EXPORT_OK and EXPORT_TAGS is code by [kcott] @ Perlmongs.org, thanks!
# see https://perlmonks.org/?node_id=11115288
our (@EXPORT_OK, %EXPORT_TAGS);

our $VERSION = '0.02';

BEGIN {
	$VERSION = '0.02';
	if ($] > 5.006) {
		require XSLoader;
		XSLoader::load(__PACKAGE__, $VERSION);
	} else {
		require DynaLoader;
		@ISA = qw(DynaLoader);
		__PACKAGE__->bootstrap;
	}
	@EXPORT_OK = qw/generate_random_strings/;
	%EXPORT_TAGS = (
		# the :all tag: so we can use this like
		#  use String::Random::Regexp::regxstring qw/:all/;
		all => [@EXPORT_OK]
	);
}

# $regx is a string containing a regular expression
#       or a Regexp object constructed, e.g., via qr/.../
# $N    is the number of random strings to generate
# $debug is optional, it can be 0 or 1 denoting name-like behaviour.
# The sub returns undef on failure (e.g. bad parameters)
# On success, it returns an array of $N random strings 
sub generate_random_strings {
	my ($regx, $N, $debug) = @_;

	$debug //= 0;

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

Version 0.02

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

=item * C<generate_random_strings> : generates random strings

=item * C<:all> : tag for exporting all available export symbols

=back

=head1 SUBROUTINES


=head2 C<generate_random_strings>

    my $strings = generate_random_strings($regexp, $N, [$debug])


Arguments:

=over 4

=item * C<$regexp> : a regular expression either as a string
or as a Regexp object created via e.g. C<qr/.../>

=item * C<$N> : the number of random strings to generate.

=item * C<$debug> : optionally enable debug, if set to 1. By default it is turned off.

=back

Given a regular expression, this subroutine will generate
C<$N> random strings which are guaranteed to be matched by
the specified regular expression.

The generated random strings will be returned back as an ARRAY ref.

C<undef> is returned on error, e.g. when no regular expression was
specified or when the number of random strings to generate is not positive.

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




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc String::Random::Regexp::regxstring


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=String-Random-Regexp-regxstring>

=item * Review this module at PerlMonks

not yet...


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

This software is Copyright (c) 2024 by Andreas Hadjiprocopis.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)


=cut

1; # End of String::Random::Regexp::regxstring
