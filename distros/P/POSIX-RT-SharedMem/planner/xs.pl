#! perl

use strict;
use warnings;

load_extension('Dist::Build::XS');
load_extension('Dist::Build::XS::Conf');

find_libraries_for(source => <<'EOF', libs => [ [], ['rt'] ], quiet => 1);
#include <sys/mman.h>
#include <sys/stat.h>
#include <fcntl.h>

int main(int argc, const char** argv) {
	shm_open("test", O_RDONLY, 0600);
	return 0;
}
EOF

add_xs();
