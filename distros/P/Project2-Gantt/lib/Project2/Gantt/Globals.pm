package Project2::Gantt::Globals;
use strict;
use warnings;

use Exporter ();
use vars qw[$DAYSIZE $MONTHSIZE @ISA @EXPORT];

our $DATE = '2024-02-05'; # DATE
our $VERSION = '0.011';

@ISA		= qw[Exporter];

$DAYSIZE	= 15;
$MONTHSIZE	= 60;

@EXPORT		= qw[$DAYSIZE $MONTHSIZE];

1;
