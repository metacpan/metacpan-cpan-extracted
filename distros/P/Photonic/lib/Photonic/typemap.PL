our $VERSION = '0.011';

# Copy pdl's typemap to this directory

use strict;
use warnings;
use File::Copy;
use PDL::Core::Dev;
my $file=PDL::Core::Dev::PDL_TYPEMAP;
my $detination="lib/Photonic/typemap"; #where .pd file lives
copy($file, "lib/Photonic/typemap")
    or die "Copy of $file to typemap failed: $!";


