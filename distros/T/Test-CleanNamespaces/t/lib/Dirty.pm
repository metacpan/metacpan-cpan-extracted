use strict;
use warnings;
package Dirty;

use ExporterModule qw/stuff/;

sub method { }

sub callstuff { stuff(); 'called stuff' }

use constant CAN => [ qw(stuff method callstuff) ];
use constant CANT => [ ];
use constant DIRTY => [ qw(stuff) ];

1;
