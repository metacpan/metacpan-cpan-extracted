# no code
## no critic: TestingAndDebugging::RequireUseStrict
package Sah::SchemaBundle::Perl;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2024-02-16'; # DATE
our $DIST = 'Sah-SchemaBundle-Perl'; # DIST
our $VERSION = '0.050'; # VERSION

1;
# ABSTRACT: Sah schemas related to Perl

__END__

=pod

=encoding UTF-8

=head1 NAME

Sah::SchemaBundle::Perl - Sah schemas related to Perl

=head1 VERSION

This document describes version 0.050 of Sah::SchemaBundle::Perl (from Perl distribution Sah-SchemaBundle-Perl), released on 2024-02-16.

=head1 SAH SCHEMAS

The following schemas are included in this distribution:

=over

=item * L<perl::distname|Sah::Schema::perl::distname>

Perl distribution name, e.g. Foo-Bar.

This is a schema you can use when you want to accept a Perl distribution name,
e.g. C<WWW-Mechanize>. It offers basic checking of syntax as well as a couple of
conveniences. First, it offers completion from list of locally installed Perl
distribution. Second, it contains coercion rule so you can also input
C<Foo::Bar>, C<Foo/Bar>, C<Foo/Bar.pm>, or even 'Foo.Bar' and it will be normalized
into C<Foo-Bar>.

To see this schema in action on the CLI, you can try e.g. the C<dist-has-deb>
script from L<App::DistUtils> and activate its tab completion (see its manpage
for more details). Then on the CLI try typing:

 % dist-has-deb WWW-<tab>
 % dist-has-deb dzp/<tab>

Note that this schema does not check that the Perl disribution exists on CPAN or
is installed locally. To check that, use the C<perl::distname::installed> schema.
And there's also a C<perl::distname::not_installed> schema.


=item * L<perl::distname::default_this_dist|Sah::Schema::perl::distname::default_this_dist>

Perl distribution name, defaults to "this distribution".

See L<App::ThisDist>'s C<this_dist()> for more details on how "this
distribution" is determined. Note that C<App::ThisDist> is not added as
dependency automatically; you will have to add it manually.

Note: be careful when using this schema for actions that are destructive to a
Perl dist or that change some things, because a user can perform those actions
without giving an argument (e.g. a C<delete-dist> script). It is safer to use
this schema to perform a non=destructive action (e.g. C<ls-dist>) and/or
operate in dry-run mode by default.


=item * L<perl::distname_with_optional_ver|Sah::Schema::perl::distname_with_optional_ver>

Perl distribution name (e.g. Foo-Bar) with optional version number suffix (e.g. Foo-Bar@0.001).

For convenience (particularly in CLI with tab completion), you can input one of:

 Foo::Bar
 Foo/Bar
 Foo/Bar.pm
 Foo.Bar

and it will be coerced into Foo-Bar form.


=item * L<perl::distname_with_ver|Sah::Schema::perl::distname_with_ver>

Perl distribution name with version number suffix, e.g. Foo-Bar@0.001.

For convenience (particularly in CLI with tab completion), you can input one of:

 Foo::Bar@1.23
 Foo/Bar@1.23
 Foo/Bar.pm@1.23
 Foo.Bar@1.23

and it will be coerced into Foo-Bar form.


=item * L<perl::filename|Sah::Schema::perl::filename>

Filename of Perl scriptE<sol>moduleE<sol>POD, e.g. E<sol>pathE<sol>FooE<sol>Bar.pm.

Use this schema if you want to accept a filesystem path containing Perl script,
module, or POD. The value of this schema is in the convenience of CLI
completion, as well as coercion from script or module name.

String containing filename of a Perl script or module or POD. For convenience,
when value is in the form of:

 Foo
 Foo.pm
 Foo.pod
 Foo::Bar
 Foo/Bar
 Foo/Bar.pm
 Foo/Bar.pod

and a matching .pod or .pm file is found in C<@INC>, then it will be coerced
(converted) into the path of that .pod/.pm file, e.g.:

 /home/ujang/perl5/perlbrew/perls/perl-5.24.0/lib/site_perl/5.24.0/Foo/Bar.pm
 lib/Foo/Bar.pod

