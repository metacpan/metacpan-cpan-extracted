package Shipwright;

use warnings;
use strict;
use version; our $VERSION = qv('2.4.41');

use base qw/Shipwright::Base/;

__PACKAGE__->mk_accessors(qw/backend source build log_level log_file/);

use Shipwright::Logger;
use File::Spec::Functions qw/catfile tmpdir/;
use Shipwright::Util;
# strawberry perl's build make is 'dmake'
use File::Which 'which';
$ENV{SHIPWRIGHT_MAKE} ||= which('make') || which('dmake') || which( 'nmake' ) || 'make';
$ENV{SHIPWRIGHT_SVK}  ||= which('svk')  || 'svk';
$ENV{SHIPWRIGHT_SVN}  ||= which('svn')  || 'svn';
$ENV{SHIPWRIGHT_GIT}  ||= which('git')  || 'git';
$ENV{SHIPWRIGHT_DZIL} ||= which('dzil') || 'dzil';
$ENV{SHIPWRIGHT_LWP_TIMEOUT} ||= 1200;

$ENV{PERL_MM_USE_DEFAULT} = 1; # always true

# FTP_PASSIVE is true by default,
# since many sites use this nowadays.
unless ( defined $ENV{FTP_PASSIVE} ) {
    $ENV{FTP_PASSIVE} = 1;
}

=head2 new

=cut

sub new {
    my $class = shift;

    my %args = (
        log_level  => undef,
        log_file   => undef,
        repository => undef,
        source     => undef,
        @_
    );
    $args{log_level} = $args{log_level} ? uc $args{log_level} : 'FATAL';

    $args{log_file} = '-' unless $args{log_file};

    my $self = {
        log_level => $args{log_level},
        log_file  => $args{log_file},
    };

    bless $self, $class;

    Shipwright::Logger->new($self);

    if ( $args{repository} ) {
        require Shipwright::Backend;
        $self->backend( Shipwright::Backend->new(%args) );
    }

    if ( $args{source} ) {
        require Shipwright::Source;
        $self->source( Shipwright::Source->new(%args) );
    }

    return $self;
}

1;

__END__

=head1 NAME

Shipwright - Best Practical Builder

=head1 SYNOPSIS

    $ export SHIPWRIGHT_SHIPYARD=fs:/tmp/fs
    $ shipwright create 
    # import will take a while, enjoy your coffee!
    $ shipwright import cpan:Jifty
    $ cd /tmp/fs
    $ ./bin/shipwright-builder --install-base /tmp/jifty

    one liner doing the same thing:
    $ shipwright-generate cpan:Jifty | perl - --install-base /tmp/jifty


=head1 DESCRIPTION

=head2 Why use Shipwright?

Most software packages depend on other bits of software in order to avoid code
repetition. This may result in pain when attempting to install the software,
due to the maze of dependencies, especially for large projects with many
dependencies.

Shipwright is a tool to help you bundle your software with all its
dependencies, regardless of whether they are CPAN modules or non-Perl modules
from elsewhere. Shipwright makes the bundle work easy.

=head2 Introduction

If this is your first time using Shipwright, L<Shipwright::Manual::Tutorial> is
probably a better place to start.

=head2 Design

The idea of Shipwright is simple:

    sources                        shipwright factory
---------------------           ------------------------
|  all the separate |  import   |  shipyard             |  build
|  sources          |  =====>   |                       |  ====>
---------------------           ------------------------

     vessel (final product)
----------------------------------------------
| all packages installed with smart wrappers |
----------------------------------------------

=head2 What's in a shipyard

=head3 shipyard after initialization

After initializing a shipyard, the files in the repository are:

bin/
    # used for building, installing and testing
     shipwright-builder
    # a utility for doing things such as updating the build order
     shipwright-utility

etc/
    # wrapper for installed bin files, mainly for optimizing the environment
     shipwright-script-wrapper
    # wrapper for installed perl scripts
    shipwright-perl-wrapper
    # source files you can `source', for tcsh and bash, respectively.
    # both will be installed to tools/
    shipwright-source-tcsh, shipwright-source-bash
    # utility which will be installed to tools/
    shipwright-utility
    # set env bat for windows
    shipwright-windows-setenv.bat

inc/ # modules for shipwright itself

sources/      # all the sources live here

scripts/    # all the build scripts and dependency hints live here

shipwright/

    # branches note, see L<Shipwright::Manual::UsingBranches>
    branches.yml
    # flags note, see L<Shipwright::Manual::UsingFlags>
    flags.yml		
    # test failures note
    known_test_failures.yml
    # cpan dists' module => name map
    map.yml
    # the actual build order
    order.yml
    # reference count note
    refs.yml
    # non-cpan dists' name => url map
    source.yml
    # sources' version
    version.yml

t/
    # will run this if with --only-test when build
    test

=head3 shipyard after import

After importing, say cpan:Acme::Hello, both the sources and scripts directories
will have a `cpan-Acme-Hello' directory.

Under scripts/cpan-Acme-Hello there are two files: 'build' and 'require.yml'.

=head4 build

configure: %%PERL%% %%MODULE_BUILD_BEFORE_BUILD_PL%% Build.PL --install_base=%%INSTALL_BASE%% --install_path lib=%%INSTALL_BASE%%/lib/perl5 --install_path arch=%%INSTALL_BASE%%/lib/perl5
make: %%PERL%% %%MODULE_BUILD_BEFORE_BUILD%% Build
test: %%PERL%% %%MODULE_BUILD_BEFORE_BUILD%% Build test
install: %%PERL%% %%MODULE_BUILD_BEFORE_BUILD%% Build install
clean: %%PERL%% %%MODULE_BUILD_BEFORE_BUILD%% Build realclean

Each line is of `type: command' format, and the command is executed line by
line (which is also true for t/test).

See L<Shipwright::Manual::CustomizeBuild> for more information on
customizing the build process for dists.

=head4 require.yml

build_requires: {}

conflicts: {}

recommends:
  cpan-Locale-Maketext-Lexicon: 
    version: 0.15
requires: {}

This file details the hints needed in order for Shipwright to create the
right build order.

=head4 vessel

After the cmd `./bin/shipwright-builder --install-base /tmp/vessel`,
we have a new directory structure which we call a I<vessel>(/tmp/vessel).

=head1 SEE ALSO

L<Shipwright::Manual>

=head1 AUTHORS

sunnavy  C<< <sunnavy@bestpractical.com> >>

=head1 LICENCE AND COPYRIGHT

Shipwright is Copyright 2007-2015 Best Practical Solutions, LLC.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.
