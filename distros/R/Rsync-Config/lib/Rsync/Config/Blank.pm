package Rsync::Config::Blank;

use strict;
use warnings;

our $VERSION = '1.1';

use CLASS;
use Scalar::Util qw(blessed);
use base qw(Rsync::Config::Renderer);
use overload
    q{""}    => sub { shift->to_string },
    fallback => 1;

use Exception::Class (
    'Rsync::Config::BasicAtom::Exception' => { alias => 'throw' } );
Rsync::Config::BasicAtom::Exception->Trace(1);

sub new {
    my $class = shift;
    return $class->SUPER::new(@_);
}

sub to_string {
    return qq{\n};
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

sub value {
    my $self = shift;
    if ( !blessed($self) || !$self->isa($CLASS) ) {
        throw('Invalid call: not an object!');
    }
    if (@_) {
        $self->{value} = $self->_valid_value(@_);
    }
    return $self->{value};
}

sub _valid_name {
    my ( $class, $value ) = @_;
    if ( !defined $value || $value !~ /\S/xm ) {
        throw('Invalid name: need a non-empty string!');
    }
    return $value;
}

sub _valid_value {
    my ( $class, $value ) = @_;
    if ( !defined $value || $value !~ m{^ .* \S+ .* $}xm ) {
        throw('Invalid value: need a non-empty string!');
    }
    return $value;
}

1;

__END__

=head1 NAME

Rsync::Config::Blank - basic atom object

=head1 VERSION

1.1

=head1 DESCRIPTION

FIXME

Inherits from L<Rsync::Config::Renderer>.

=head1 SYNOPSIS

FIXME

=head1 SUBROUTINES/METHODS

=head2 new

FIXME: constructor

=head2 to_string

returns a stringified version of the comment.

=head2 name

Unused here. Useful for derivated classes, as "name" accessor/mutator.

=head2 value

Unused here. Useful for derivated classes, as "value" accessor/mutator.

=head1 DEPENDENCIES

L<Exception::Class>, L<CLASS>.

=head1 DIAGNOSTICS

FIXME

=head1 CONFIGURATION AND ENVIRONMENT

This module does not use any configuration files or environment variables.

=head1 INCOMPATIBILITIES

None known to the author.

=head1 BUGS AND LIMITATIONS

No bugs known to the author.

=head1 SEE ALSO

L<Rsync::Config>.

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
