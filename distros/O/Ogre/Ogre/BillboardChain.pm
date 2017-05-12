package Ogre::BillboardChain;

use strict;
use warnings;

use Ogre::MovableObject;
use Ogre::Renderable;
our @ISA = qw(Ogre::MovableObject Ogre::Renderable);


########## GENERATED CONSTANTS BEGIN
require Exporter;
unshift @Ogre::BillboardChain::ISA, 'Exporter';

our %EXPORT_TAGS = (
	'TexCoordDirection' => [qw(
		TCD_U
		TCD_V
	)],
);

$EXPORT_TAGS{'all'} = [ map { @{ $EXPORT_TAGS{$_} } } keys %EXPORT_TAGS ];
our @EXPORT_OK = @{ $EXPORT_TAGS{'all'} };
our @EXPORT = ();
########## GENERATED CONSTANTS END

1;

__END__
=head1 NAME

Ogre::BillboardChain

=head1 SYNOPSIS

  use Ogre;
  use Ogre::BillboardChain;
  # (for now see examples/README.txt)

=head1 DESCRIPTION

See the online API documentation at
 L<http://www.ogre3d.org/docs/api/html/classOgre_1_1BillboardChain.html>

B<Note:> this Perl binding is currently I<experimental> and subject to API changes.

=head1 AUTHOR

Scott Lanning E<lt>slanning@cpan.orgE<gt>

For licensing information, see README.txt .

=cut
