package Module::Build::IkiWiki;
use base qw(Module::Build);
use warnings;
use strict;
use Carp;

use File::Basename;
use File::Spec;

our $VERSION    =   '0.0.3';

# flag for fake installations
my  $_fake_install  =   0;

# Module implementation here
sub new {
    my  ($class,@params)    = @_;
    my  $self               = $class->SUPER::new( @params );
    my  $prop               = $self->_get_prop();
    
    my  %ikiwiki_paths  =   (
            'templates' =>  q(/usr/share/ikiwiki/templates),
            'css'       =>  q(/usr/share/ikiwiki/basewiki),
    );

    # checking default values 
    if (not defined ($prop->{ ikiwiki_paths } )) {
        $prop->{ ikiwiki_paths } = \%ikiwiki_paths;
    }
    foreach my $other qw(ikiwiki_templates ikiwiki_css) {
        if (not exists $prop->{ $other }) {
            $prop->{ $other } = [];
        }
    }

    return $self;
}

sub ACTION_install {
    my  ($self,@params)     =   @_;
    my  $prop               =   $self->_get_prop();

    if (not $_fake_install) {
        $self->SUPER::ACTION_install( @params );
    }

    # process the new file types 
    foreach my $category qw(templates css) {
        # get the final list
        my @source_files = @{ $prop->{ "ikiwiki_${category}" } };
        my $dest_dir    =   $self->destdir() || '';

        if (@source_files) {
            # get the target directory 
            my $target_dir = File::Spec->catdir( 
                                    $dest_dir,
                                    $prop->{ikiwiki_paths}->{$category}
                                );

            # install the source files 
            foreach my $source (@source_files) {
                my $to_file = File::Spec->catdir($target_dir, 
                                    scalar fileparse( $source ) );

                if ($_fake_install) {
                    print "Installing ${to_file}\n";
                }
                else {
                    $self->copy_if_modified( from => $source,
                                            to   => $to_file );
                }                                        
            }
        }
    }            

    return;
}

sub ACTION_fakeinstall {
    my  ($self,@params)     =   @_;
    
    # first dispatch to up 
    $self->SUPER::ACTION_fakeinstall( @params );

    # and now show our files
    $_fake_install = 1;
    $self->ACTION_install( @params );
    $_fake_install = 0;

    return;
}

sub _get_prop {
    my  $self   =   shift;

    return $self->{ properties };   ##Violates 'ProhibitAccessOfPrivateData'
}

1; # Magic true value required at end of module
__END__

=head1 NAME

Module::Build::IkiWiki - Extension for develop Ikiwiki plugins 

=head1 VERSION

This document describes Module::Build::IkiWiki version 0.0.2

=head1 SYNOPSIS

    #!/usr/bin/perl 

    use Module::Build::IkiWiki;

    my $build = Module::Build::IkiWiki->new(
                    module_name     =>  'xxxx',
                    license         =>  'gpl',
                    ...
                    ikiwiki_paths       =>  {
                        'templates' =>  q(/usr/share/ikiwiki/templates),
                        'css'       =>  q(/usr/share/ikiwiki/basewiki),
                        },
                    ikiwiki_templates   =>  [ glob('extras/*.tmpl') ],
                    ikiwiki_stylesheets =>  [ glob('extras/*.css') ],
                );

    $build->create_build_script();
                       
=head1 DESCRIPTION

The goal of this module is build and install IkiWiki plugins in Perl,
subclassing the Module::Build and adding some extra funcionalites to it.

For a description of the interface see L<Module::Build::API>.

This is a list of a new parameters in the Module::Build::new method:

=over

=item ikiwiki_paths

Define the install paths of the components using a hash with the following
keys:

=over

=item templates

The default value is F</usr/share/ikiwiki/templates>.

=item css

The default value is F</usr/share/ikiwiki/basewiki>.

=back

=item ikiwiki_templates

List of templates for install.

=item ikiwiki_stylesheets

List of css stylesheets files to install.

=back

=head1 SUBROUTINES/METHODS

=head2 new( )

Override the new method in the base class and check the special parameters for
ikiwiki.

=head2 ACTION_install( )

Install the template and css files of the package.

=head2 ACTION_fakeinstall( )

Show the install actions to the standard output.

=head1 DIAGNOSTICS

The error messages are from the base class. This package don't generate any exceptions.

=head1 CONFIGURATION AND ENVIRONMENT

Module::Build::IkiWiki requires no configuration files or environment variables.

=head1 DEPENDENCIES

=over

=item L<Module::Build>

=back

=head1 INCOMPATIBILITIES

None reported.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-module-build-ikiwiki@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.

=head1 AUTHOR

Víctor Moral <victor@taquiones.net>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2008 <Victor Moral>

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License or
any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License along
with this program; if not, write to the Free Software Foundation, Inc.,
51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.

