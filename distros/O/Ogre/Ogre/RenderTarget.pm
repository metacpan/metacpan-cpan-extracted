package Ogre::RenderTarget;

use strict;
use warnings;


########## GENERATED CONSTANTS BEGIN
require Exporter;
unshift @Ogre::RenderTarget::ISA, 'Exporter';

our %EXPORT_TAGS = (
	'StatFlags' => [qw(
		SF_NONE
		SF_FPS
		SF_AVG_FPS
		SF_BEST_FPS
		SF_WORST_FPS
		SF_TRIANGLE_COUNT
		SF_ALL
	)],
);

$EXPORT_TAGS{'all'} = [ map { @{ $EXPORT_TAGS{$_} } } keys %EXPORT_TAGS ];
our @EXPORT_OK = @{ $EXPORT_TAGS{'all'} };
our @EXPORT = ();
########## GENERATED CONSTANTS END

1;

__END__
=head1 NAME

Ogre::RenderTarget

=head1 SYNOPSIS

  use Ogre;
  use Ogre::RenderTarget;
  # (for now see examples/README.txt)

=head1 DESCRIPTION

See the online API documentation at
 L<http://www.ogre3d.org/docs/api/html/classOgre_1_1RenderTarget.html>

B<Note:> this Perl binding is currently I<experimental> and subject to API changes.

=head1 INSTANCE METHODS

=head2 $obj->addViewport($cam, $ZOrder=0, $left=0, $top=0, $width=1, $height=1)

I<Parameter types>

=over

=item $cam : Camera *

=item $ZOrder=0 : int

=item $left=0 : Real

=item $top=0 : Real

=item $width=1 : Real

=item $height=1 : Real

=back

I<Returns>

=over

=item Viewport *

=back

=head2 $obj->getMetrics($OUTLIST unsigned int width, $OUTLIST unsigned int height, $OUTLIST unsigned int colourDepth)

I<Parameter types>

=over

=item $OUTLIST unsigned int width : (no info available)

=item $OUTLIST unsigned int height : (no info available)

=item $OUTLIST unsigned int colourDepth : (no info available)

=back

I<Returns>

=over

=item void

=back

=head2 $obj->resetStatistics()

I<Returns>

=over

=item void

=back

=head2 $obj->getLastFPS()

I<Returns>

=over

=item Real

=back

=head2 $obj->getAverageFPS()

I<Returns>

=over

=item Real

=back

=head2 $obj->getBestFPS()

I<Returns>

=over

=item Real

=back

=head2 $obj->getWorstFPS()

I<Returns>

=over

=item Real

=back

=head2 $obj->getBestFrameTime()

I<Returns>

=over

=item Real

=back

=head2 $obj->getWorstFrameTime()

I<Returns>

=over

=item Real

=back

=head2 $obj->getTriangleCount()

I<Returns>

=over

=item size_t

=back

=head2 $obj->getBatchCount()

I<Returns>

=over

=item size_t

=back

=head2 $obj->update()

I<Returns>

=over

=item void

=back

=head2 $obj->isPrimary()

I<Returns>

=over

=item bool

=back

=head2 $obj->isActive()

I<Returns>

=over

=item bool

=back

=head2 $obj->setActive($state)

I<Parameter types>

=over

=item $state : bool

=back

I<Returns>

=over

=item void

=back

=head2 $obj->isAutoUpdated()

I<Returns>

=over

=item bool

=back

=head2 $obj->setAutoUpdated($autoupdate)

I<Parameter types>

=over

=item $autoupdate : bool

=back

I<Returns>

=over

=item void

=back

=head2 $obj->getName()

I<Returns>

=over

=item String

=back

=head2 $obj->getWidth()

I<Returns>

=over

=item unsigned int

=back

=head2 $obj->getHeight()

I<Returns>

=over

=item unsigned int

=back

=head2 $obj->getColourDepth()

I<Returns>

=over

=item unsigned int

=back

=head2 $obj->getNumViewports()

I<Returns>

=over

=item unsigned short

=back

=head2 $obj->getViewport($index)

I<Parameter types>

=over

=item $index : unsigned short

=back

I<Returns>

=over

=item Viewport *

=back

=head2 $obj->removeViewport($zOrder)

I<Parameter types>

=over

=item $zOrder : int

=back

I<Returns>

=over

=item void

=back

=head2 $obj->removeAllViewports()

I<Returns>

=over

=item void

=back

=head2 $obj->getPriority()

I<Returns>

=over

=item uchar

=back

=head2 $obj->setPriority($priority)

I<Parameter types>

=over

=item $priority : uchar

=back

I<Returns>

=over

=item void

=back

=head2 $obj->writeContentsToFile($filename)

I<Parameter types>

=over

=item $filename : String

=back

I<Returns>

=over

=item void

=back

=head2 $obj->writeContentsToTimestampedFile($filenamePrefix, $filenameSuffix)

I<Parameter types>

=over

=item $filenamePrefix : String

=item $filenameSuffix : String

=back

I<Returns>

=over

=item String

=back

=head2 $obj->requiresTextureFlipping()

I<Returns>

=over

=item bool

=back

=head2 $obj->getCustomAttributePtr($name)

I<Parameter types>

=over

=item $name : String

=back

I<Returns>

=over

=item size_t

=back

=head2 $obj->getCustomAttributeInt($name)

I<Parameter types>

=over

=item $name : String

=back

I<Returns>

=over

=item int

=back

=head2 $obj->getCustomAttributeFloat($name)

I<Parameter types>

=over

=item $name : String

=back

I<Returns>

=over

=item Real

=back

=head2 $obj->getCustomAttributeStr($name)

I<Parameter types>

=over

=item $name : String

=back

I<Returns>

=over

=item String

=back

=head2 $obj->getCustomAttributeBool($name)

I<Parameter types>

=over

=item $name : String

=back

I<Returns>

=over

=item bool

=back

=head1 AUTHOR

Scott Lanning E<lt>slanning@cpan.orgE<gt>

For licensing information, see README.txt .

=cut
