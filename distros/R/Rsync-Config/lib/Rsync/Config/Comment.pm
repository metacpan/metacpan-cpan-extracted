package Rsync::Config::Comment;

use strict;
use warnings;

our $VERSION = '1.0';

use CLASS;
use Scalar::Util qw(blessed);
use base qw(Rsync::Config::Blank);

use Exception::Class (
    'Rsync::Config::Comment::Exception' => { alias => 'throw' } );
Rsync::Config::Comment::Exception->Trace(1);

sub new {
    my ( $class, %opt ) = @_;
    $opt{value} = $class->_valid_value( $opt{value} );
    return $class->SUPER::new(%opt);
}

sub to_string {
    my $self = shift;
    if ( !blessed($self) || !$self->isa($CLASS) ) {
        throw('Invalid call: not an object!');
    }
    my $prefix = $self->value =~ m{^\s* \# .*$}xm ? q{} : q{# };
    return $self->render( $self->value, { prefix => $prefix } );
}

1;

__END__

=head1 NAME

Rsync::Config::Comment - comments as objects

=head1 VERSION

1.0

=head1 DESCRIPTION

Comments as objects.

Inherits from L<Rsync::Config::Blank>.

=head1 SYNOPSIS

 my $com1 = new Rsync::Config::Comment(value => 'this module is private');
 $com1->to_string();

 prints:

 <TAB>#this module is private

=head1 SUBROUTINES/METHODS

=head2 new

This class inherits from B<Rsync::Config::Blank>. Please
read B<Rsync::Config::Blank> documentations for more 
details.

=head2 to_string

returns a stringified version of the comment.

=head1 DEPENDENCIES

L<Exception::Class>, L<CLASS>.

=head1 DIAGNOSTICS

=over 1

=item C<< Invalid call: not an object ! >>

Occurs when method is not called within an object. Self-explanatory.

=back

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