To prevent such coercion, you can use prefixing path, e.g.:

 ./Foo::Bar
 ../Foo/Bar
 /path/to/Foo/Bar

This schema comes with convenience completion too.


=item * L<perl::funcname|Sah::Schema::perl::funcname>

Perl function name, either qualified with package name (e.g. Foo::subname) or unqualified (e.g. subname).

Currently function name is restricted to this regex:

 \A[A-Za-z_][A-Za-z_0-9]*\z

Function name can be qualified (prefixed) by a package name, which is restricted
to this regex:

 [A-Za-z_][A-Za-z_0-9]*(::[A-Za-z_0-9]+)*


=item * L<perl::identifier::qualified_ascii|Sah::Schema::perl::identifier::qualified_ascii>

Qualified identifier in Perl, without "use utf8" in effect.




=item * L<perl::identifier::qualified_unicode|Sah::Schema::perl::identifier::qualified_unicode>

Unqualified identifier in Perl, with "use utf8" in effect.




=item * L<perl::identifier::unqualified_ascii|Sah::Schema::perl::identifier::unqualified_ascii>

Unqualified identifier in Perl, without "use utf8" in effect.




=item * L<perl::identifier::unqualified_unicode|Sah::Schema::perl::identifier::unqualified_unicode>

Unqualified identifier in Perl, with "use utf8" in effect.




=item * L<perl::modargs|Sah::Schema::perl::modargs>

Shorter alias for perl::modname_with_optional_args.

=item * L<perl::modname|Sah::Schema::perl::modname>

Perl module name, e.g. Foo::Bar.

This is a schema you can use when you want to accept a Perl module name. It
offers basic checking of syntax as well as a couple of conveniences. First, it
offers completion from list of locally installed Perl modules. Second, it
contains coercion rule so you can also input C<Foo-Bar>, C<Foo/Bar>, C<Foo/Bar.pm>
or even 'Foo.Bar' and it will be normalized into C<Foo::Bar>.

To see this schema in action on the CLI, you can try e.g. the C<pmless> script
from L<App::PMUtils> and activate its tab completion (see its manpage for more
details). Then on the CLI try typing:

 % pmless M/<tab>
 % pmless dzp/<tab>
 % pmless Module/List/Wildcard
 % pmless Module::List::Wildcard

Note that this schema does not check that the Perl module exists or is installed
locally. To check that, use the C<perl::modname::installed> schema. And there's
also a C<perl::modname::not_installed> schema.


=item * L<perl::modname::default_this_mod|Sah::Schema::perl::modname::default_this_mod>

Perl module, defaults to "this module".

See L<App::ThisDist>'s C<this_mod()> for more details on how "this module" is
determined. Note that C<App::ThisDist> is not added as dependency automatically;
you will have to add it manually.

Note: be careful when using this schema for actions that are destructive to a
Perl module or that change some things, because a user can perform those actions
without giving an argument (e.g. a C<delete-module> script). It is safer to use
this schema to perform a non=destructive action (e.g. C<man-module>) and/or
operate in dry-run mode by default.


=item * L<perl::modname::installed|Sah::Schema::perl::modname::installed>

Name of a Perl module that is installed locally.

This schema is based on the C<perl::modname> schema with an additional check that
the perl module is installed locally. Checking is done using
L<Module::Installed::Tiny>. This check fetches the source code of the module
from filesystem or %INC hooks, but does not actually load/execute the code.


=item * L<perl::modname::not_installed|Sah::Schema::perl::modname::not_installed>

Name of a Perl module that is not installed locally.

This schema is based on the C<perl::modname> schema with an additional check that
the perl module is not installed locally. Checking is done using
L<Module::Installed::Tiny>. This check fetches the source code of the module
from filesystem or %INC hooks, but does not actually load/execute the code.


=item * L<perl::modname_or_prefix|Sah::Schema::perl::modname_or_prefix>

Perl module name (e.g. Foo::Bar) or prefix (e.g. Foo::Bar::).

Contains coercion rule so inputing C<Foo-Bar> or C<Foo/Bar> will be normalized to
C<Foo::Bar> while inputing C<Foo-Bar-> or C<Foo/Bar/> will be normalized to
C<Foo::Bar::>

See also: C<perl::modname> and C<perl::modprefix>.


=item * L<perl::modname_pm|Sah::Schema::perl::modname_pm>

