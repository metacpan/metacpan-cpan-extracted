package Sah::Schemas::Float;

our $DATE = '2019-04-08'; # DATE
our $VERSION = '0.003'; # VERSION

1;
# ABSTRACT: Sah schemas for various floating types

__END__

=pod

=encoding UTF-8

=head1 NAME

Sah::Schemas::Float - Sah schemas for various floating types

=head1 VERSION

This document describes version 0.003 of Sah::Schemas::Float (from Perl distribution Sah-Schemas-Float), released on 2019-04-08.

=head1 SAH SCHEMAS

=over

=item * L<negfloat|Sah::Schema::negfloat>

Negative float.

=item * L<percent|Sah::Schema::percent>

A float.

This type is basically C<float>, with C<str_as_percent> coerce rule. So the
percent sign is optional, but the number is always interpreted as percent, e.g.
"1" is interpreted as 1% (0.01).


=item * L<posfloat|Sah::Schema::posfloat>

Positive float.




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


=back

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Sah-Schemas-Float>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Sah-Schemas-Float>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Sah-Schemas-Float>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Sah> - specification

L<Data::Sah>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019, 2018 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
