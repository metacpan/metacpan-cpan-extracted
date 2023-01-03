## no critic: TestingAndDebugging::RequireStrict
package Sah::SchemaR::cpanmodules::entry;

our $DATE = '2022-09-25'; # DATE
our $VERSION = '0.003'; # VERSION

our $rschema = do{my$var={base=>"hash",clsets_after_base=>[{allowed_keys_re=>qr(\A(?:([A-Za-z_][A-Za-z0-9_]*)|([A-Za-z_][A-Za-z0-9_]*)?\.([A-Za-z_][A-Za-z0-9_]*(?:\.[A-Za-z_][A-Za-z0-9_]*)*))\z),examples=>[{valid=>1,value=>{}},{valid=>1,value=>{bar=>1,foo=>1}},{summary=>"Invalid property syntax, contains dash",valid=>0,value=>{"foo-bar"=>1}}],keys=>{caption=>["str",{req=>1}],default_lang=>["str",{match=>"\\A[a-z]{2}(_[A-Z]{2})?\\z",req=>1},{}],defhash_v=>["int",{default=>1,req=>1}],description=>["str",{req=>1}],name=>["str",{clset=>[{match=>"\\A\\w+\\z","match.err_level"=>"warn","match.err_msg"=>"should be a word"},{max_len=>32,"max_len.err_level"=>"warn","max_len.err_msg"=>"should be short"}],"clset.op"=>"and",req=>1}],summary=>["str",{clset=>[{max_len=>72,"max_len.err_level"=>"warn","max_len.err_msg"=>"should be short"},{match=>qr(\n),"match.err_level"=>"warn","match.err_msg"=>"should only be a single-line text","match.op"=>"not"}],"clset.op"=>"and",req=>1}],tags=>["array",{of=>["any",{of=>[["str",{req=>1}],["hash",{req=>1}]],req=>1}]}],v=>["float",{default=>1,req=>1}],x=>["any",{},{}]},"keys.restrict"=>0,summary=>"DefHash"},{"keys.restrict"=>1,"merge.add.keys"=>{alternate_modules=>["perl::modnames",{req=>1}],bench_code=>["code",{req=>1}],bench_code_template=>["str",{req=>1}],defhash_v=>["int",{is=>1,req=>1}],module=>["perl::modname",{req=>1}],rating=>["int",{max=>10,min=>1}],related_modules=>["perl::modnames",{req=>1}],script=>["str*",{req=>1}],scripts=>["array",{of=>["str*",{req=>1}],req=>1}],v=>["int",{is=>1,req=>1}]},summary=>"A single Acme::CPANModules list entry, e.g. {module=>\"Foo\"}"}],clsets_after_type=>['$var->{clsets_after_base}[0]','$var->{clsets_after_base}[1]'],"clsets_after_type.alt.merge.merged"=>[{allowed_keys_re=>'$var->{clsets_after_base}[0]{allowed_keys_re}',examples=>'$var->{clsets_after_base}[0]{examples}',keys=>{alternate_modules=>'$var->{clsets_after_base}[1]{"merge.add.keys"}{alternate_modules}',bench_code=>'$var->{clsets_after_base}[1]{"merge.add.keys"}{bench_code}',bench_code_template=>'$var->{clsets_after_base}[1]{"merge.add.keys"}{bench_code_template}',caption=>'$var->{clsets_after_base}[0]{keys}{caption}',default_lang=>'$var->{clsets_after_base}[0]{keys}{default_lang}',defhash_v=>["int",{default=>1,is=>1,req=>1}],description=>'$var->{clsets_after_base}[0]{keys}{description}',module=>'$var->{clsets_after_base}[1]{"merge.add.keys"}{module}',name=>'$var->{clsets_after_base}[0]{keys}{name}',rating=>'$var->{clsets_after_base}[1]{"merge.add.keys"}{rating}',related_modules=>'$var->{clsets_after_base}[1]{"merge.add.keys"}{related_modules}',script=>'$var->{clsets_after_base}[1]{"merge.add.keys"}{script}',scripts=>'$var->{clsets_after_base}[1]{"merge.add.keys"}{scripts}',summary=>'$var->{clsets_after_base}[0]{keys}{summary}',tags=>'$var->{clsets_after_base}[0]{keys}{tags}',v=>["int",{default=>1,is=>1,req=>1}],x=>'$var->{clsets_after_base}[0]{keys}{x}'},"keys.restrict"=>1,summary=>"A single Acme::CPANModules list entry, e.g. {module=>\"Foo\"}"}],resolve_path=>["hash","defhash"],type=>"hash",v=>2};$var->{clsets_after_type}[0]=$var->{clsets_after_base}[0];$var->{clsets_after_type}[1]=$var->{clsets_after_base}[1];$var->{"clsets_after_type.alt.merge.merged"}[0]{allowed_keys_re}=$var->{clsets_after_base}[0]{allowed_keys_re};$var->{"clsets_after_type.alt.merge.merged"}[0]{examples}=$var->{clsets_after_base}[0]{examples};$var->{"clsets_after_type.alt.merge.merged"}[0]{keys}{alternate_modules}=$var->{clsets_after_base}[1]{"merge.add.keys"}{alternate_modules};$var->{"clsets_after_type.alt.merge.merged"}[0]{keys}{bench_code}=$var->{clsets_after_base}[1]{"merge.add.keys"}{bench_code};$var->{"clsets_after_type.alt.merge.merged"}[0]{keys}{bench_code_template}=$var->{clsets_after_base}[1]{"merge.add.keys"}{bench_code_template};$var->{"clsets_after_type.alt.merge.merged"}[0]{keys}{caption}=$var->{clsets_after_base}[0]{keys}{caption};$var->{"clsets_after_type.alt.merge.merged"}[0]{keys}{default_lang}=$var->{clsets_after_base}[0]{keys}{default_lang};$var->{"clsets_after_type.alt.merge.merged"}[0]{keys}{description}=$var->{clsets_after_base}[0]{keys}{description};$var->{"clsets_after_type.alt.merge.merged"}[0]{keys}{module}=$var->{clsets_after_base}[1]{"merge.add.keys"}{module};$var->{"clsets_after_type.alt.merge.merged"}[0]{keys}{name}=$var->{clsets_after_base}[0]{keys}{name};$var->{"clsets_after_type.alt.merge.merged"}[0]{keys}{rating}=$var->{clsets_after_base}[1]{"merge.add.keys"}{rating};$var->{"clsets_after_type.alt.merge.merged"}[0]{keys}{related_modules}=$var->{clsets_after_base}[1]{"merge.add.keys"}{related_modules};$var->{"clsets_after_type.alt.merge.merged"}[0]{keys}{script}=$var->{clsets_after_base}[1]{"merge.add.keys"}{script};$var->{"clsets_after_type.alt.merge.merged"}[0]{keys}{scripts}=$var->{clsets_after_base}[1]{"merge.add.keys"}{scripts};$var->{"clsets_after_type.alt.merge.merged"}[0]{keys}{summary}=$var->{clsets_after_base}[0]{keys}{summary};$var->{"clsets_after_type.alt.merge.merged"}[0]{keys}{tags}=$var->{clsets_after_base}[0]{keys}{tags};$var->{"clsets_after_type.alt.merge.merged"}[0]{keys}{x}=$var->{clsets_after_base}[0]{keys}{x};$var};

