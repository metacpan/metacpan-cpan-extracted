#! perl

use strict;
use warnings;

load_extension('Dist::Build::XS');
load_extension('Dist::Build::XS::Conf');

find_libraries_for(source => <<EOF, libs => [ [], [ 'rt' ] ]);
#include <stdlib.h>
#include <signal.h>
#include <time.h>

int main(int argc, const char** argv) {
	struct sigevent sev;
	sev.sigev_notify = SIGEV_NONE;
	timer_t timer;
	timer_create(CLOCK_REALTIME, &sev, &timer);
	return 0;
}

EOF

add_xs();
