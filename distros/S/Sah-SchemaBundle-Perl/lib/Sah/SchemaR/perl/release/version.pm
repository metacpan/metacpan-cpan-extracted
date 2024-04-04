## no critic: TestingAndDebugging::RequireStrict
package Sah::SchemaR::perl::release::version;

# preamble code
no warnings 'experimental::regex_sets';

our $DATE = '2024-02-16'; # DATE
our $VERSION = '0.050'; # VERSION

our $rschema = do{my$var={base=>"str",clsets_after_base=>[{description=>"\nUse this schema if you want to accept one of the known released versions of\nperl.\n\nThe list of releases of perl is retrieved from the installed core module\n<pm:Module::CoreList> during runtime as well as the one used during build. One\nof both those Module::CoreList instances might not be the latest, so this list\nmight not be up-to-date. To ensure that the list is complete, you will need to\nkeep your copy of Module::CoreList up-to-date.\n\nThe list of version numbers include numified version (which, unfortunately,\ncollapses trailing zeros, e.g. 5.010000 into 5.010) as well as the x.y.z version\n(e.g. 5.10.0).\n\n",in=>[5,"5.0.0","5.000",5.001,5.002,5.00307,5.004,5.00405,5.005,5.00503,5.00504,5.006,"5.006000",5.006001,5.006002,5.007003,5.008,"5.008000",5.008001,5.008002,5.008003,5.008004,5.008005,5.008006,5.008007,5.008008,5.008009,5.009,"5.009000",5.009001,5.009002,5.009003,5.009004,5.009005,5.01,"5.010000",5.010001,5.011,"5.011000",5.011001,5.011002,5.011003,5.011004,5.011005,5.012,"5.012000",5.012001,5.012002,5.012003,5.012004,5.012005,5.013,"5.013000",5.013001,5.013002,5.013003,5.013004,5.013005,5.013006,5.013007,5.013008,5.013009,5.01301,"5.013010",5.013011,5.014,"5.014000",5.014001,5.014002,5.014003,5.014004,5.015,"5.015000",5.015001,5.015002,5.015003,5.015004,5.015005,5.015006,5.015007,5.015008,5.015009,5.016,"5.016000",5.016001,5.016002,5.016003,5.017,"5.017000",5.017001,5.017002,5.017003,5.017004,5.017005,5.017006,5.017007,5.017008,5.017009,5.01701,"5.017010",5.017011,5.018,"5.018000",5.018001,5.018002,5.018003,5.018004,5.019,"5.019000",5.019001,5.019002,5.019003,5.019004,5.019005,5.019006,5.019007,5.019008,5.019009,5.01901,"5.019010",5.019011,5.02,"5.020000",5.020001,5.020002,5.020003,5.021,"5.021000",5.021001,5.021002,5.021003,5.021004,5.021005,5.021006,5.021007,5.021008,5.021009,5.02101,"5.021010",5.021011,5.022,"5.022000",5.022001,5.022002,5.022003,5.022004,5.023,"5.023000",5.023001,5.023002,5.023003,5.023004,5.023005,5.023006,5.023007,5.023008,5.023009,5.024,"5.024000",5.024001,5.024002,5.024003,5.024004,5.025,"5.025000",5.025001,5.025002,5.025003,5.025004,5.025005,5.025006,5.025007,5.025008,5.025009,5.02501,"5.025010",5.025011,5.025012,5.026,"5.026000",5.026001,5.026002,5.026003,5.027,"5.027000",5.027001,5.027002,5.027003,5.027004,5.027005,5.027006,5.027007,5.027008,5.027009,5.02701,"5.027010",5.027011,5.028,"5.028000",5.028001,5.028002,5.028003,5.029,"5.029000",5.029001,5.029002,5.029003,5.029004,5.029005,5.029006,5.029007,5.029008,5.029009,5.02901,"5.029010",5.03,"5.030000",5.030001,5.030002,5.030003,5.031,"5.031000",5.031001,5.031002,5.031003,5.031004,5.031005,5.031006,5.031007,5.031008,5.031009,5.03101,"5.031010",5.031011,5.032,"5.032000",5.032001,5.033,"5.033000",5.033001,5.033002,5.033003,5.033004,5.033005,5.033006,5.033007,5.033008,5.033009,5.034,"5.034000",5.034001,5.034002,5.034003,5.035,"5.035000",5.035001,5.035002,5.035003,5.035004,5.035005,5.035006,5.035007,5.035008,5.035009,5.03501,"5.035010",5.035011,5.036,"5.036000",5.036001,5.036002,5.036003,5.037,"5.037000",5.037001,5.037002,5.037003,5.037004,5.037005,5.037006,5.037007,5.037008,5.037009,5.03701,"5.037010",5.037011,5.038,"5.038000",5.038001,5.038002,5.039001,5.039002,5.039003,5.039004,5.039005,"5.1.0","5.10.0","5.10.1","5.11.0","5.11.1","5.11.2","5.11.3","5.11.4","5.11.5","5.12.0","5.12.1","5.12.2","5.12.3","5.12.4","5.12.5","5.13.0","5.13.1","5.13.10","5.13.11","5.13.2","5.13.3","5.13.4","5.13.5","5.13.6","5.13.7","5.13.8","5.13.9","5.14.0","5.14.1","5.14.2","5.14.3","5.14.4","5.15.0","5.15.1","5.15.2","5.15.3","5.15.4","5.15.5","5.15.6","5.15.7","5.15.8","5.15.9","5.16.0","5.16.1","5.16.2","5.16.3","5.17.0","5.17.1","5.17.10","5.17.11","5.17.2","5.17.3","5.17.4","5.17.5","5.17.6","5.17.7","5.17.8","5.17.9","5.18.0","5.18.1","5.18.2","5.18.3","5.18.4","5.19.0","5.19.1","5.19.10","5.19.11","5.19.2","5.19.3","5.19.4","5.19.5","5.19.6","5.19.7","5.19.8","5.19.9","5.2.0","5.20.0","5.20.1","5.20.2","5.20.3","5.21.0","5.21.1","5.21.10","5.21.11","5.21.2","5.21.3","5.21.4","5.21.5","5.21.6","5.21.7","5.21.8","5.21.9","5.22.0","5.22.1","5.22.2","5.22.3","5.22.4","5.23.0","5.23.1","5.23.2","5.23.3","5.23.4","5.23.5","5.23.6","5.23.7","5.23.8","5.23.9","5.24.0","5.24.1","5.24.2","5.24.3","5.24.4","5.25.0","5.25.1","5.25.10","5.25.11","5.25.12","5.25.2","5.25.3","5.25.4","5.25.5","5.25.6","5.25.7","5.25.8","5.25.9","5.26.0","5.26.1","5.26.2","5.26.3","5.27.0","5.27.1","5.27.10","5.27.11","5.27.2","5.27.3","5.27.4","5.27.5","5.27.6","5.27.7","5.27.8","5.27.9","5.28.0","5.28.1","5.28.2","5.28.3","5.29.0","5.29.1","5.29.10","5.29.2","5.29.3","5.29.4","5.29.5","5.29.6","5.29.7","5.29.8","5.29.9","5.3.70","5.30.0","5.30.1","5.30.2","5.30.3","5.31.0","5.31.1","5.31.10","5.31.11","5.31.2","5.31.3","5.31.4","5.31.5","5.31.6","5.31.7","5.31.8","5.31.9","5.32.0","5.32.1","5.33.0","5.33.1","5.33.2","5.33.3","5.33.4","5.33.5","5.33.6","5.33.7","5.33.8","5.33.9","5.34.0","5.34.1","5.34.2","5.34.3","5.35.0","5.35.1","5.35.10","5.35.11","5.35.2","5.35.3","5.35.4","5.35.5","5.35.6","5.35.7","5.35.8","5.35.9","5.36.0","5.36.1","5.36.2","5.36.3","5.37.0","5.37.1","5.37.10","5.37.11","5.37.2","5.37.3","5.37.4","5.37.5","5.37.6","5.37.7","5.37.8","5.37.9","5.38.0","5.38.1","5.38.2","5.39.1","5.39.2","5.39.3","5.39.4","5.39.5","5.4.0","5.4.50","5.5.0","5.5.30","5.5.40","5.6.0","5.6.1","5.6.2","5.7.3","5.8.0","5.8.1","5.8.2","5.8.3","5.8.4","5.8.5","5.8.6","5.8.7","5.8.8","5.8.9","5.9.0","5.9.1","5.9.2","5.9.3","5.9.4","5.9.5"],summary=>"One of known released versions of perl (e.g. 5.010 or 5.10.0)"}],clsets_after_type=>['$var->{clsets_after_base}[0]'],"clsets_after_type.alt.merge.merged"=>['$var->{clsets_after_base}[0]'],resolve_path=>["str"],type=>"str",v=>2};$var->{clsets_after_type}[0]=$var->{clsets_after_base}[0];$var->{"clsets_after_type.alt.merge.merged"}[0]=$var->{clsets_after_base}[0];$var};

