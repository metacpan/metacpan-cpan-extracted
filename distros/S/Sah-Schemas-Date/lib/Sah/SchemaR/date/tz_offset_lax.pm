## no critic: TestingAndDebugging::RequireStrict
package Sah::SchemaR::date::tz_offset_lax;

our $DATE = '2023-12-09'; # DATE
our $VERSION = '0.019'; # VERSION

our $rschema = do{my$var={base=>"int",clsets_after_base=>[{description=>"\nOnly timezone offsets that are known to exist are allowed. For example, 1 second\n(+00:00:01) is not allowed. See `date::tz_offset_lax` for a more relaxed\nvalidation.\n\nA coercion from these form of string is provided:\n\n    UTC\n\n    UTC-14 or UTC+12 or UTC+12:45 or UTC-00:25:21\n    -14 or +12, -1400 or +12:00\n\nA coercion from timezone name is also provided.\n\n",examples=>[{valid=>0,value=>""},{valid=>1,validated_value=>0,value=>"UTC"},{valid=>1,validated_value=>3600,value=>3600},{valid=>1,validated_value=>-43200,value=>-43200},{valid=>1,validated_value=>-43200,value=>-12},{valid=>1,validated_value=>-43200,value=>-1200},{valid=>1,validated_value=>-43200,value=>"-12:00"},{valid=>1,validated_value=>-43200,value=>"UTC-12"},{valid=>1,validated_value=>-43200,value=>"UTC-1200"},{valid=>1,validated_value=>45900,value=>"UTC+12:45"},{valid=>0,value=>"UTC-13"},{summary=>"Unknown offset",valid=>0,value=>"UTC+12:01"}],in=>[-43200,-39600,-37800,-36000,-34200,-32400,-30600,-28800,-25200,-21600,-18000,-16200,-14400,-12600,-10800,-9000,-7200,-3600,-2640,-1521,0,0,1200,1800,3600,5040,5400,7200,9000,10800,12600,14400,16200,17460,18000,19800,20400,20700,21600,23400,25200,26400,27000,28800,30600,31500,32400,34200,35100,36000,37800,39600,41400,43200,45900,46800,49500,50400,-43200,-39600,-37800,-36000,-34200,-32400,-30600,-28800,-25200,-21600,-18000,-16200,-14400,-12600,-10800,-9000,-7200,-3600,-2640,-1521,0,0,1200,1800,3600,5040,5400,7200,9000,10800,12600,14400,16200,17460,18000,19800,20400,20700,21600,23400,25200,26400,27000,28800,30600,31500,32400,34200,35100,36000,37800,39600,41400,43200,45900,46800,49500,50400],summary=>"Timezone offset in seconds from UTC (only known offsets are allowd, coercible from string), e.g. 25200 or \"+07:00\"","x.completion"=>sub{package Sah::Schema::date::tz_offset;use strict;require Complete::TZ;require Complete::Util;my(%args) = @_;Complete::Util::combine_answers(Complete::TZ::complete_tz_offset('word', $args{'word'}), Complete::TZ::complete_tz_name('word', $args{'word'}))},"x.perl.coerce_rules"=>["From_str::tz_offset_strings"]},{description=>"\nThis schema allows timezone offsets that are not known to exist, e.g. 1 second\n(+00:00:01). If you only want ot allow timezone offsets that are known to exist,\nsee the `date::tz_offset` schema.\n\nA coercion from these form of string is provided:\n\n    UTC\n\n    UTC-14 or UTC+12 or UTC+12:45 or UTC-00:25:21\n    -14 or +12, -1400 or +12:00\n\nA coercion from timezone name is also provided.\n\n",examples=>[{valid=>0,value=>""},{valid=>1,validated_value=>0,value=>"UTC"},{valid=>1,validated_value=>3600,value=>3600},{valid=>1,validated_value=>-43200,value=>-43200},{valid=>1,validated_value=>-43200,value=>-12},{valid=>1,validated_value=>-43200,value=>-1200},{valid=>1,validated_value=>-43200,value=>"-12:00"},{valid=>1,validated_value=>-43200,value=>"UTC-12"},{valid=>1,validated_value=>-43200,value=>"UTC-1200"},{valid=>1,validated_value=>45900,value=>"UTC+12:45"},{valid=>0,value=>"UTC-13"},{valid=>1,validated_value=>43260,value=>"UTC+12:01"}],max=>50400,"merge.delete.in"=>[],min=>-43200,summary=>"Timezone offset in seconds from UTC (any offset is allowed, coercible from string), e.g. 1 or 25200 e.g. \"UTC+7\""}],clsets_after_type=>['$var->{clsets_after_base}[0]','$var->{clsets_after_base}[1]'],"clsets_after_type.alt.merge.merged"=>[{description=>"\nThis schema allows timezone offsets that are not known to exist, e.g. 1 second\n(+00:00:01). If you only want ot allow timezone offsets that are known to exist,\nsee the `date::tz_offset` schema.\n\nA coercion from these form of string is provided:\n\n    UTC\n\n    UTC-14 or UTC+12 or UTC+12:45 or UTC-00:25:21\n    -14 or +12, -1400 or +12:00\n\nA coercion from timezone name is also provided.\n\n",examples=>[{valid=>0,value=>""},{valid=>1,validated_value=>0,value=>"UTC"},{valid=>1,validated_value=>3600,value=>3600},{valid=>1,validated_value=>-43200,value=>-43200},{valid=>1,validated_value=>-43200,value=>-12},{valid=>1,validated_value=>-43200,value=>-1200},{valid=>1,validated_value=>-43200,value=>"-12:00"},{valid=>1,validated_value=>-43200,value=>"UTC-12"},{valid=>1,validated_value=>-43200,value=>"UTC-1200"},{valid=>1,validated_value=>45900,value=>"UTC+12:45"},{valid=>0,value=>"UTC-13"},{summary=>"Unknown offset",valid=>1,validated_value=>43260,value=>"UTC+12:01"}],max=>50400,min=>-43200,summary=>"Timezone offset in seconds from UTC (any offset is allowed, coercible from string), e.g. 1 or 25200 e.g. \"UTC+7\"","x.completion"=>'$var->{clsets_after_base}[0]{"x.completion"}',"x.perl.coerce_rules"=>'$var->{clsets_after_base}[0]{"x.perl.coerce_rules"}'}],resolve_path=>["int","date::tz_offset"],type=>"int",v=>2};$var->{clsets_after_type}[0]=$var->{clsets_after_base}[0];$var->{clsets_after_type}[1]=$var->{clsets_after_base}[1];$var->{"clsets_after_type.alt.merge.merged"}[0]{"x.completion"}=$var->{clsets_after_base}[0]{"x.completion"};$var->{"clsets_after_type.alt.merge.merged"}[0]{"x.perl.coerce_rules"}=$var->{clsets_after_base}[0]{"x.perl.coerce_rules"};$var};

