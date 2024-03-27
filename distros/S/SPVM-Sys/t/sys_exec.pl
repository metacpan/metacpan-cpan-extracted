use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/lib";
BEGIN { $ENV{SPVM_BUILD_DIR} = "$FindBin::Bin/.spvm_build"; }

use SPVM 'TestCase::Sys::Process';

my $program_file = "$FindBin::Bin/print_hello.pl";

SPVM::TestCase::Sys::Process->exec_sys($^X, $program_file);
