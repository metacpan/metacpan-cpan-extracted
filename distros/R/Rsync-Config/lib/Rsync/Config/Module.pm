package Rsync::Config::Module;

use strict;
use warnings;

our $VERSION = '2.1';

use English qw(-no_match_vars);
use Scalar::Util qw(blessed);
use CLASS;
use Rsync::Config::Atom;
use Rsync::Config::Blank;
use Rsync::Config::Comment;
use base qw(Rsync::Config::Renderer);

use overload
    q{""}    => sub { shift->to_string },
    fallback => 1;

use Exception::Class (
    'Rsync::Config::Module::Exception' => { alias => 'throw' } );
Rsync::Config::Module::Exception->Trace(1);

sub new {
    my ( $class, %opt ) = @_;

    $opt{name} = $class->_valid_name( $opt{name} );
    return $class->SUPER::new( indent_step => 0, %opt, atoms => [] );
}

sub atoms {
    my $self = shift;

    if ( !blessed($self) || !$self->isa($CLASS) ) {
        throw('Invalid call: not an object!');
    }
    return wantarray ? @{ $self->{atoms} } : $self->{atoms};
}

sub atoms_no {
    my $self = shift;

    if ( !blessed($self) || !$self->isa($CLASS) ) {
        throw('Invalid call: not an object!');
    }
    return scalar @{ $self->{atoms} };
}

sub add_atom_obj {
    my ( $self, $atom_obj ) = @_;

    if ( !blessed($self) || !$self->isa($CLASS) ) {
        throw('Invalid call: not an object!');
    }
    if ( !blessed($atom_obj) || !$atom_obj->isa('Rsync::Config::Atom')) {
      throw('Invalid call: not an atom object');
    }
    push @{ $self->{atoms} }, $atom_obj;
    return $self->{atoms}[-1];
}

sub add_atom {
    my ( $self, $name, $value ) = @_;
    if ( !blessed($self) || !$self->isa($CLASS) ) {
        throw('Invalid call: not an object!');
    }
    push @{ $self->{atoms} },
        Rsync::Config::Atom->new(
        name        => $name,
        value       => $value,
        indent      => $self->indent + $self->indent_step,
        indent_char => $self->indent_char,
        );
    return $self->{atoms}[-1];
}

sub add_blank {
    my $self = shift;
    if ( !blessed($self) || !$self->isa($CLASS) ) {
        throw('Invalid call: not an object!');
    }
    push @{ $self->{atoms} }, Rsync::Config::Blank->new;
    return @{ $self->{atoms} }[-1];
}

sub add_comment {
    my ( $self, $value ) = @_;
    if ( !blessed($self) || !$self->isa($CLASS) ) {
        throw('Invalid call: not an object!');
    }
    push @{ $self->{atoms} },
        Rsync::Config::Comment->new(
        value       => $value,
        indent      => $self->indent + $self->indent_step,
        indent_char => $self->indent_char,
        );
    return $self->{atoms}[-1];
}

sub name {
    my $self = shift;
    if ( !blessed($self) || !$self->isa($CLASS) ) {
        throw('Invalid call: not an object!');
    }
    if (@_) {
        $self->{name} = $self->_valid_name(@_);
    }
    return $self->{name};
}

sub indent_step {
    my $self = shift;
    return 1 if !ref $self;
    if (@_) {
        my $step = shift;
        if ( !defined $step || $step !~ /^\d+$/xm ) {
            throw('Invalid indent_step: need a non-negative integer');
        }
        $self->{indent_step} = $step;
        return $self;
    }
    return $self->{indent_step};
}

sub _valid_name {
    my ( $class, $value ) = @_;
    if ( !defined $value || $value !~ /\S/xm ) {
        throw('Invalid name: need a non-empty string!');
    }
    return $value;
}

sub to_string {
    my $self = shift;
    if ( !blessed($self) || !$self->isa($CLASS) ) {
        throw('Invalid call: not an object!');
    }
    return $self->render( $self->name, { prefix => q{[}, suffix => qq{]\n} } )
        . join q{}, map { $_->to_string } $self->atoms;
}

1;

__END__

=head1 NAME

Rsync::Config::Module

=head1 VERSION

2.1

=head1 DESCRIPTION

A module is a module entry from a rsync configuration file. 
Ex:
 [cpan]
   path = /var/ftp/pub/mirrors/ftp.cpan.org/
   comment = CPAN mirror

Rsync::Config::Module is used to create a module who can be later used in generating
a rsync configuration file. Each module is made by atoms (Rsync::Config::Atom).

=head1 SYNOPSIS

 use Rsync::Config::Module;

 sub main {
   my $mod_cpan;

   $mod_cpan = new Rsync::Config::Module(name => 'cpan');

   $mod_cpan->add_atom(name => 'path', value => '/var/ftp/pub/mirrors/ftp.cpan.org/');
   $mod_cpan->add_atom(name => 'comment', value => 'CPAN mirror');
 }

=head1 SUBROUTINES/METHODS

=head2 new(%opt)

The class contructor. %opt must contain at least a key named B<name>
with the name of the module.

=head2 add_blank()

Adds a blank atom to this module. Returns the object.
This method internally calles Rsync::Config::Atom constructor.

=head2 add_comment($comment)

Adds a comment atom to this module. Returns the object.
This method internally calles Rsync::Config::Atom constructor with
$comment parameter. Please read B<Rsync::Config::Atom>
contructor documentation to see if any exceptions are throwned.

=head2 add_atom($name, $value)

Adds a new atom to this module.
This method internally calles Rsync::Config::Atom constructor with
$name and $value parameters. Please read B<Rsync::Config::Atom>
contructor documentation to see if any exceptions are throwned.

=head2 add_atom_obj($atom_obj)

Adds a previsiously created atom object to the list of current atoms. If
$atom_obj is not a instance of Rsync::Config::Atom B<REX::Param::Invalid>
exception is throwned.

=head2 atoms_no()

Returns the number of current atoms.

=head2 atoms()

In scalar context returns a array reference to the list
of current atoms. In array content returns a array of current atoms.

=head2 to_string()

Returns the string representation of the current module. If B<indent>
is true, a best of effort is made to indent the module.

=head2 indent_step

    my $current_indent_step = $module->indent_step;
    $module->indent_step(2);

Both accessor and mutator, I<indent_step> can be used to get the current
indentation level step or to change it.

=head2 name

Both accessor and mutator, I<name> can be used to get the name of the module
or change it.

=head1 DEPENDENCIES

Rsync::Config::Module uses the following modules:

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

None known to the author

=head1 SEE ALSO

L<Rsync::Config::Exceptions> L<Rsync::Config::Atom> L<Rsync::Config>
L<Rsync::Config::Renderer>


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

=cut
