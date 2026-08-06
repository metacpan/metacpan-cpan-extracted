#! perl

use strict;
use warnings;
use Config;

load_extension('Dist::Build::XS');
load_extension('Dist::Build::XS::Conf');

try_find_libraries_for(source => <<EOF, libs => [ [], [ 'rt' ] ], define => 'HAVE_PTHREAD_SIGQUEUE') if $Config{usethreads};
#define _GNU_SOURCE
#define _POSIX_PTHREAD_SEMANTICS
#include <signal.h>
#include <unistd.h>
#include <pthread.h>

int main(int argc, const char** argv) {
	union sigval number;
	number.sival_int = 42;
	pthread_sigqueue(pthread_self(), SIGCHLD, number);
	return 0;
}
EOF

add_xs();
