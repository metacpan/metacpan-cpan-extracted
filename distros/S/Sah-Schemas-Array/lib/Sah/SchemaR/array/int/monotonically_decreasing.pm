## no critic: TestingAndDebugging::RequireStrict
package Sah::SchemaR::array::int::monotonically_decreasing;

our $DATE = '2023-02-03'; # DATE
our $VERSION = '0.003'; # VERSION

our $rschema = do{my$var={base=>"array",clsets_after_base=>[{description=>"\nThis is like the `array::num::monotonically_decreasing` schema except elements\nmust be integers.\n\n",examples=>[{summary=>"Not an array",valid=>0,value=>{}},{valid=>1,value=>[]},{summary=>"Contains a non-numeric element",valid=>0,value=>[1,"a"]},{summary=>"Contains an undefined element",valid=>0,value=>[1,undef]},{summary=>"Duplicate elements",valid=>0,value=>[3,2,2,1]},{summary=>"Not monotonically decreasing",valid=>0,value=>[1,2,3]},{summary=>"Not monotonically decreasing",valid=>0,value=>[1,3,2]},{valid=>1,value=>[3,2.9,1]}],of=>["num",{req=>1}],prefilters=>["Array::check_elems_numeric_monotonically_decreasing"],summary=>"An array of integers with monotonically decreasing elements"}],clsets_after_type=>['$var->{clsets_after_base}[0]'],"clsets_after_type.alt.merge.merged"=>['$var->{clsets_after_base}[0]'],resolve_path=>["array"],type=>"array",v=>2};$var->{clsets_after_type}[0]=$var->{clsets_after_base}[0];$var->{"clsets_after_type.alt.merge.merged"}[0]=$var->{clsets_after_base}[0];$var};

1;
# ABSTRACT: An array of integers with monotonically decreasing elements

__END__

=pod

=encoding UTF-8

=head1 NAME

Sah::SchemaR::array::int::monotonically_decreasing - An array of integers with monotonically decreasing elements

=head1 VERSION

This document describes version 0.003 of Sah::SchemaR::array::int::monotonically_decreasing (from Perl distribution Sah-Schemas-Array), released on 2023-02-03.

=head1 DESCRIPTION

This module is automatically generated by Dist::Zilla::Plugin::Sah::Schemas during distribution build.

A Sah::SchemaR::* module is useful if a client wants to quickly lookup the base type of a schema without having to do any extra resolving. With Sah::Schema::*, one might need to do several lookups if a schema is based on another schema, and so on. Compare for example L<Sah::Schema::poseven> vs L<Sah::SchemaR::poseven>, where in Sah::SchemaR::poseven one can immediately get that the base type is C<int>. Currently L<Perinci::Sub::Complete> uses Sah::SchemaR::* instead of Sah::Schema::* for reduced startup overhead when doing tab completion.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Sah-Schemas-Array>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Sah-Schemas-Array>.

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

This software is copyright (c) 2023 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Sah-Schemas-Array>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
