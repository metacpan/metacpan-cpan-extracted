## no critic: TestingAndDebugging::RequireStrict
package Sah::SchemaR::perl::modargs;

# preamble code
no warnings 'experimental::regex_sets';

our $DATE = '2024-02-16'; # DATE
our $VERSION = '0.050'; # VERSION

our $rschema = do{my$var={base=>"perl::modname_with_optional_args",clsets_after_base=>[{summary=>"Shorter alias for perl::modname_with_optional_args"}],clsets_after_type=>[{description=>"\nPerl module name with optional arguments which will be used as import arguments,\njust like the `-MMODULE=ARGS` shortcut that `perl` provides. Examples:\n\n    Foo\n    Foo::Bar\n    Foo::Bar=arg1,arg2\n\nSee also: `perl::modname`.\nA two-element array from (coercible from JSON string) is also allowed:\n\n    [\"Foo::Bar\", \\\@args]\n\n",examples=>[{valid=>0,value=>""},{valid=>1,value=>"Foo::Bar"},{valid=>1,value=>"Foo::Bar=arg1,arg2"},{valid=>1,validated_value=>"Foo::Bar=arg1,arg2",value=>"Foo-Bar=arg1,arg2"},{summary=>"No module name",valid=>0,value=>[]},{valid=>1,value=>["Foo"]},{summary=>"Invalid module name",valid=>0,value=>["Foo Bar"]},{summary=>"Args must be arrayref or hashref",valid=>0,value=>["Foo","arg"]},{valid=>1,value=>["Foo",{arg1=>1,arg2=>2}]},{valid=>1,value=>["Foo",["arg1","arg2"]]},{summary=>"Too many elements",valid=>0,value=>["Foo",["arg1","arg2"],{}]}],of=>[["array_from_json",{description=>"\nThese are valid values for this schema:\n\n    [\"Foo\"]                                      # just the module name\n    [\"Foo::Bar\", [\"arg1\",\"arg2\"]]                # with import arguments (array)\n    [\"Foo::Bar\", {\"arg1\"=>\"val\",\"arg2\"=>\"val\"}]  # with import arguments (hash)\n\n",elems=>[["perl::modname",{req=>1}],["any",{of=>[["array",{req=>1}],["hash",{req=>1}]],req=>1}]],examples=>['$var->{clsets_after_type}[0]{examples}[4]','$var->{clsets_after_type}[0]{examples}[5]','$var->{clsets_after_type}[0]{examples}[6]','$var->{clsets_after_type}[0]{examples}[7]','$var->{clsets_after_type}[0]{examples}[8]','$var->{clsets_after_type}[0]{examples}[9]','$var->{clsets_after_type}[0]{examples}[10]'],max_len=>2,min_len=>1,summary=>"A 1- or 2-element array containing Perl module name (e.g. [\"Foo::Bar\"]) with optional arguments (e.g. [\"Foo::Bar\", [\"arg1\",\"arg2\"]])"}],["str",{description=>"\nPerl module name with optional arguments which will be used as import arguments,\njust like the `-MMODULE=ARGS` shortcut that `perl` provides. Examples:\n\n    Foo\n    Foo::Bar\n    Foo::Bar=arg1,arg2\n\nSee also: `perl::modname`.\n\n",examples=>['$var->{clsets_after_type}[0]{examples}[0]','$var->{clsets_after_type}[0]{examples}[1]','$var->{clsets_after_type}[0]{examples}[2]','$var->{clsets_after_type}[0]{examples}[3]'],match=>"\\A(?:[A-Za-z_][A-Za-z_0-9]*(::[A-Za-z_0-9]+)*(?:=.*)?)\\z",summary=>"Perl module name (e.g. Foo::Bar) with optional arguments (e.g. Foo::Bar=arg1,arg2)","x.completion"=>"perl_modname","x.perl.coerce_rules"=>["From_str::normalize_perl_modname"]}]],summary=>"Perl module name (e.g. Foo::Bar) with optional arguments (e.g. Foo::Bar=arg1,arg2)","x.completion"=>"perl_modname"},'$var->{clsets_after_base}[0]'],"clsets_after_type.alt.merge.merged"=>['$var->{clsets_after_type}[0]','$var->{clsets_after_base}[0]'],resolve_path=>["any","perl::modname_with_optional_args"],type=>"any",v=>2};$var->{clsets_after_type}[0]{of}[0][1]{examples}[0]=$var->{clsets_after_type}[0]{examples}[4];$var->{clsets_after_type}[0]{of}[0][1]{examples}[1]=$var->{clsets_after_type}[0]{examples}[5];$var->{clsets_after_type}[0]{of}[0][1]{examples}[2]=$var->{clsets_after_type}[0]{examples}[6];$var->{clsets_after_type}[0]{of}[0][1]{examples}[3]=$var->{clsets_after_type}[0]{examples}[7];$var->{clsets_after_type}[0]{of}[0][1]{examples}[4]=$var->{clsets_after_type}[0]{examples}[8];$var->{clsets_after_type}[0]{of}[0][1]{examples}[5]=$var->{clsets_after_type}[0]{examples}[9];$var->{clsets_after_type}[0]{of}[0][1]{examples}[6]=$var->{clsets_after_type}[0]{examples}[10];$var->{clsets_after_type}[0]{of}[1][1]{examples}[0]=$var->{clsets_after_type}[0]{examples}[0];$var->{clsets_after_type}[0]{of}[1][1]{examples}[1]=$var->{clsets_after_type}[0]{examples}[1];$var->{clsets_after_type}[0]{of}[1][1]{examples}[2]=$var->{clsets_after_type}[0]{examples}[2];$var->{clsets_after_type}[0]{of}[1][1]{examples}[3]=$var->{clsets_after_type}[0]{examples}[3];$var->{clsets_after_type}[1]=$var->{clsets_after_base}[0];$var->{"clsets_after_type.alt.merge.merged"}[0]=$var->{clsets_after_type}[0];$var->{"clsets_after_type.alt.merge.merged"}[1]=$var->{clsets_after_base}[0];$var};

1;
# ABSTRACT: Shorter alias for perl::modname_with_optional_args

__END__

=pod

=encoding UTF-8

=head1 NAME

Sah::SchemaR::perl::modargs - Shorter alias for perl::modname_with_optional_args

=head1 VERSION

This document describes version 0.050 of Sah::SchemaR::perl::modargs (from Perl distribution Sah-SchemaBundle-Perl), released on 2024-02-16.

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
