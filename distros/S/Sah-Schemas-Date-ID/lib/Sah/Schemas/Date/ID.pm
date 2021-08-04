package Sah::Schemas::Date::ID;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2021-08-04'; # DATE
our $DIST = 'Sah-Schemas-Date-ID'; # DIST
our $VERSION = '0.007'; # VERSION

1;
# ABSTRACT: Sah schemas related to date (Indonesian)

__END__

=pod

=encoding UTF-8

=head1 NAME

Sah::Schemas::Date::ID - Sah schemas related to date (Indonesian)

=head1 VERSION

This document describes version 0.007 of Sah::Schemas::Date::ID (from Perl distribution Sah-Schemas-Date-ID), released on 2021-08-04.

=head1 SYNOPSIS

=head1 SAH SCHEMAS

The following schemas are included in this distribution:

=over

=item * L<date::dow_name::id|Sah::Schema::date::dow_name::id>

Day-of-week name (abbreviated or full, in Indonesian).

See also related schemas for other locales, e.g.
L<Sah::Schema::date::dow_name::en> (English),
L<Sah::Schema::date::dow_name::en_or_id> (English/Indonesian), etc.


=item * L<date::dow_num::en_or_id|Sah::Schema::date::dow_num::en_or_id>

Day-of-week number (1-7, 1=Monday, like DateTime), coercible from EnglishE<sol>Indonesian day-of-week name (MoE<sol>SnE<sol>MONE<sol>SENE<sol>mondayE<sol>senin).

See also related schemas that coerce from other locales, e.g.
L<Sah::Schema::date::dow_num> (English), L<Sah::Schema::date::dow_num::id>
(Indonesian), etc.


=item * L<date::dow_num::id|Sah::Schema::date::dow_num::id>

Day-of-week number (1-7, 1=Monday, like DateTime), coercible from Indonesian day-of-week name (SnE<sol>SENE<sol>senin).

See also related schemas that coerce from other locales, e.g.
L<Sah::Schema::date::dow_num> (English),
L<Sah::Schema::date::dow_num::en_or_id> (English or Indonesian), etc.


=item * L<date::dow_nums::en_or_id|Sah::Schema::date::dow_nums::en_or_id>

Array of day-of-week numbers (1-7, 1=Monday).

See also L<Sah::Schema::date::dow_num> which is the schema for the elements.

See also related schemas that coerce from other locales, e.g.
L<Sah::Schema::date::dow_nums::id> (Indonesian),
L<Sah::Schema::date::dow_num::en_or_id> (English/Indonesian), etc.


=item * L<date::dow_nums::id|Sah::Schema::date::dow_nums::id>

Array of required day-of-week numbers (1-7, 1=Monday, like DateTime, with coercions).

See also L<Sah::Schema::date::dow_num::id> which is the schema for the
elements.

See also related schemas that coerce from other locales, e.g.
L<Sah::Schema::date::dow_nums> (English),
L<Sah::Schema::date::dow_num::en_or_id> (English/Indonesian), etc.


=item * L<date::month::id|Sah::Schema::date::month::id>

Month numberE<sol>name (abbreviated or full, in Indonesian).

Note that name is not coerced to number; use
L<Sah::Schema::date::month_num::id> for that.

See also related schemas for other locales, e.g.
L<Sah::Schema::date::month::en> (English),
L<Sah::Schema::date::month::en_or_id> (English/Indonesian), etc.


=item * L<date::month_name::id|Sah::Schema::date::month_name::id>

Month name (abbreviated or full, in Indonesian).

See also related schemas for other locales, e.g.
L<Sah::Schema::date::month_name::en> (English),
L<Sah::Schema::date::month_name::en_or_id> (English/Indonesian), etc.


=item * L<date::month_num::en_or_id|Sah::Schema::date::month_num::en_or_id>

Month number (1-12), coercible from EnglishE<sol>Indonesian fullE<sol>abbreviated name (DecE<sol>DesE<sol>DECEMBERE<sol>DESEMber).

See also related schemas for other locales, e.g.
L<Sah::Schema::date::month_num> (English),
L<Sah::Schema::date::month_num::id> (Indonesian), etc.


=item * L<date::month_num::id|Sah::Schema::date::month_num::id>

Month number (1-12), coercible from Indonesian fullE<sol>abbreviated month name (DesE<sol>DeSEMBER).

See also related schemas for other locales, e.g.
L<Sah::Schema::date::month> (English),
L<Sah::Schema::date::month::en_or_id> (English/Indonesian), etc.


=item * L<date::month_nums::en_or_id|Sah::Schema::date::month_nums::en_or_id>

Array of required month numbers, coercible from EnglishE<sol>Indonesian fullE<sol>abbreviated month names.

See also related schemas for other locales, e.g.
L<Sah::Schema::date::month_nums> (English),
L<Sah::Schema::date::month_nums::id> (Indonesian), etc.


=item * L<date::month_nums::id|Sah::Schema::date::month_nums::id>

Array of required month numbers, coercible from Indonesian fullE<sol>abbreviated month names.

See also related schemas for other locales, e.g.
L<Sah::Schema::date::month_nums> (English),
L<Sah::Schema::date::month_nums::en_or_id> (English/Indonesian), etc.


=back

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

L<Data::Sah::Type::date>

L<Sah::Schemas::Date>

L<Sah> - schema specification

L<Data::Sah> - Perl implementation of Sah

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021, 2020, 2019 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
