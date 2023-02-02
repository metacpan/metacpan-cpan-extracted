package Project2::Gantt::Globals;
use strict;
use warnings;

use Exporter ();
use vars qw[$DAYSIZE $MONTHSIZE @ISA @EXPORT];

our $DATE = '2023-02-02'; # DATE
our $VERSION = '0.006';

@ISA		= qw[Exporter];

$DAYSIZE	= 15;
$MONTHSIZE	= 60;

@EXPORT		= qw[$DAYSIZE $MONTHSIZE];

1;
