package Sah::SchemaR::rinci::function_meta;

our $DATE = '2021-07-20'; # DATE
our $VERSION = '1.1.98.0'; # VERSION

our $rschema = do{my$var=["hash",[{_prop=>{args=>{_value_prop=>{caption=>{},cmdline_aliases=>{_value_prop=>{code=>{},description=>{},is_flag=>{},schema=>{},summary=>{}}},cmdline_on_getopt=>{},cmdline_prompt=>{},cmdline_src=>{},completion=>{},default=>{},default_lang=>{},defhash_v=>{},deps=>{_keys=>{all=>{},any=>{},arg=>{},none=>{}}},description=>{},element_completion=>{},element_meta=>{_prop=>'$var->[1][0]{_prop}',_ver=>1.1,examples=>[{valid=>1,value=>{}},{valid=>1,value=>{args=>{a1=>{},a2=>{}},summary=>"Some function",v=>1.1}}],summary=>"Rinci function metadata"},examples=>{},filters=>{},greedy=>{},index_completion=>{},is_password=>{},links=>{},meta=>'$var->[1][0]{_prop}{args}{_value_prop}{element_meta}',name=>{},partial=>{},pos=>{},req=>{},schema=>{},slurpy=>{},stream=>{},summary=>{},tags=>{},v=>{},x=>{}}},args_as=>{},args_rels=>{},caption=>'$var->[1][0]{_prop}{args}{_value_prop}{caption}',default_lang=>'$var->[1][0]{_prop}{args}{_value_prop}{default_lang}',defhash_v=>'$var->[1][0]{_prop}{args}{_value_prop}{defhash_v}',deps=>{_keys=>{all=>{},any=>{},code=>{},env=>{},func=>{},none=>{},pkg=>{},prog=>{},tmp_dir=>{},trash_dir=>{}}},description=>'$var->[1][0]{_prop}{args}{_value_prop}{description}',entity_date=>{},entity_v=>{},examples=>{_elem_prop=>{args=>{},argv=>{},caption=>'$var->[1][0]{_prop}{args}{_value_prop}{caption}',default_lang=>'$var->[1][0]{_prop}{args}{_value_prop}{default_lang}',defhash_v=>'$var->[1][0]{_prop}{args}{_value_prop}{defhash_v}',description=>'$var->[1][0]{_prop}{args}{_value_prop}{description}',env_result=>{},naked_result=>{},name=>'$var->[1][0]{_prop}{args}{_value_prop}{name}',result=>{},src=>{},src_plang=>{},status=>{},summary=>'$var->[1][0]{_prop}{args}{_value_prop}{summary}',tags=>'$var->[1][0]{_prop}{args}{_value_prop}{tags}',test=>{},v=>'$var->[1][0]{_prop}{args}{_value_prop}{v}',x=>'$var->[1][0]{_prop}{args}{_value_prop}{x}'}},features=>{_keys=>{check_arg=>{},dry_run=>{},idempotent=>{},immutable=>{},pure=>{},reverse=>{},tx=>{}}},is_class_meth=>{},is_func=>{},is_meth=>{},links=>{},name=>'$var->[1][0]{_prop}{args}{_value_prop}{name}',result=>{_prop=>{caption=>'$var->[1][0]{_prop}{args}{_value_prop}{caption}',default_lang=>'$var->[1][0]{_prop}{args}{_value_prop}{default_lang}',defhash_v=>'$var->[1][0]{_prop}{args}{_value_prop}{defhash_v}',description=>'$var->[1][0]{_prop}{args}{_value_prop}{description}',name=>'$var->[1][0]{_prop}{args}{_value_prop}{name}',partial=>{},schema=>{},statuses=>{_value_prop=>{description=>{},schema=>{},summary=>{}}},stream=>{},summary=>'$var->[1][0]{_prop}{args}{_value_prop}{summary}',tags=>'$var->[1][0]{_prop}{args}{_value_prop}{tags}',v=>'$var->[1][0]{_prop}{args}{_value_prop}{v}',x=>'$var->[1][0]{_prop}{args}{_value_prop}{x}'}},result_naked=>{},summary=>'$var->[1][0]{_prop}{args}{_value_prop}{summary}',tags=>'$var->[1][0]{_prop}{args}{_value_prop}{tags}',v=>'$var->[1][0]{_prop}{args}{_value_prop}{v}',x=>'$var->[1][0]{_prop}{args}{_value_prop}{x}'},_ver=>1.1,examples=>'$var->[1][0]{_prop}{args}{_value_prop}{element_meta}{examples}',summary=>"Rinci function metadata"}],["hash"]];$var->[1][0]{_prop}{args}{_value_prop}{element_meta}{_prop}=$var->[1][0]{_prop};$var->[1][0]{_prop}{args}{_value_prop}{meta}=$var->[1][0]{_prop}{args}{_value_prop}{element_meta};$var->[1][0]{_prop}{caption}=$var->[1][0]{_prop}{args}{_value_prop}{caption};$var->[1][0]{_prop}{default_lang}=$var->[1][0]{_prop}{args}{_value_prop}{default_lang};$var->[1][0]{_prop}{defhash_v}=$var->[1][0]{_prop}{args}{_value_prop}{defhash_v};$var->[1][0]{_prop}{description}=$var->[1][0]{_prop}{args}{_value_prop}{description};$var->[1][0]{_prop}{examples}{_elem_prop}{caption}=$var->[1][0]{_prop}{args}{_value_prop}{caption};$var->[1][0]{_prop}{examples}{_elem_prop}{default_lang}=$var->[1][0]{_prop}{args}{_value_prop}{default_lang};$var->[1][0]{_prop}{examples}{_elem_prop}{defhash_v}=$var->[1][0]{_prop}{args}{_value_prop}{defhash_v};$var->[1][0]{_prop}{examples}{_elem_prop}{description}=$var->[1][0]{_prop}{args}{_value_prop}{description};$var->[1][0]{_prop}{examples}{_elem_prop}{name}=$var->[1][0]{_prop}{args}{_value_prop}{name};$var->[1][0]{_prop}{examples}{_elem_prop}{summary}=$var->[1][0]{_prop}{args}{_value_prop}{summary};$var->[1][0]{_prop}{examples}{_elem_prop}{tags}=$var->[1][0]{_prop}{args}{_value_prop}{tags};$var->[1][0]{_prop}{examples}{_elem_prop}{v}=$var->[1][0]{_prop}{args}{_value_prop}{v};$var->[1][0]{_prop}{examples}{_elem_prop}{x}=$var->[1][0]{_prop}{args}{_value_prop}{x};$var->[1][0]{_prop}{name}=$var->[1][0]{_prop}{args}{_value_prop}{name};$var->[1][0]{_prop}{result}{_prop}{caption}=$var->[1][0]{_prop}{args}{_value_prop}{caption};$var->[1][0]{_prop}{result}{_prop}{default_lang}=$var->[1][0]{_prop}{args}{_value_prop}{default_lang};$var->[1][0]{_prop}{result}{_prop}{defhash_v}=$var->[1][0]{_prop}{args}{_value_prop}{defhash_v};$var->[1][0]{_prop}{result}{_prop}{description}=$var->[1][0]{_prop}{args}{_value_prop}{description};$var->[1][0]{_prop}{result}{_prop}{name}=$var->[1][0]{_prop}{args}{_value_prop}{name};$var->[1][0]{_prop}{result}{_prop}{summary}=$var->[1][0]{_prop}{args}{_value_prop}{summary};$var->[1][0]{_prop}{result}{_prop}{tags}=$var->[1][0]{_prop}{args}{_value_prop}{tags};$var->[1][0]{_prop}{result}{_prop}{v}=$var->[1][0]{_prop}{args}{_value_prop}{v};$var->[1][0]{_prop}{result}{_prop}{x}=$var->[1][0]{_prop}{args}{_value_prop}{x};$var->[1][0]{_prop}{summary}=$var->[1][0]{_prop}{args}{_value_prop}{summary};$var->[1][0]{_prop}{tags}=$var->[1][0]{_prop}{args}{_value_prop}{tags};$var->[1][0]{_prop}{v}=$var->[1][0]{_prop}{args}{_value_prop}{v};$var->[1][0]{_prop}{x}=$var->[1][0]{_prop}{args}{_value_prop}{x};$var->[1][0]{examples}=$var->[1][0]{_prop}{args}{_value_prop}{element_meta}{examples};$var};

1;
# ABSTRACT: Rinci function metadata

__END__

=pod

=encoding UTF-8

=head1 NAME

Sah::SchemaR::rinci::function_meta - Rinci function metadata

=head1 VERSION

This document describes version 1.1.98.0 of Sah::SchemaR::rinci::function_meta (from Perl distribution Sah-Schemas-Rinci), released on 2021-07-20.

=head1 DESCRIPTION

This module is automatically generated by Dist::Zilla::Plugin::Sah::Schemas during distribution build.

A Sah::SchemaR::* module is useful if a client wants to quickly lookup the base type of a schema without having to do any extra resolving. With Sah::Schema::*, one might need to do several lookups if a schema is based on another schema, and so on. Compare for example L<Sah::Schema::poseven> vs L<Sah::SchemaR::poseven>, where in Sah::SchemaR::poseven one can immediately get that the base type is C<int>. Currently L<Perinci::Sub::Complete> uses Sah::SchemaR::* instead of Sah::Schema::* for reduced startup overhead when doing tab completion.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Sah-Schemas-Rinci>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Sah-Schemas-Rinci>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Sah-Schemas-Rinci>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021, 2020, 2019, 2018, 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