1;
# ABSTRACT: A single Acme::CPANModules list entry, e.g. {module=>"Foo"}

__END__

=pod

=encoding UTF-8

=head1 NAME

Sah::SchemaR::cpanmodules::entry - A single Acme::CPANModules list entry, e.g. {module=>"Foo"}

=head1 VERSION

This document describes version 0.003 of Sah::SchemaR::cpanmodules::entry (from Perl distribution Sah-Schemas-CPANModules), released on 2022-09-25.

=head1 DESCRIPTION

This module is automatically generated by Dist::Zilla::Plugin::Sah::Schemas during distribution build.

A Sah::SchemaR::* module is useful if a client wants to quickly lookup the base type of a schema without having to do any extra resolving. With Sah::Schema::*, one might need to do several lookups if a schema is based on another schema, and so on. Compare for example L<Sah::Schema::poseven> vs L<Sah::SchemaR::poseven>, where in Sah::SchemaR::poseven one can immediately get that the base type is C<int>. Currently L<Perinci::Sub::Complete> uses Sah::SchemaR::* instead of Sah::Schema::* for reduced startup overhead when doing tab completion.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Sah-Schemas-CPANModules>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Sah-Schemas-CPANModules>.

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

This software is copyright (c) 2022 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Sah-Schemas-CPANModules>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