Perl module name in FooE<sol>Bar.pm form.

This is just like the C<perl::modname> schema except that instead of to
C<Foo::Bar>, it normalizes to C<Foo/Bar.pm>.


=item * L<perl::modname_with_optional_args|Sah::Schema::perl::modname_with_optional_args>

Perl module name (e.g. Foo::Bar) with optional arguments (e.g. Foo::Bar=arg1,arg2).

Perl module name with optional arguments which will be used as import arguments,
just like the C<-MMODULE=ARGS> shortcut that C<perl> provides. Examples:

 Foo
 Foo::Bar
 Foo::Bar=arg1,arg2

See also: C<perl::modname>.
A two-element array from (coercible from JSON string) is also allowed:

 ["Foo::Bar", \@args]


=item * L<perl::modname_with_optional_ver|Sah::Schema::perl::modname_with_optional_ver>

Perl module name (e.g. Foo::Bar) with optional version number suffix (e.g. Foo::Bar@0.001).

=item * L<perl::modname_with_ver|Sah::Schema::perl::modname_with_ver>

Perl module name with version number suffix, e.g. Foo::Bar@0.001.

=item * L<perl::modnames|Sah::Schema::perl::modnames>

Array of Perl module names, e.g. ["Foo::Bar", "Baz"].

Array of Perl module names, where each element is of C<perl::modname> schema,
e.g. C<Foo>, C<Foo::Bar>.

Contains coercion rule that expands wildcard, so you can specify:

 Module::P*

and it will be expanded to e.g.:

 ["Module::Patch", "Module::Path", "Module::Pluggable"]

The wildcard syntax supports jokers (C<?>, C<*>, C<**>), brackets (C<[abc]>), and
braces (C<{one,two}>). See L<Module::List::Wildcard> for more details.


=item * L<perl::modprefix|Sah::Schema::perl::modprefix>

Perl module prefix, e.g. Foo::Bar::.

Perl module prefix, e.g. C<Foo::Bar::>. An empty prefix ('') is also allowed.

Contains coercion rule so you can also input:

 Foo-Bar
 Foo-Bar-
 Foo-Bar
 Foo/Bar
 Foo/Bar/
 Foo::Bar

and it will be normalized into C<Foo::Bar::>.


=item * L<perl::modprefixes|Sah::Schema::perl::modprefixes>

Perl module prefixes, e.g. ["", "Foo::", "Foo::Bar::"].

Array of Perl module prefixes, where each element is of C<perl::modprefix>
schema, e.g. C<Foo::>, C<Foo::Bar::>.

Contains coercion rule that expands wildcard, so you can specify:

 Module::C*

and it will be expanded to e.g.:

 ["Module::CPANTS::", "Module::CPANfile::", "Module::CheckVersion::", "Module::CoreList::"]

