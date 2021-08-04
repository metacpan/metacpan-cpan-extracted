package Sah::Schemas::Date;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2021-08-04'; # DATE
our $DIST = 'Sah-Schemas-Date'; # DIST
our $VERSION = '0.017'; # VERSION

1;
# ABSTRACT: Sah schemas related to date

__END__

=pod

=encoding UTF-8

=head1 NAME

Sah::Schemas::Date - Sah schemas related to date

=head1 VERSION

This document describes version 0.017 of Sah::Schemas::Date (from Perl distribution Sah-Schemas-Date), released on 2021-08-04.

=head1 SYNOPSIS

=head1 SAH SCHEMAS

The following schemas are included in this distribution:

=over

=item * L<date::day|Sah::Schema::date::day>

Day of month (1-31).

=item * L<date::dow_name::en|Sah::Schema::date::dow_name::en>

Day-of-week name (abbreviated or full, in English).

See also: L<Sah::Schema::date::dow_num>.

See also related schemas for other locales, e.g.
L<Sah::Schema::date::dow_name::id> (Indonesian),
L<Sah::Schema::date::dow_name::en_or_id> (English/Indonesian), etc.


=item * L<date::dow_num|Sah::Schema::date::dow_num>

Day-of-week number (1-7, 1=Monday, like DateTime), coercible from English day-of-week name (MoE<sol>monE<sol>MONDAY).

See also related schemas that coerce from other locales, e.g.
L<Sah::Schema::date::dow_num::id> (Indonesian),
L<Sah::Schema::date::dow_num::en_or_id> (English/Indonesian), etc.


=item * L<date::dow_nums|Sah::Schema::date::dow_nums>

Array of required date::dow_num (day-of-week, 1-7, 1=Monday, like DateTime, with coercions).

See also L<Sah::Schema::date::dow_num> which is the schema for the elements.

See also related schemas that coerce from other locales, e.g.
L<Sah::Schema::date::dow_nums::id> (Indonesian),
L<Sah::Schema::date::dow_num::en_or_id> (English/Indonesian), etc.


=item * L<date::hour|Sah::Schema::date::hour>

Hour of day (0-23).

=item * L<date::minute|Sah::Schema::date::minute>

Minute of hour (0-59).

=item * L<date::month::en|Sah::Schema::date::month::en>

Month numberE<sol>name (abbreviated or full, in English).

Note that name is not coerced to number; use
L<Sah::Schema::date::month_num::id> for that.

See also related schemas for other locales, e.g.
L<Sah::Schema::date::month::id> (Indonesian),
L<Sah::Schema::date::month::en_or_id> (English/Indonesian), etc.


=item * L<date::month_name::en|Sah::Schema::date::month_name::en>

Month name (abbreviated or full, in English).

See also: L<Sah::Schema::date::month_num>.

See also related schemas for other locales, e.g.
L<Sah::Schema::date::month_name::id> (Indonesian),
L<Sah::Schema::date::month_name::en_or_id> (English/Indonesian), etc.


=item * L<date::month_num|Sah::Schema::date::month_num>

Month number, coercible from English month names (DecE<sol>DECEMBER).

See also related schemas that coerce from other locales, e.g.
L<Sah::Schema::date::month_num::id> (Indonesian),
L<Sah::Schema::date::month_num::en_or_id> (English/Indonesian), etc.


=item * L<date::month_nums|Sah::Schema::date::month_nums>

Array of required month numbers (1-12, with coercions).

See also related schemas that coerce from other locales, e.g.
L<Sah::Schema::date::month_nums::id> (Indonesian),
L<Sah::Schema::date::month_nums::en_or_id> (English/Indonesian), etc.


=item * L<date::second|Sah::Schema::date::second>

Second of minute (0-60).

=item * L<date::tz_name|Sah::Schema::date::tz_name>

Timezone name, e.g. AsiaE<sol>Jakarta.

Currently no validation for valid timezone names. But completion is provided.


=item * L<date::tz_offset|Sah::Schema::date::tz_offset>

Timezone offset in seconds from UTC.

Only timezone offsets that are known to exist are allowed. For example, 1 second
(+00:00:01) is not allowed. See C<date::tz_offset_lax> for a more relaxed
validation.

A coercion from these form of string is provided:

 UTC
 
 UTC-14 or UTC+12 or UTC+12:45 or UTC-00:25:21
 -14 or +12, -1400 or +12:00

A coercion from timezone name is also provided.


=item * L<date::tz_offset_lax|Sah::Schema::date::tz_offset_lax>

Timezone offset in seconds from UTC.

This schema allows timezone offsets that are not known to exist, e.g. 1 second
(+00:00:01). If you only want ot allow timezone offsets that are known to exist,
see the C<date::tz_offset> schema.

A coercion from these form of string is provided:

 UTC
 
 UTC-14 or UTC+12 or UTC+12:45 or UTC-00:25:21
 -14 or +12, -1400 or +12:00

A coercion from timezone name is also provided.


=item * L<date::year|Sah::Schema::date::year>

Year number (AD, starting from 1).

=back

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Sah-Schemas-Date>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Sah-Schemas-Date>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Sah-Schemas-Date>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Data::Sah::Type::date>

L<Sah> - schema specification

L<Data::Sah> - Perl implementation of Sah

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021, 2020, 2019 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
