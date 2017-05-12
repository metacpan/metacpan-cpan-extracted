use strict;
use warnings;
package Clean;

use ExporterModule qw/stuff/;
use File::Spec::Functions 'catdir';
use namespace::clean;

sub method { }

sub callstuff { stuff(); 'called stuff' }

use constant CAN => [ qw(method callstuff) ];
use constant CANT => [ qw(stuff catdir) ];

1;