The wildcard syntax supports jokers (C<?>, '*C<) and brackets (>[abc]C<). See the
>unix` type of wildcard in L<Regexp::Wildcards>, which this coercion rule
uses.


=item * L<perl::module::release::version|Sah::Schema::perl::module::release::version>

Expression to select module release.

=item * L<perl::module::release::versions|Sah::Schema::perl::module::release::versions>

=item * L<perl::pm_filename|Sah::Schema::perl::pm_filename>

A .pm filename, e.g. E<sol>pathE<sol>Foo.pm.

Use this schema if you want to accept a filesystem path containing Perl module.
The value of this schema is in the convenience of CLI completion, as well as
coercion from module name.

String containing filename of a Perl module. For convenience, when value is in
the form of:

 Foo
 Foo.pm
 Foo::Bar
 Foo/Bar
 Foo/Bar.pm

and a matching .pm file is found in C<@INC>, then it will be coerced (converted)
into the path of that .pm file, e.g.:

 /home/ujang/perl5/perlbrew/perls/perl-5.24.0/lib/site_perl/5.24.0/Foo/Bar.pm

To prevent such coercion, you can use prefixing path, e.g.:

 ./Foo::Bar
 ../Foo/Bar
 /path/to/Foo/Bar

This schema comes with convenience completion too.


=item * L<perl::pod_filename|Sah::Schema::perl::pod_filename>

A .pod filename, e.g. E<sol>pathE<sol>Foo.pod.

Use this schema if you want to accept a filesystem path containing Perl POD. The
value of this schema is in the convenience of CLI completion, as well as
coercion from POD name.

String containing filename of a Perl .pod file. For convenience, when value is
in the form of:

 Foo
 Foo.pod
 Foo::Bar
 Foo/Bar
 Foo/Bar.pod

and a matching .pod file is found in C<@INC>, then it will be coerced (converted)
into the filesystem path of that .pod file, e.g.:

 /home/ujang/perl5/perlbrew/perls/perl-5.24.0/lib/site_perl/5.24.0/Foo/Bar.pod

To prevent such coercion, you can use prefixing path, e.g.:

 ./Foo::Bar
 ../Foo/Bar
 /path/to/Foo/Bar

This schema comes with convenience completion too.


=item * L<perl::pod_or_pm_filename|Sah::Schema::perl::pod_or_pm_filename>

A .pod or .pm filename, e.g. E<sol>pathE<sol>Foo.pm or E<sol>pathE<sol>BarE<sol>Baz.pod.

String containing filename of a Perl POD or module. For convenience, when value
is in the form of:

 Foo
 Foo.pod
 Foo.pm
 Foo::Bar
 Foo/Bar
 Foo/Bar.pod
 Foo/Bar.pm

and a matching .pod or .pm file is found in C<@INC>, then it will be coerced
(converted) into the path of that .pod/.pm file, e.g.:

 /home/ujang/perl5/perlbrew/perls/perl-5.24.0/lib/site_perl/5.24.0/Foo/Bar.pm
 lib/Foo/Bar.pod

To prevent such coercion, you can use prefixing path, e.g.:

 ./Foo::Bar
 ../Foo/Bar
 /path/to/Foo/Bar

This schema comes with convenience completion too.

This schema is like another schema C<perl::filename> except that .pod is
prioritized over .pm. If both C<Foo.pm> and C<Foo.pod> are found in C<@INC>, the
path to C<Foo.pod> will be returned.


=item * L<perl::podname|Sah::Schema::perl::podname>

Perl POD name, e.g. Moose::Cookbook.

Perl POD name, e.g. C<Config>, C<Some::Other::POD>.

Basically the same as C<perl::modname>, but with a different completion.


=item * L<perl::qualified_funcname|Sah::Schema::perl::qualified_funcname>

Perl function name qualified with a package name, e.g. Foo::subname.

Currently function name is restricted to this regex:

 \A[A-Za-z_][A-Za-z_0-9]*\z

and package name is restricted to this regex:

 [A-Za-z_][A-Za-z_0-9]*(::[A-Za-z_0-9]+)*

This schema includes syntax validity check only; it does not check whether the
function actually exists.


=item * L<perl::release::version|Sah::Schema::perl::release::version>

One of known released versions of perl (e.g. 5.010 or 5.10.0).

Use this schema if you want to accept one of the known released versions of
perl.

The list of releases of perl is retrieved from the installed core module
L<Module::CoreList> during runtime as well as the one used during build. One
of both those Module::CoreList instances might not be the latest, so this list
might not be up-to-date. To ensure that the list is complete, you will need to
keep your copy of Module::CoreList up-to-date.

The list of version numbers include numified version (which, unfortunately,
collapses trailing zeros, e.g. 5.010000 into 5.010) as well as the x.y.z version
(e.g. 5.10.0).


=item * L<perl::unqualified_funcname|Sah::Schema::perl::unqualified_funcname>

Perl function name which must not be qualified with a package name, e.g. subname.

Currently function name is restricted to this regex:

 \A[A-Za-z_][A-Za-z_0-9]*\z

This schema includes syntax validity check only; it does not check whether the
function actually exists.

This schema includes syntax validity check only; it does not check whether the
function actually exists.


=item * L<perl::version|Sah::Schema::perl::version>

Perl version object.

Use this schema if you want to accept a version object (see L<version>).
Coercion from string is provided.


=back

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Sah-SchemaBundle-Perl>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Sah-SchemaBundle-Perl>.

=head1 SEE ALSO

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

This software is copyright (c) 2024, 2023, 2022, 2021, 2020, 2019, 2018, 2017, 2016 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Sah-SchemaBundle-Perl>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
