use strict;
use warnings;
package SubClean;

use SubExporterModule qw/stuff/;
use File::Spec::Functions 'catdir';
use namespace::clean;   # clean 'stuff' at end of compilation

sub method { }

sub callstuff { stuff(); 'called stuff' }

use constant CAN => [ qw(method callstuff) ];
use constant CANT => [ qw(stuff catdir) ];

1;
