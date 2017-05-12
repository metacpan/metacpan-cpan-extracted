package Rsync::Config::Atom;

use strict;
use warnings;

our $VERSION = '0.3';

use CLASS;
use Scalar::Util qw(blessed);
use base qw(Rsync::Config::Blank);

use Exception::Class (
    'Rsync::Config::Atom::Exception' => { alias => 'throw' } );
Rsync::Config::Atom::Exception->Trace(1);

sub new {
    my ( $class, %opt ) = @_;
    $opt{name}  = $class->_valid_name( $opt{name} );
    $opt{value} = $class->_valid_value( $opt{value} );
    return $class->SUPER::new(%opt);
}

sub to_string {
    my ($self) = @_;
    if ( !blessed($self) || !$self->isa($CLASS) ) {
        throw('Invalid call: not an object!');
    }
    return $self->render( join q{ = }, @{$self}{qw(name value)} );
}

1;

__END__

=head1 NAME

Rsync::Config::Atom - atom of a rsync configuration file

=head1 VERSION

0.2

=head1 DESCRIPTION

Rsync::Config::Atom is the smallest element of a rsync configuration file.
Every atom has a name and a value. There are 2 types of atoms with special
treatment.

=over 2

=item blank atoms (empty lines)

=item comment atoms

=back

Rsync::Config::Atom inherits from Rsync::Config::Renderer.

=head1 SYNOPSIS

 use Rsync::Config::Atom;

 sub main {
   my $atom = new Rsync::Config::Atom(name => 'path', value => '/var/ftp/pub/mirrors/cpan.org');
 }

=head1 SUBROUTINES/METHODS

Please note that some methods may throw exceptions. Check the documentation
for each method to see what exceptions may be throwned.

=head2 new()

The constructor. The constructor accepts a hash as a argument. The hash must
contain 2 keys:

=over 2

=item *) name

=item *) value

=back

name can be:

=over 3

=item *) B<__blank__> who specifies that the atom is a blank line

=item *) B<__comment__> who specifies that the atom is a comment

=item *) B<a string> with the name of the atom

=back

In all cases name and value must be specified, except for __blank__ atoms. 
new may throw the following exceptions:

=over 3

=item *) REX::Param::Missing - when name or value are not specified

=item *) REX::Param::Undef - when the value of the parameters is not defined

=item *) REX::Param::Invalid - when the value of one of the parameters is blank or 0

=back

Also, options accepted by Rsync::Config::Renderer can be used. Check the documentation
of Rsync::Config::Renderer for a complete list of options.

=head2 is_blank()

returns true (1) if the atom is a blank atom (empty line), 0 otherwise

=head2 is_comment()

returns true (1) if the atom is a comment, 0 otherwise

=head2 name($new_name)

changes the name of the atom if $new_name is defined. Always returns the name of the atom.
If this method is called outside class instance a REX::OutsideClass exception is throwned.

=head2 value($new_value)

changes the value of the atom if $new_value is defined. Else, returns the value of the atom.
If this method is called outside class instance a REX::OutsideClass exception is throwned.

=head2 to_string()

returns a string representation of the atom.
If this method is called outside class instance a REX::OutsideClass exception is throwned.

=head1 DEPENDENCIES

Rsync::Config::Atom depends on the following modules:

=over 3

=item English

=item Scalar::Util

=item CLASS

=back

=head1 DIAGNOSTICS

All tests are located in the t directory .

=head1 PERL CRITIC

This module is perl critic level 1 compliant.

=head1 CONFIGURATION AND ENVIRONMENT

This module does not use any configuration files or environment
variables. The used modules however may use such things. Please
refer to each module man page for more information.

=head1 INCOMPATIBILITIES

None known to the author

=head1 BUGS AND LIMITATIONS

Using atoms with values 0 or undef will trigger exceptions.

=head1 SEE ALSO

L<Rsync::Config::Exceptions> L<Rsync::Config::Module> L<Rsync::Config>
L<Rsync::Config::Renderer>

=head1 AUTHOR

Subredu Manuel <diablo@packages.ro>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2006 Subredu Manuel.  All Rights Reserved.
This module is free software; you can redistribute it 
and/or modify it under the same terms as Perl itself.
The LICENSE file contains the full text of the license.

=cut
