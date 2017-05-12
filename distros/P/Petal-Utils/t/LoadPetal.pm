# Common code for loading Petal with default dir

# load things into the caller's package

use Petal;
use File::Spec;

my $base_dir = File::Spec->catdir(qw( t data ));

# Petal's global settings
$Petal::DISK_CACHE   = 0;
$Petal::MEMORY_CACHE = 0;
$Petal::TAINT        = 1;
$Petal::BASE_DIR     = $base_dir;
$Petal::INPUT        = "XHTML";
$Petal::OUTPUT       = "XHTML";

1;
