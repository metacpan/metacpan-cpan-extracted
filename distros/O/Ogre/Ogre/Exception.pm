package Ogre::Exception;

use strict;
use warnings;


########## GENERATED CONSTANTS BEGIN
require Exporter;
unshift @Ogre::Exception::ISA, 'Exporter';

our %EXPORT_TAGS = (
	'ExceptionCodes' => [qw(
		ERR_CANNOT_WRITE_TO_FILE
		ERR_INVALID_STATE
		ERR_INVALIDPARAMS
		ERR_RENDERINGAPI_ERROR
		ERR_DUPLICATE_ITEM
		ERR_ITEM_NOT_FOUND
		ERR_FILE_NOT_FOUND
		ERR_INTERNAL_ERROR
		ERR_RT_ASSERTION_FAILED
		ERR_NOT_IMPLEMENTED
	)],
);

$EXPORT_TAGS{'all'} = [ map { @{ $EXPORT_TAGS{$_} } } keys %EXPORT_TAGS ];
our @EXPORT_OK = @{ $EXPORT_TAGS{'all'} };
our @EXPORT = ();
########## GENERATED CONSTANTS END
1;

__END__
