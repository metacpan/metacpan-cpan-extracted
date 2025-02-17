## no critic: TestingAndDebugging::RequireStrict
package Sah::SchemaR::firefox::local_profile_name;

our $DATE = '2023-06-14'; # DATE
our $VERSION = '0.008'; # VERSION

our $rschema = do{my$var={base=>"firefox::profile_name",clsets_after_base=>[{description=>"\nThis is like the `firefox::profile_name` schema, but adds a check (in\n`prefilter` clause) that the profile must exist in local Firefox installation.\n\n",examples=>[{test=>0,valid=>0,value=>""},{summary=>"Assuming the profile named \"default\" exists in local Firefox installation",test=>0,valid=>1,value=>"default"}],prefilters=>["Firefox::check_profile_name_exists"],summary=>"Firefox profile name, must exist in local Firefox installation"}],clsets_after_type=>[{description=>"\nThis is currently just `str` with a minimum length of 1, but adds a completion\nrule to complete from list of profiles from local Firefox installation.\n\n",examples=>[{valid=>0,value=>""},{valid=>1,value=>"standard"}],min_len=>1,summary=>"Firefox profile name","x.completion"=>"firefox_profile_name"},'$var->{clsets_after_base}[0]'],"clsets_after_type.alt.merge.merged"=>['$var->{clsets_after_type}[0]','$var->{clsets_after_base}[0]'],resolve_path=>["str","firefox::profile_name"],type=>"str",v=>2};$var->{clsets_after_type}[1]=$var->{clsets_after_base}[0];$var->{"clsets_after_type.alt.merge.merged"}[0]=$var->{clsets_after_type}[0];$var->{"clsets_after_type.alt.merge.merged"}[1]=$var->{clsets_after_base}[0];$var};

1;
# ABSTRACT: Firefox profile name, must exist in local Firefox installation

__END__

=pod

=encoding UTF-8

=head1 NAME

Sah::SchemaR::firefox::local_profile_name - Firefox profile name, must exist in local Firefox installation

=head1 VERSION

This document describes version 0.008 of Sah::SchemaR::firefox::local_profile_name (from Perl distribution Sah-Schemas-Firefox), released on 2023-06-14.

=head1 DESCRIPTION

This module is automatically generated by Dist::Zilla::Plugin::Sah::Schemas during distribution build.

A Sah::SchemaR::* module is useful if a client wants to quickly lookup the base type of a schema without having to do any extra resolving. With Sah::Schema::*, one might need to do several lookups if a schema is based on another schema, and so on. Compare for example L<Sah::Schema::poseven> vs L<Sah::SchemaR::poseven>, where in Sah::SchemaR::poseven one can immediately get that the base type is C<int>. Currently L<Perinci::Sub::Complete> uses Sah::SchemaR::* instead of Sah::Schema::* for reduced startup overhead when doing tab completion.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Sah-Schemas-Firefox>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Sah-Schemas-Firefox>.

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

This software is copyright (c) 2023, 2020 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Sah-Schemas-Firefox>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
