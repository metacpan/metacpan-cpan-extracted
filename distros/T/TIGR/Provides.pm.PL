use 5.006;
use strict;
use warnings;
use File::Path 'make_path';
use File::Basename 'dirname';
use autodie;

my $destination = shift;
make_path( dirname( $destination ) );
open my $fh, ">", $destination;
print {$fh} <DATA>;

__DATA__
package TIGR;
use 5.006;
use strict;
use warnings;
our $VERSION = '0.02';
1;
