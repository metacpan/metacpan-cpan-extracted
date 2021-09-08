# no code
## no critic: TestingAndDebugging::RequireUseStrict
package Module::Features;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2021-08-27'; # DATE
our $DIST = 'Module-Features'; # DIST
our $VERSION = '0.1.7'; # VERSION

1;
# ABSTRACT: Define features for modules

__END__

=pod

=encoding UTF-8

=head1 NAME

Module::Features - Define features for modules

=head1 SPECIFICATION VERSION

0.1

=head1 VERSION

This document describes version 0.1.7 of Module::Features (from Perl distribution Module-Features), released on 2021-08-27.

=head1 DESCRIPTION

This document specifies a very easy and lightweight way to define and declare
features for modules. A definer module defines some features in a feature set,
other modules declare these features that they have or don't have, and user can
easily check and select modules based on features he/she wants.

The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD",
"SHOULD NOT", "RECOMMENDED", "MAY", and "OPTIONAL" in this document are to be
interpreted as described in RFC 2119.

=head1 SPECIFICATION STATUS

The 0.1.x version series is still unstable.

=head1 GLOSSARY

=head2 feature definer module

A module in "C<Module::Features::>I<FeatureSetName>" namespace that contains
L</"feature set specification">. This module describes what each feature in the
feature set means, what values are valid for the feature, and so on. A
L</"feature declarer module"> follows this specification and declares features.

=head2 feature declarer module

A regular Perl module that wants to declare some features defined by L</"feature
definer module">. Module name must not end with C<::_ModuleFeatures>, in which
case it is a L</"feature declarer proxy module">.

=head2 feature declarer proxy module

A module that declares features for another module. Module name must end with
C<::_ModuleFeatures> and the name of the module it delares features for (the
target module) is its own name sans the C<::_ModuleFeatures> suffix. For
example, the module L<Text::Table::Tiny::_ModuleFeatures> contains L</"features
declaration"> for L<Text::Table::Tiny>.

The point of proxy module is to allow a different author declare features for a
target module.

=head2 feature name

A non-empty string, preferably an identifier matching regex pattern /\A\w+\z/.

=head2 feature value

The value of a feature.

=head2 feature specification

A L<DefHash>, containing the feature's summary, description, schema for value,
and other things.

See L</"Recommendation for feature name">.

=head2 feature set name

A string following regular Perl namespace name, e.g. C<JSON::Encoder> or
C<TextTable>.

=head2 feature set specification

A collection of L</"feature name">s along with each feature's
L<specification|/"feature specification">.

=head2 features declaration

A L<DefHash> containing a list of feature set names and feature values for
features of those feature sets.

=head1 SPECIFICATION

=head2 Defining feature set

A L</"feature definer module"> specifies feature set by putting the L</"feature
set specification"> in C<%FEATURES_DEF> package variable. Specifying feature set
should not require any module dependency.

For example, in L<Module::Features::TextTable>:

 # a DefHash
 our %FEATURES_DEF = (

     # version number of the feature set. positive integer, begins at 1.
     # optional, default is 1 if unspecified. should be increased whenever
     # there's a backward-incompatible change in the feature set, i.e. when one
     # or more features are renamed, deleted, change meaning, or change the
     # schema in a backward-incompatible way (e.g. become more restricted or
     # change type). when a feature set changes in a backward-compatible wa
     # (e.g. a new feature is added, just the summary is revised, etc) then the
     # version number need not be increased.
     v => 1,

     summary => 'Features of a text table generator',

     description => <<'_',
 This feature set defines features of a text table generator. By declaring these
 features, the module author makes it easier for module users to choose an
 appropriate module.
 _

     features => {

         # each key is a feature name. each value is the feature's
         # specification. see recommendation on feature name in this
         # specification.

         can_align_cell_containing_color_code => {
             # a regular DefHash with common properties like 'summary',
             # 'description', 'tags', etc. can also contain these properties:
             # 'schema', 'req' (whether the feature must be declared by user
             # module).

             summary => 'Whether the module can align cells that contain ANSI color codes',
             # schema => 'bool', # Sah schema. if not specified, the default is 'bool'

             tags => ['category:alignment'],
         },
         can_align_cell_containing_newline => {
             summary => 'Whether the module can align cells that contain multiple lines of text',
             tags => ['category:alignment'],
         },
         can_align_cell_containing_wide_character => {
             summary => 'Whether the module can align cells that contain wide Unicode characters',
             tags => ['category:alignment', 'category:unicode'],
         },
         speed => {
             summary => 'The speed of the module, according to the author',
             schema => ['str', in=>['slow', 'medium', 'fast']],
         },
     },
 );

=head2 Recommendations for feature name

Features should be written in lower case and words are separated by underscores,
e.g. C<can_color>, C<max_colors>. The name should be self-explanatory when
possible and should use English.

Singular noun is preferred (e.g C<can_align_cell_containing_wide_character>
instead of C<can_align_cells_containing_wide_characters>) unless when
is is grammatically required to be plurals, e.g. C<max_colors>.

Abbreviations should be avoided unless when an abbrevation is common, e.g.
C<require_filesystem> is preferred over C<req_fs>, but C<max_colors> is okay.

Infinitive form of verb is preferred, e.g. C<require_filesystem_access> instead
of C<requires_filesystem_access>.

