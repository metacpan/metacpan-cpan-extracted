package Ogre::RenderOperation;

use strict;
use warnings;


########## GENERATED CONSTANTS BEGIN
require Exporter;
unshift @Ogre::RenderOperation::ISA, 'Exporter';

our %EXPORT_TAGS = (
	'OperationType' => [qw(
		OT_POINT_LIST
		OT_LINE_LIST
		OT_LINE_STRIP
		OT_TRIANGLE_LIST
		OT_TRIANGLE_STRIP
		OT_TRIANGLE_FAN
	)],
);

$EXPORT_TAGS{'all'} = [ map { @{ $EXPORT_TAGS{$_} } } keys %EXPORT_TAGS ];
our @EXPORT_OK = @{ $EXPORT_TAGS{'all'} };
our @EXPORT = ();
########## GENERATED CONSTANTS END
1;

__END__
