package Sah::Schemas::Date;

use strict;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2022-10-12'; # DATE
our $DIST = 'Sah-Schemas-Date'; # DIST
our $VERSION = '0.018'; # VERSION

1;
# ABSTRACT: Sah schemas related to date

__END__

=pod

=encoding UTF-8

=head1 NAME

Sah::Schemas::Date - Sah schemas related to date

=head1 VERSION

This document describes version 0.018 of Sah::Schemas::Date (from Perl distribution Sah-Schemas-Date), released on 2022-10-12.

=head1 SYNOPSIS

=head1 SAH SCHEMAS

The following schemas are included in this distribution:

=over

=item * L<date::day|Sah::Schema::date::day>

Day of month (1-31), e.g. 17.

=item * L<date::dow_name::en|Sah::Schema::date::dow_name::en>

Day-of-week name (abbreviated or full, in English), e.g. "su" or "Monday".

See also: L<Sah::Schema::date::dow_num>.

See also related schemas for other locales, e.g.
L<Sah::Schema::date::dow_name::id> (Indonesian),
L<Sah::Schema::date::dow_name::en_or_id> (English/Indonesian), etc.


=item * L<date::dow_num|Sah::Schema::date::dow_num>

Day-of-week number (1-7, 1=Monday, like DateTime), coercible from English day-of-week name (MoE<sol>monE<sol>MONDAY), e.g. 1 or "Mon".

See also related schemas that coerce from other locales, e.g.
L<Sah::Schema::date::dow_num::id> (Indonesian),
L<Sah::Schema::date::dow_num::en_or_id> (English/Indonesian), etc.


=item * L<date::dow_nums|Sah::Schema::date::dow_nums>

Array of required date::dow_num (day-of-week, 1-7, 1=Monday, like DateTime, with coercions), e.g. [1,3,5].

See also L<Sah::Schema::date::dow_num> which is the schema for the elements.

See also related schemas that coerce from other locales, e.g.
L<Sah::Schema::date::dow_nums::id> (Indonesian),
L<Sah::Schema::date::dow_num::en_or_id> (English/Indonesian), etc.


=item * L<date::hour|Sah::Schema::date::hour>

Hour of day (0-23), e.g. 12.

=item * L<date::minute|Sah::Schema::date::minute>

Minute of hour (0-59), e.g. 30.

=item * L<date::month::en|Sah::Schema::date::month::en>

Month numberE<sol>name (abbreviated or full, in English), e.g. 1 or "jan" or "September".

Note that name is not coerced to number; use
L<Sah::Schema::date::month_num::id> for that.

See also related schemas for other locales, e.g.
L<Sah::Schema::date::month::id> (Indonesian),
L<Sah::Schema::date::month::en_or_id> (English/Indonesian), etc.


=item * L<date::month_name::en|Sah::Schema::date::month_name::en>

Month name (abbreviated or full, in English), e.g. jan or "September".

See also: L<Sah::Schema::date::month_num>.

See also related schemas for other locales, e.g.
L<Sah::Schema::date::month_name::id> (Indonesian),
L<Sah::Schema::date::month_name::en_or_id> (English/Indonesian), etc.


=item * L<date::month_num|Sah::Schema::date::month_num>

Month number, coercible from English month names (DecE<sol>DECEMBER), e.g. 2 or "Feb".

See also related schemas that coerce from other locales, e.g.
L<Sah::Schema::date::month_num::id> (Indonesian),
L<Sah::Schema::date::month_num::en_or_id> (English/Indonesian), etc.


=item * L<date::month_nums|Sah::Schema::date::month_nums>

Array of required month numbers (1-12, with coercions), e.g. [6,12].

See also related schemas that coerce from other locales, e.g.
L<Sah::Schema::date::month_nums::id> (Indonesian),
L<Sah::Schema::date::month_nums::en_or_id> (English/Indonesian), etc.


=item * L<date::second|Sah::Schema::date::second>

Second of minute (0-60), e.g. 39.

=item * L<date::tz_name|Sah::Schema::date::tz_name>

Timezone name (validity not checked), e.g. AsiaE<sol>Jakarta.

Currently no validation for valid timezone names. But completion is provided.


=item * L<date::tz_offset|Sah::Schema::date::tz_offset>

Timezone offset in seconds from UTC (only known offsets are allowd, coercible from string), e.g. 25200 or "+07:00".

Only timezone offsets that are known to exist are allowed. For example, 1 second
(+00:00:01) is not allowed. See C<date::tz_offset_lax> for a more relaxed
validation.

A coercion from these form of string is provided:

 UTC
 
 UTC-14 or UTC+12 or UTC+12:45 or UTC-00:25:21
 -14 or +12, -1400 or +12:00

A coercion from timezone name is also provided.


=item * L<date::tz_offset_lax|Sah::Schema::date::tz_offset_lax>

Timezone offset in seconds from UTC (any offset is allowed, coercible from string), e.g. 1 or 25200 e.g. UTC+7.

This schema allows timezone offsets that are not known to exist, e.g. 1 second
(+00:00:01). If you only want ot allow timezone offsets that are known to exist,
see the C<date::tz_offset> schema.

A coercion from these form of string is provided:

 UTC
 
 UTC-14 or UTC+12 or UTC+12:45 or UTC-00:25:21
 -14 or +12, -1400 or +12:00

A coercion from timezone name is also provided.


=item * L<date::year|Sah::Schema::date::year>

Year number (AD, starting from 1), e.g. 2022.

=back

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Sah-Schemas-Date>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Sah-Schemas-Date>.

=head1 SEE ALSO

L<Data::Sah::Type::date>

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

This software is copyright (c) 2022, 2020, 2019 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Sah-Schemas-Date>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
