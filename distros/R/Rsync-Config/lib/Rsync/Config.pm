# $Id$
package Rsync::Config;

use strict;
use warnings;

our $VERSION = '0.3.1';

use Scalar::Util qw(blessed);
use English qw(-no_match_vars);
use CLASS;
use base qw(Rsync::Config::Module);

use Exception::Class ( 'Rsync::Config::Exception' => { alias => 'throw' } );
Rsync::Config::Exception->Trace(1);

sub new {
    my ( $class, %opt ) = @_;
    $opt{name} = '_main_';
    return $class->SUPER::new(
        %opt,
        modules     => [],
        name        => '_main_',
        indent_step => 0,
    );
}

sub modules {
    my $self = shift;
    if ( !blessed($self) || !$self->isa($CLASS) ) {
        throw('Invalid call: not an object!');
    }
    return wantarray ? @{ $self->{modules} } : $self->{modules};
}

sub modules_no {
    my $self = shift;
    if ( !blessed($self) || !$self->isa($CLASS) ) {
        throw('Invalid call: not an object!');
    }
    return scalar @{ $self->{modules} };
}

sub add_module_obj {
    my ( $self, $module_obj ) = @_;

    if ( !blessed($self) || !$self->isa($CLASS) ) {
        throw('Invalid call: not an object!');
    }
    if ( !blessed($module_obj) || !$module_obj->isa('Rsync::Config::Module') ) {
        throw('Invalid call: not an module object');
    }
    if ( $self->module_exists($module_obj->name) ) {
        throw('Already have a module named "' . $module_obj->name . q{"});
    }
    push @{ $self->{modules} }, $module_obj;
    return $self->{modules}[-1];
}

sub add_module {
    my ( $self, $name ) = @_;
    if ( !blessed($self) || !$self->isa($CLASS) ) {
        throw('Invalid call: not an object!');
    }
    if ( $self->module_exists($name) ) {
        throw("Already have a module named '$name'");
    }
    push @{ $self->{modules} },
        Rsync::Config::Module->new(
        name        => $name,
        indent      => $self->indent + 1,
        indent_step => 1,
        indent_char => $self->indent_char,
        );
    return $self->{modules}[-1];
}

sub module_exists {
    my ( $self, $name ) = @_;
    if ( !blessed($self) || !$self->isa($CLASS) ) {
        throw('Invalid call: not an object!');
    }
    return if !defined $name;
    for my $mod ( $self->modules ) {
        return $mod if $mod->name eq $name;
    }
    return;
}

sub to_string {
    my $self = shift;
    if ( !blessed($self) || !$self->isa($CLASS) ) {
        throw('Invalid call: not an object!');
    }
    return join q{}, map( { $_->to_string } $self->atoms ),
        map { $_->to_string } $self->modules;
}

sub to_file {
    my ( $self, $filename ) = @_;
    if ( !blessed($self) || !$self->isa($CLASS) ) {
        throw('Invalid call: not an object!');
    }
    if ( !$filename ) {
        throw('Missing filename!');
    }
    open my $fh, '>', $filename
        or throw("Cannot open '$filename': $OS_ERROR");
    print {$fh} $self->to_string;
    close $fh;
    return 1;
}

1;

__END__

=head1 NAME

Rsync::Config - rsync configuration generator

=head1 VERSION

0.3.1

=head1 DESCRIPTION

Rsync::Config is a module who can be used to create rsync configuration files.
A configuration file (from Rsync::Config point of view) is made by atoms and
modules with atoms. A atom is the smallest piece from the configuration file.
This module inherits from B<Rsync::Config::Module> .

=head1 INHERITANCE

Objects from Rsync::Config inherits as in the next scheme

                         /--- Rsync::Config::Module --- Rsync::Config
 Rsync::Config::Renderer 
                         \--- Rsync::Config::Blank
                               /  \
        Rsync::Config::Atom ---    --- Rsync::Config::Comment

=head1 SYNOPSIS

 use Rsync::Config;
 use Rsync::Config::Atom;
 use Rsync::Config::Module;

 sub main {
   my ($conf, $module);

   $conf = new Rsync::Config();
   $conf->add_comment('Main configuration file for our rsync daemon');
   $conf->add_atom('read only','yes');
   $conf->add_atom('chroot','yes');

   $module = new Rsync::Config::Module(name => 'cpan');
   $module->add_atom('path','/var/ftp/pub/mirrors/ftp.cpan.org/');
   $module->add_atom('comment', 'CPAN mirror');

   $conf->add_module($module);
   $conf->to_file('/etc/rsyncd.conf');
 }

=head1 SUBROUTINES/METHODS

=head2 new(%opt)

The class contructor.

=head2 add_module_obj($module)

Adds the $module (a instance of Rsync::Config::Module) to the internal list
of modules. Returns the $module object.

=head2 add_module($module_name)

Add a new module name $module_name to the internal list of modules. Returns
the newly created object.

=head2 modules()

In scalar context, the number of existing modules is returned. In list context
a array with all modules is returned.

=head2 modules_no()

Returns the current number of modules.

=head2 module_exists($module_name)

Search trough the list of modules and check if a module with name $module_name exists.
Returns the corresponding object or undef (if a module with the specified name does not
exists)

=head2 to_string()

Returns the string representation for this configuration file.

=head2 to_file($filename)

Writes the configuration into the file specified by $filename. 

If the file already exists, the content of that file will be lost.

=head1 DEPENDENCIES

L<Scalar::Util>, L<English>, L<Exception::Class>, L<CLASS>.

=head1 DIAGNOSTICS

=over 5

=item C<< Invalid call: not an object ! >>

Self-explanatory

=item C<< Invalid call: not an module object ! >>

Occurs when the parameter is not a instance of Rsync::Config::Module

=item C<< Already have a module named ... >>

Occurs when one is trying to add a module with a name that already exists

=item C<< Missing filename! >>

Occurs when filename was not specified. 

=item C<< Cannot open ... >>

Occurs when the file could not be created 

=back

=head1 CONFIGURATION AND ENVIRONMENT

This module does not use any configuration files or environment variables.

=head1 INCOMPATIBILITIES

None known to the author

=head1 BUGS AND LIMITATIONS

None known to the author

=head1 SEE ALSO

L<Rsync::Config::Module>,
L<Rsync::Config::Atom>,
L<Rsync::Config::Blank>,
L<Rsync::Config::Comment>,
L<Rsync::Config::Renderer>.

=head1 AUTHOR

Manuel SUBREDU C<< <diablo@packages.ro> >>.

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2006, Manuel SUBREDU C<< <diablo@packages.ro> >>.
All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.
See L<perlartistic>.

=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.
