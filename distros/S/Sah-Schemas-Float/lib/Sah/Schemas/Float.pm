package Sah::Schemas::Float;

use strict;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2022-10-20'; # DATE
our $DIST = 'Sah-Schemas-Float'; # DIST
our $VERSION = '0.013'; # VERSION

1;
# ABSTRACT: Sah schemas for various floating types

__END__

=pod

=encoding UTF-8

=head1 NAME

Sah::Schemas::Float - Sah schemas for various floating types

=head1 VERSION

This document describes version 0.013 of Sah::Schemas::Float (from Perl distribution Sah-Schemas-Float), released on 2022-10-20.

=head1 SAH SCHEMAS

The following schemas are included in this distribution:

=over

=item * L<inf|Sah::Schema::inf>

Inf or -Inf.

=item * L<int_or_inf|Sah::Schema::int_or_inf>

Integer, or InfE<sol>-Inf.

=item * L<nan|Sah::Schema::nan>

NaN.

=item * L<negfloat|Sah::Schema::negfloat>

Negative float.

=item * L<neginf|Sah::Schema::neginf>

-Inf.

=item * L<percent|Sah::Schema::percent>

A float.

This type is basically C<float>, with C<str_as_percent> coerce rule. So the
percent sign is optional, but the number is always interpreted as percent, e.g.
"1" is interpreted as 1% (0.01).

In general, instead of using this schema, I recommend just using the C<float>
type (which by default includes coercion rule to convert from percent notation
e.g. '1%' -> 0.01). Use this schema if your argument really needs to be
expressed in percents.


=item * L<posfloat|Sah::Schema::posfloat>

Positive float.

See also C<ufloat> for floats that are equal or larger than 0.


=item * L<posinf|Sah::Schema::posinf>

Inf but not -Inf.

=item * L<posint_or_posinf|Sah::Schema::posint_or_posinf>

Positive integer, or Inf.

Can be used to check value for number of items in a (possibly infinite)
sequence.


=item * L<share|Sah::Schema::share>

A float between 0 and 1.

Accepted in one of these forms:

 0.5      # a normal float between 0 and 1
 10       # a float between 1 (exclusive) and 100, interpreted as percent
 10%      # a percentage string, between 0% and 100%

Due to different interpretations, particularly "1" (some people might expect it
to mean "0.01" or "1%") use of this type is discouraged. Use
L<Sah::Schema::percent> instead.


=item * L<ufloat|Sah::Schema::ufloat>

Non-negative float.

See also C<posfloat> for floats that are larger than 0.


=item * L<uint_or_posinf|Sah::Schema::uint_or_posinf>

Unsigned integer, or Inf.

Can be used to check value for number of items in a (possibly infinite)
sequence.


=back

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Sah-Schemas-Float>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Sah-Schemas-Float>.

=head1 SEE ALSO

L<Sah> - schema specification

L<Data::Sah> - Perl implementation of Sah

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 CONTRIBUTING


To contribute, you can send patches by email/via RT, or send pull requests on
GitHub.

Most of the time, you don't need to build the distribution yourself. You can
simply modify the code, then test via:

 % prove -l

If you want to build the distribution (e.g. to try to install it locally on your
system), you can install L<Dist::Zilla>,
L<Dist::Zilla::PluginBundle::Author::PERLANCAR>,
L<Pod::Weaver::PluginBundle::Author::PERLANCAR>, and sometimes one or two other
Dist::Zilla- and/or Pod::Weaver plugins. Any additional steps required beyond
that are considered a bug and can be reported to me.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2022, 2020, 2019, 2018 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Sah-Schemas-Float>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