1;
# ABSTRACT: One of known released versions of perl (e.g. 5.010 or 5.10.0)

__END__

=pod

=encoding UTF-8

=head1 NAME

Sah::SchemaR::perl::release::version - One of known released versions of perl (e.g. 5.010 or 5.10.0)

=head1 VERSION

This document describes version 0.050 of Sah::SchemaR::perl::release::version (from Perl distribution Sah-SchemaBundle-Perl), released on 2024-02-16.

=head1 DESCRIPTION

This module is automatically generated by Dist::Zilla::Plugin::Sah::SchemaBundle during distribution build.

A Sah::SchemaR::* module is useful if a client wants to quickly lookup the base type of a schema without having to do any extra resolving. With Sah::Schema::*, one might need to do several lookups if a schema is based on another schema, and so on. Compare for example L<Sah::Schema::poseven> vs L<Sah::SchemaR::poseven>, where in Sah::SchemaR::poseven one can immediately get that the base type is C<int>. Currently L<Perinci::Sub::Complete> uses Sah::SchemaR::* instead of Sah::Schema::* for reduced startup overhead when doing tab completion.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Sah-SchemaBundle-Perl>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Sah-SchemaBundle-Perl>.

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

This software is copyright (c) 2024, 2023, 2022, 2021, 2020, 2019, 2018, 2017, 2016 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Sah-SchemaBundle-Perl>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
