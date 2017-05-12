package OIS::Exception;

use strict;
use warnings;

require Exporter;
our @ISA = qw(Exporter);

our %EXPORT_TAGS = (
    'OIS_ERROR' => [
        qw(
	   E_InputDisconnected
           E_InputDeviceNonExistant
           E_InputDeviceNotSupported
           E_DeviceFull
           E_NotSupported
           E_NotImplemented
           E_Duplicate
           E_InvalidParam
           E_General
       )
    ],
);

$EXPORT_TAGS{'all'} = [ map { @{ $EXPORT_TAGS{$_} } } keys %EXPORT_TAGS ];

our @EXPORT_OK = @{ $EXPORT_TAGS{'all'} };
our @EXPORT = ();


1;
