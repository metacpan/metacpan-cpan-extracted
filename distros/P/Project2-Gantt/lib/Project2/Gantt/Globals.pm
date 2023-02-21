package Project2::Gantt::Globals;
use strict;
use warnings;

use Exporter ();
use vars qw[$DAYSIZE $MONTHSIZE @ISA @EXPORT];

our $DATE = '2023-02-16'; # DATE
our $VERSION = '0.009';

@ISA		= qw[Exporter];

$DAYSIZE	= 15;
$MONTHSIZE	= 60;

@EXPORT		= qw[$DAYSIZE $MONTHSIZE];

1;