1;
# ABSTRACT: Timezone offset in seconds from UTC (any offset is allowed, coercible from string), e.g. 1 or 25200 e.g. "UTC+7"

__END__

=pod

=encoding UTF-8

=head1 NAME

Sah::SchemaR::date::tz_offset_lax - Timezone offset in seconds from UTC (any offset is allowed, coercible from string), e.g. 1 or 25200 e.g. "UTC+7"

=head1 VERSION

This document describes version 0.019 of Sah::SchemaR::date::tz_offset_lax (from Perl distribution Sah-Schemas-Date), released on 2023-12-09.

=head1 DESCRIPTION

This module is automatically generated by Dist::Zilla::Plugin::Sah::Schemas during distribution build.

A Sah::SchemaR::* module is useful if a client wants to quickly lookup the base type of a schema without having to do any extra resolving. With Sah::Schema::*, one might need to do several lookups if a schema is based on another schema, and so on. Compare for example L<Sah::Schema::poseven> vs L<Sah::SchemaR::poseven>, where in Sah::SchemaR::poseven one can immediately get that the base type is C<int>. Currently L<Perinci::Sub::Complete> uses Sah::SchemaR::* instead of Sah::Schema::* for reduced startup overhead when doing tab completion.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Sah-Schemas-Date>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Sah-Schemas-Date>.

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

This software is copyright (c) 2023, 2022, 2020, 2019 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Sah-Schemas-Date>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