Features that refer to whether a module has a specific ability should be named
with C<can_> prefix. Examples: C<can_align_cell_containing_wide_character>,
C<can_color>. These features have a bool value ("yes" or "no"). C<have_> or
C<able_to_> prefix is not preferred.

Features that refer to whether a module needs (requires) a specific
feature/resource to function should be named with C<require_> prefix. C<need_>
prefix is not preferred. Examples: C<require_filesystem_access>.

Features that refer to whether a module can optionally use or prefers something
should be named with C<can_use_> prefix. C<prefer_> or C<want_> prefix is not
preferred.

Features that specify an upper or lower limit of something should be named with
C<max_> or C<min_> prefix. They typically have int/float/num schemas.

=head2 Recommendations for feature definer module

The distribution that ships a feature definer module should add a dependency
(phase=develop, rel=x_spec) to C<Module::Features>, to express that it follows
the Module::Features specification.

=head2 Declaring features

A L</"feature declarer module"> declares features that it supports (or does not
support) via putting the L</"features declaration"> in C<%FEATURES> package
variable. Declaring features should not require any module dependency, but a
helper module can be written to help check that declared feature sets and
features are known and the feature values conform to defined schemas.

Not all features from a feature set need to be declared by the feature declarer
module. The undeclared features will have C<undef> as their values for the
declarer module. However, features defined as required (C<< req => 1 >> in the
specification) MUST be declared.

For example, in L<Text::Table::More>:

 # a DefHash
 our %FEATURES = (

     # optional. specify the versions of the feature sets this declaration uses.
     # the version of feature set must match. versions defaults to 1 if
     # unspecified.
     #set_v => {TextTable => 1},

     # optional, specifies which module version this declaration pertains to
     #module_v => "0.002",

     # optional, a numeric value to be compared against other declarations for
     # the same module. recommended form is YYYYMMDD. for multiple serials in a
     # single day, you can use YYYYMMDD.1, YYYYMMDD.2, YYYYMMDD.91, and so on.
     #serial => 20210223,

     features => {
         # each key is a feature set name.
         TextTable => {
             # each key is a feature name defined in the feature set. each value
             # is either a feature value, or a DefHash that contains the feature
             # value in the 'value' property, and notes in 'summary', and other
             # things.
             can_align_cell_containing_color_code     => 1,
             can_align_cell_containing_wide_character => 1,
             can_align_cell_containing_newline        => 1,
             speed => {
                 value => 'slow', # if unspecified, value will become undef (which means N/A [not available])
                 summary => "It's certainly slower than Text::Table::Tiny, etc; and it can still be made faster after some optimization",
             },
         },
     },
 );

While in L<Text::Table::Sprintf>:

 our %FEATURES = (
     features => {
         TextTable => {
             can_align_cell_containing_color_code     => 0,
             can_align_cell_containing_wide_character => 0,
             can_align_cell_containing_newline        => 0,
             speed                                 => 'fast',
         },
     },
 );

and in L<Text::Table::Any>:

 our %FEATURES = (
     features => {
         TextTable => {
             can_align_cell_containing_color_code     => {value => undef, summary => 'Depends on the backend used'},
             can_align_cell_containing_wide_character => {value => undef, summary => 'Depends on the backend used'},
             can_align_cell_containing_newline        => {value => undef, summary => 'Depends on the backend used'},
             speed                                    => {value => undef, summary => 'Depends on the backend used'},
         },
     },
 );

Features declaration can also be put in other places:

=over

=item * %FEATURES package variable in the L</"feature declarer proxy module">

=item * database

=item * others

=back

The %FEATURES package variable in the feature declarer module itself is
considered to be authoritative, but other places can be checked first to avoid
having to load the feature declarer module. When multiple features declaration
exist, the C<module_v> and/or C<serial> can be used to find out which
declaration is the most recent or suitable.

=head2 Recommendations for feature declarer module

The distribution that ships a feature declarer module should add a dependency
(phase=develop, rel=x_spec) to C<Module::Features>, to express that it follows
the Module::Features specification. It should also add a dependency
(phase=develop, x=features_from> to associated feature definer module(s), to
express that it declares features defined in the associated feature definer
module(s).

=head2 Checking whether a module has a certain feature

The user of a L</"feature declarer module"> can check whether the module has a
certain feature simply by checking the module's L</"features declaration">
(C<%FEATURES>). Checking features of a module should not require any module
dependency.

For example, to check whether Text::Table::Sprintf supports aligning cells that
contain multiple lines:

 if (do { my $val = $Text::Table::Sprintf::FEATURES{features}{TextTable}{align_cell_containing_multiple_lines}; ref $val eq 'HASH' ? $val->{value} : $val }) {
     ...
 }

A utility module can be written to help make this more convenient.

=head1 FAQ

=head2 Why not roles?

Role frameworks like L<Role::Tiny> allow you to require a module to have certain
subroutines, i.e. to follow some kind of interface. This can be used to achieve
the same goal of defining and declaring features, by representing features as
required subroutines and feature sets as roles. However, Module::Features wants
declaring features to have negligible overhead, including no extra runtime
dependency.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Module-Features>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Module-Features>.

=head1 SEE ALSO

L<DefHash>

L<Sah>

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
L<Dist::Zilla::PluginBundle::Author::PERLANCAR>, and sometimes one or two other
Dist::Zilla plugin and/or Pod::Weaver::Plugin. Any additional steps required
beyond that are considered a bug and can be reported to me.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Module-Features>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
