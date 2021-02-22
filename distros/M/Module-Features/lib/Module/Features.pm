package Module::Features;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2021-02-22'; # DATE
our $DIST = 'Module-Features'; # DIST
our $VERSION = '0.1.2'; # VERSION

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

This document describes version 0.1.2 of Module::Features (from Perl distribution Module-Features), released on 2021-02-22.

=head1 DESCRIPTION

This document specifies a very easy and lightweight way to define and declare
features for modules. A definer module defines some features in a feature set,
other modules declare these features that they have or don't have, and user can
easily check and select modules based on features he/she wants.

=head1 SPECIFICATION STATUS

The series 0.1.x version is still unstable.

=head1 GLOSSARY

=head2 definer module

Module in the namespace of C<Module::Features::>I<FeatureSetName> that contains
L</"feature set specification">. This module describes what each feature in the
feature set means, what values are valid for the feature, and so on. A L</"user
module"> follows the specification and declares features.

=head2 user module

A regular Perl module that wants to declare some features defined by L</"definer
module">.

=head2 feature name

A string, preferably an identifier matching regex pattern /\A\w+\z/.

=head2 feature value

The value of a feature.

=head2 feature specification

A L<DefHash>, containing the feature's summary, description, schema for value,
and other things.

=head2 feature set name

A string following regular Perl namespace name, e.g. C<JSON::Encoder> or
C<TextTable>.

=head2 feature set specification

A collection of L</"feature name">s along with each feature's
L<specification|/"feature specification">.

=head1 SPECIFICATION

=head2 Defining feature set

L<Definer module|/"definer module"> defines feature set by putting it in
C<%FEATURES_DEF> package variable. Defining feature set should not require any
module dependency.

For example, in L<Module::Features::TextTable>:

 # a DefHash
 our %FEATURES_DEF = (
     summary => 'Features of a text table generator',
     description => <<'_',
 This feature set defines features of a text table generator. By declaring these
 features, the module author makes it easier for module users to choose an
 appropriate module.
 _
     features => {
         # each key is a feature name. each value is the feature's specification.

         align_cell_containing_color_codes => {
             # a regular DefHash with common properties like 'summary',
             # 'description', 'tags', etc. can also contain these properties:
             # 'schema', 'req' (whether the feature must be declared by user
             # module).

             summary => 'Whether the module can align cells that contain ANSI color codes',
             # schema => 'bool*', # Sah schema. if not specified, the default is 'bool*'
         },
         align_cell_containing_multiple_lines => {
             summary => 'Whether the module can align cells that contain multiple lines of text',
         },
         align_cell_containing_wide_characters => {
             summary => 'Whether the module can align cells that contain wide Unicode characters',
         },
         speed => {
             summary => 'The speed of the module, according to the author',
             schema => ['int', in=>['slow', 'medium', 'fast']],
         },
     },
 );

=head2 Declaring features

L<User module|/"user module"> declares features that it supports (or does not
support) via putting it in C<%FEATURES> package variable. Declaring features
should not require any module dependency, but a helper module can be written to
help check that declared feature sets and features are known and the feature
values conform to defined schemas.

Not all features from a feature set need to be declared by the user module. The
undeclared features will have C<undef> as their values for the user module.
However, features defined as required (C<< req => 1 >> in the specification)
MUST be declared.

For example, in L<Text::Table::More>:

 our %FEATURES = (
     # each key is a feature set name.
     TextTable => {
         # each key is a feature name defined in the feature set. each value is
         # either a feature value, or a DefHash that contains the feature value
         # in the 'value' property, and notes in 'summary', and other things.
         align_cell_containing_color_codes     => 1,
         align_cell_containing_wide_characters => 1,
         align_cell_containing_multiple_lines  => 1,
         speed => {
             value => 'slow', # if unspecified, value will become undef
             summary => "It's certainly slower than Text::Table::Tiny, etc; and it can still be made faster after some optimization",
         },
     },
 );

While in L<Text::Table::Sprintf>:

 our %FEATURES = (
     TextTable => {
         align_cell_containing_color_codes     => 0,
         align_cell_containing_wide_characters => 0,
         align_cell_containing_multiple_lines  => 0,
         speed                                 => 'fast',
     },
 );

and in L<Text::Table::Any>:

 our %FEATURES = (
     TextTable => {
         align_cell_containing_color_codes     => {value => undef, summary => 'Depends on the backend used'},
         align_cell_containing_wide_characters => {value => undef, summary => 'Depends on the backend used'},
         align_cell_containing_multiple_lines  => {value => undef, summary => 'Depends on the backend used'},
         speed                                 => {value => undef, summary => 'Depends on the backend used'},
     },
 );

=head2 Checking whether a module has a certain feature

A L</"user module"> user can check whether a user module has a certain feature
simply by checking the user module's C<%FEATURES>. Checking features of a module
should not require any module dependency.

For example, to check whether
Text::Table::Sprintf supports aligning cells that contain multiple lines:

 if (do { my $val = $Text::Table::Sprintf::FEATURES{TextTable}{align_cell_containing_multiple_lines}; ref $val eq 'HASH' ? $val->{value} : $val }) {
     ...
 }

A utility module can be written to help make this more convenient.

=head2 Selecting modules by its feature

Each module that one wants to select can be loaded and its C<%FEATURES> read. To
avoid loading lots of modules, the features declaration can also be put
somewhere else if wanted, like database, or per-distribution shared files, or
distribution metadata. Currently no specific recommendation is given.

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

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://github.com/perlancar/perl-Module-Features/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<DefHash>

L<Sah>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
