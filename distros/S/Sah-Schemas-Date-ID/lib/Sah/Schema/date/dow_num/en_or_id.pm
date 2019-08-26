package Sah::Schema::date::dow_num::en_or_id;

our $DATE = '2019-07-21'; # DATE
our $VERSION = '0.002'; # VERSION

our $schema = [int => {
    summary => 'Day-of-week number (1-7, 1=Monday)',
    min => 1,
    max => 7,
    'x.perl.coerce_rules' => ['str_convert_en_or_id_dow_name_to_num'],
    'x.completion' => ['date_dow_num_en_or_id'],
}, {}];

1;

# ABSTRACT: Day-of-week number (1-7, 1=Monday)

__END__

=pod

=encoding UTF-8

=head1 NAME

Sah::Schema::date::dow_num::en_or_id - Day-of-week number (1-7, 1=Monday)

=head1 VERSION

This document describes version 0.002 of Sah::Schema::date::dow_num::en_or_id (from Perl distribution Sah-Schemas-Date-ID), released on 2019-07-21.

=head1 DESCRIPTION

Like the L<date::dow_num|Sah::Schema::date::dow_num> schema, except with
coercion rule to convert English/Indonesian day-of-week name to number.

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

L<Sah::Schema::date::dow_num>

L<Sah::Schema::date::dow_num::id>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
