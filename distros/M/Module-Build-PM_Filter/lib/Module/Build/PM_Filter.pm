package Module::Build::PM_Filter;
use base qw(Module::Build);
use strict;
use warnings;
use Carp;
use utf8;
use English qw(-no_match_vars);
use File::Temp;
use File::Path;
use File::Basename qw(dirname);

use version; our $VERSION = qv(1.21);

sub process_pm_files {
    my  $self   =   shift;
    my  $ext    =   shift;

    ### is there a pm_filter file ? ...
    if (not $self->_check_pm_filter_file( q(pm_filter) )) {
        ### dispatch to super method ...
        return $self->SUPER::process_pm_files( $ext );
    }

    ### build the install directory
    my $target_dir = $self->blib;
    if (not -e $target_dir) {
        File::Path::mkpath( $target_dir );
    }

    ### build the method name for finding files according to the extension
    my $method = "find_${ext}_files";

    ### build a hash with module names and targets. 
    my $files = $self->can($method) ? $self->$method() :
                $self->_find_file_by_type($ext,  'lib');

    ### only filter and install the module if it's not updated
    while (my ($file, $dest) = each %{ $files }) {
        my $derived = File::Spec->catfile($target_dir, $dest);

        if (not $self->up_to_date( $file, $derived )) {

            ### filter to a temporary file
            my $temp_source = File::Temp->new();
            $self->_do_filter( $file, $temp_source );

            ### and install into the distribution directory
            $self->copy_if_modified( from => $temp_source, to => $derived );
        }
    }

    return;
}

sub process_script_files {
    my  $self   =   shift;

    ### is there a pm_filter file ? ...
    if (not $self->_check_pm_filter_file( q(pm_filter) )) {
        ### dispatch to super method ...
        return $self->SUPER::process_script_files( );
    }

    # find script files 
    my  $files  =   $self->find_script_files;

    # do nothing if not files
    return if not keys %{ $files };

    # make the install directory
    my $script_dir = File::Spec->catdir($self->blib, 'script');
    if (not -e $script_dir) {
        File::Path::mkpath( $script_dir );
    }

    # filter every script and make executable
    foreach my $file (keys %{ $files }) {
        # Isn't it already fresh ?
        if (not $self->up_to_date( $file, $script_dir)) {
            my $tmp_from = File::Temp->new();

            # use a temporary file for filter ...
            $self->_do_filter( $file, $tmp_from );
            $self->fix_shebang_line( $tmp_from );
            $self->make_executable( $tmp_from );

            # ... previous to the canonical installation
            $self->copy_if_modified( from => $tmp_from, to_dir => $script_dir );
        }
    }

    return;
}

sub _do_filter {
    my  $self       =   shift;
    my  $source     =   shift;
    my  $target     =   shift;
    my  $cmd        =   sprintf './pm_filter < %s > %s', $source, $target;

    if (not $self->do_system($cmd)) {
        croak "pm_filter failed: ${ERRNO}";
    }

    return;
}

### INTERNAL UTILITY ###
# Usage         : _check_pm_filter_file( $pm_filter_path )
# Purpose       : Check if there is a valid pm_filter 
# Returns       : 0 Not valid 
#               : 1 Valid 
# Parameters    : - File path 
# Throws        : no exceptions
# Commments     : none
# See also      : n/a

sub _check_pm_filter_file {
    my  $self       =   shift;
    my  $file       =   shift;

    if (-e $file) {
        if (not -x $file) {
            croak q(pm_filter exists but is not executable);
        }
    }

    return 1;
}

### CLASS METHOD ###
# Usage         : internal use only 
# Purpose       : Verify that a pm_filter exists and it's executable in the
#               : distribution directory.
# Returns       : Some of the inherited method
# Parameters    : 
# Throws        : no exceptions
# Commments     : none
# See also      : n/a

sub ACTION_distdir {
    my  ($self, @params)  =   @_;

    # dispatch to up
    $self->SUPER::ACTION_distdir(@params);

    # build the distribution path 
    my $dir     = $self->dist_dir();

    # verify that the next files are executables ...
    $self->_make_exec( "${dir}/pm_filter"       );
    $self->_make_exec( "${dir}/debian/rules"    );

    return;
}

sub _make_exec {
    my  $self   =   shift;
    my  $file   =   shift;

    # if the file exists and is not executable ...
    if (-e $file and not -x $file) {
        $self->make_executable( $file );
    }

    return;
}

1;
__END__

=head1 NAME

Module::Build::PM_Filter - Add a PM_Filter feature to Module::Build

=head1 VERSION

This documentation refers to Module::Build::PM_Filter version 1.2

=head1 SYNOPSIS

In a Build.PL file you must use this module in place of the L<Module::Build>:

    use Module::Build::PM_Filter;

    my $build = Module::Build::PM_Filter->new(
                module_name         =>  'MyIkiWiki::Tools',
                license             =>  q(gpl),
                dist_version        =>  '0.2',
                dist_author         =>  'Victor Moral <victor@taquiones.net>',
                );

    $build->create_build_script();

In the package directory create a pm_filter file like this:

    #!/usr/bin/perl -pl

    s{##PACKAGE_LIB##}{use lib qw(/usr/share/myprogram);}g;

and change its permissions for user execution.    

Then in a script from package insert a line like this:

    package MyPackage;
    use strict;
    use base;

    ...

    ##PACKAGE_LIB##

    ...

=head1 DESCRIPTION

This module provides a Module::Build compatible class and adds a filter for
F<.pm>, F<.pl> and script files. The filter could be used to replace Perl
source from development environment to production, or to remove debug
sentences.

In the debug phase we can play with the application and modules without
mattering to us where the library are; when we build the package for
distribution, the modules and the scripts will contain the correct path in the
final location.

In addition the module makes sure that the archives F<pm_filter> and
F<debian/rules> are copied in the distribution directory with the suitable
permissions.

=head1 SUBROUTINES/METHODS

=head2 process_pm_files( )

This method looks for a file named 'pm_filter' in the current work directory
and executes it; his standard input is redirected to the source pm and his
standard output is redirected to a temp file. 

The temp file is finally installed on the F<blib/> tree.

=head2 process_script_files( )

This method finds, filters and install the executable files in the package.

=head2 ACTION_distdir( )

This method performs the 'distdir' action and change the permissions of the
pm_filter and debian/rules files in the distribution to executable.

=head1 DIAGNOSTICS

=over

=item pm_filter failed ...

croak with this text when it could not run the pm_filter program.

=item pm_filter not executable ...

croak with this text when exists a pm_filter file and it not executable.

=back

=head1 CONFIGURATION AND ENVIRONMENT 

The location of the pm_filter script must be the current work directory.

=head1 DEPENDENCIES

=over 

=item Module::Build

=item File::Copy::Recursive

=back

=head1 INCOMPATIBILITIES

=over

=item L<ExtUtils::MakeMaker>

=back 

=head1 BUGS AND LIMITATIONS

There are no known bugs in this module.
Please report problems to the author.
Patches are welcome.

=head1 AUTHOR

Victor Moral <victor@taquiones.net>

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2008 "Victor Moral" <victor@taquiones.net>

This library is free software; you can redistribute it and/or
modify it under the terms of the GNU Lesser General Public
License as published by the Free Software Foundation; either
version 2.1 of the License.


This library is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
Lesser General Public License for more details.


You should have received a copy of the GNU Lesser General Public
License along with this library; if not, write to the Free Software
Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301 US

