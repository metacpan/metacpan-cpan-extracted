package Module::Provision::Config;

use namespace::autoclean;

use Class::Usul::Constants qw( NUL TRUE );
use Class::Usul::Functions qw( fullname loginid logname untaint_cmdline
                               untaint_identifier );
use File::DataClass::Types qw( ArrayRef HashRef NonEmptySimpleStr
                               Path SimpleStr Undef );
use Moo;

extends qw(Class::Usul::Config::Programs);

# Object attributes (public)
has 'author'           => is => 'lazy', isa => NonEmptySimpleStr,
   builder             => sub {
      my $author =  untaint_cmdline $ENV{AUTHOR} || fullname || logname;
         $author =~ s{ [\'] }{\'}gmx; return $author };

has 'author_email'     => is => 'lazy', isa => NonEmptySimpleStr,
   builder             => sub {
      my $email =  untaint_cmdline $ENV{EMAIL} || 'dave@example.com';
         $email =~ s{ [\'] }{\'}gmx; return $email };

has 'author_id'        => is => 'lazy', isa => NonEmptySimpleStr,
   builder             => sub { loginid };

has 'base'             => is => 'lazy', isa => Path, coerce => TRUE,
   builder             => sub { $_[ 0 ]->my_home };

has 'builder'          => is => 'lazy', isa => NonEmptySimpleStr,
   default             => 'MB';

has 'coverage_server'  => is => 'ro',   isa => NonEmptySimpleStr,
   default             => 'http://localhost:5000/coverage';

has 'default_branches' => is => 'lazy', isa => HashRef,
   builder             => sub { { git => 'master', svn => 'trunk' } };

has 'delete_files_uri' => is => 'lazy', isa => NonEmptySimpleStr,
   builder             => sub { untaint_cmdline $ENV{CPAN_DELETE_FILES_URI}
                                || 'https://pause.perl.org/pause/authenquery' };

has 'editor'           => is => 'lazy', isa => NonEmptySimpleStr,
   builder             => sub { untaint_identifier $ENV{EDITOR} || 'emacs' };

has 'home_page'        => is => 'lazy', isa => NonEmptySimpleStr,
   default             => 'http://example.com';

has 'hooks'            => is => 'lazy', isa => ArrayRef[NonEmptySimpleStr],
   builder             => sub { [ 'commit-msg', 'pre-commit' ] };

has 'license'          => is => 'lazy', isa => NonEmptySimpleStr,
   default             => 'perl';

has 'localdir'         => is => 'ro',   isa => NonEmptySimpleStr,
   default             => 'local';

has 'min_perl_ver'     => is => 'lazy', isa => NonEmptySimpleStr,
   default             => '5.010001';

has 'module_abstract'  => is => 'lazy', isa => NonEmptySimpleStr,
   default             => 'One-line description of the modules purpose';

has 'pub_repo_prefix'  => is => 'ro',   isa => SimpleStr, default => 'p5-';

has 'remote_test_id'   => is => 'ro',   isa => NonEmptySimpleStr,
   default             => 'test@testhost';

has 'remote_script'    => is => 'ro',   isa => NonEmptySimpleStr,
   default             => 'install_perl_module';

has 'repository'       => is => 'lazy', isa => NonEmptySimpleStr,
   default             => 'repository';

has 'seed_file'        => is => 'lazy', isa => Path | Undef, coerce => TRUE,
   builder             => sub { [ qw( ~ .ssh pause.key ) ] };

has 'signing_key'      => is => 'lazy', isa => SimpleStr,
   default             => NUL;

has 'tag_message'      => is => 'lazy', isa => NonEmptySimpleStr,
   default             => 'Releasing';

has 'template_index'   => is => 'lazy', isa => NonEmptySimpleStr,
   default             => 'index.json';

has 'test_env_vars'    => is => 'lazy', isa => ArrayRef,
   documentation       => 'Set these environment vars to true when testing',
   builder             => sub {
      [ qw( AUTHOR_TESTING TEST_MEMORY TEST_SPELLING ) ] };

has 'vcs'              => is => 'lazy', isa => NonEmptySimpleStr,
   default             => 'git';

1;

__END__

=pod

=encoding utf-8

=head1 Name

Module::Provision::Config - Attributes set from the config file

=head1 Synopsis

   use Moo;

   extends 'Class::Usul::Programs';

   has '+config_class' => default => sub { 'Module::Provision::Config' };

=head1 Description

Defines attributes which can be set from the config file

=head1 Configuration and Environment

Defines the following attributes;

=over 3

=item C<author>

A non empty simple string which defaults to the value of the environment
variable C<AUTHOR>. If the environment variable is unset
defaults to C<fullname> and then C<logname>

=item C<author_email>

A non empty simple string which defaults to the value of the environment
variable C<EMAIL>. If the environment variable is unset
defaults to C<dave@example.com>

=item C<author_id>

A non empty simple string which defaults to the author's login identity

=item C<base>

A path object which defaults to the authors home directory. The default
directory in which to create new distributions

=item C<builder>

A non empty simple string default to C<MB>. Selects the build system to
use when creating new distributions

=item C<coverage_server>

The HTTP address of the coverage server. Used by the badge markup feature

=item C<default_branches>

A hash reference. The default branch names for the C<git> and C<svn> VCSs
which are C<master> and C<trunk> respectively

=item C<delete_files_uri>

A non empty simple string which defaults to the value of the environment
variable C<CPAN_DELETE_FILES_URI>. If the environment variable is unset
defaults to C<https://pause.perl.org/pause/authenquery>. The URI of the
PAUSE service

=item C<editor>

A non empty simple string which defaults to the value of the environment
variable C<EDITOR>. If the environment variable is unset defaults to
C<emacs>. Which editor to invoke which C<edit_project> is called

=item C<home_page>

A non empty simple string which default to C<http://example.com>. Override
this in the configuration file to set the meta data used when creating a
distribution

=item C<hooks>

An array reference of non empty simple strings which defaults to F<commit-msg>
and F<pre-commit>. This list of Git hooks is operated on by the C<add_hooks>
method

=item C<license>

A non empty simple string which defaults to C<perl>. The default license for
new distributions

=item C<localdir>

A non empty simple string which defaults to F<local>. The directory into which
L<local::lib> should be installed

=item C<min_perl_ver>

Non empty simple string that is used as the default in the meta data of a
newly minted distribution

=item C<module_abstract>

A non empty simple string which is used as the default abstract for newly
minted modules

=item C<pub_repo_prefix>

A simple string which default to C<p5->. Prepended to the lower cased
distribution name it forms the name of the public repository

=item C<remote_test_id>

A non empty simple string that defaults to C<test@testhost>. The identity
and host used to perform test installations

=item C<remote_script>

A non empty simple string that defaults to C<install_perl_module>. The command
to execute on the test installation server

=item C<repository>

A non empty simple string which defaults to C<repository>. Name of the
L</appbase> subdirectory expected to contain a Git repository

=item C<seed_file>

File object reference or undefined. This optionally points to the file
containing the key to decrypt the author's PAUSE account password which
is stored in the F<~/.pause> file

=item C<signing_key>

Simple string that defaults to C<NUL>. If non null then this string is used
as a fingerprint to find the author distribution signing key

=item C<tag_message>

Non empty simple string defaults to C<Releasing>. This is the default message
to apply to the commit which creates a tagged release

=item C<template_index>

Name of the file containing the index of templates. Defaults to F<index.json>

=item C<test_env_vars>

Array reference. Set these environment vars to true when testing. Defaults
to; C<AUTHOR_TESTING TEST_MEMORY>, and C<TEST_SPELLING>

=item C<vcs>

A non empty simple string that defaults to C<git>. The default version control
system

=back

=head1 Subroutines/Methods

None

=head1 Diagnostics

None

=head1 Dependencies

=over 3

=item L<Class::Usul>

=item L<File::DataClass>

=item L<User::pwent>

=back

=head1 Incompatibilities

There are no known incompatibilities in this module

=head1 Bugs and Limitations

There are no known bugs in this module.
Please report problems to the address below.
Patches are welcome

=head1 Acknowledgements

Larry Wall - For the Perl programming language

=head1 Author

Peter Flanigan, C<< <pjfl@cpan.org> >>

=head1 License and Copyright

Copyright (c) 2017 Peter Flanigan. All rights reserved

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself. See L<perlartistic>

This program is distributed in the hope that it will be useful,
but WITHOUT WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE

=cut

# Local Variables:
# mode: perl
# tab-width: 3
# End:
