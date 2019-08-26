package Sah::Schema::date::dow_nums::id;

our $DATE = '2019-07-21'; # DATE
our $VERSION = '0.002'; # VERSION

our $schema = ['array' => {
    summary => 'Array of day-of-week numbers (1-7, 1=Monday)',
    of => ['date::dow_num::id', {}, {}],
    'x.perl.coerce_rules' => ['str_comma_sep'],
    'x.completion' => ['date_dow_nums_id'],
}, {}];

1;

# ABSTRACT: Array of day-of-week numbers (1-7, 1=Monday)

__END__

=pod

=encoding UTF-8

=head1 NAME

Sah::Schema::date::dow_nums::id - Array of day-of-week numbers (1-7, 1=Monday)

=head1 VERSION

This document describes version 0.002 of Sah::Schema::date::dow_nums::id (from Perl distribution Sah-Schemas-Date-ID), released on 2019-07-21.

=head1 DESCRIPTION

Like the L<date::dow_nums|Sah::Schema::date::dow_nums> except the elements are
L<date::dow_num::id|Sah::Schema::date::dow_num::id> instead of
L<date::dow_num|Sah::Schema::date::dow_num>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Sah-Schemas-Date-ID>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Sah-Schemas-Date-ID>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Sah-Schemas-Date-ID>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Sah::Schema::date::dow_nums>

L<Sah::Schema::date::dow_nums::en_or_id>

L<Sah::Schema::date::dow_num::id>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
