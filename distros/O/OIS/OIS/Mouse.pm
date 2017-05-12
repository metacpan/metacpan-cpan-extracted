package OIS::Mouse;

use strict;
use warnings;

require Exporter;
use OIS::Object;
our @ISA = qw(OIS::Object Exporter);

our %EXPORT_TAGS = (
    'MouseButtonID' => [
        qw(
           MB_Left
           MB_Right
           MB_Middle
           MB_Button3
           MB_Button4
           MB_Button5
           MB_Button6
           MB_Button7
       ),
    ],
);

$EXPORT_TAGS{'all'} = [ map { @{ $EXPORT_TAGS{$_} } } keys %EXPORT_TAGS ];

our @EXPORT_OK = @{ $EXPORT_TAGS{'all'} };
our @EXPORT = ();


1;
