use Test::More;

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/lib";
BEGIN { $ENV{SPVM_BUILD_DIR} = "$FindBin::Bin/.spvm_build"; }

use SPVM 'TestCase::Sys::Time::Util';

ok(SPVM::TestCase::Sys::Time::Util->nanoseconds_to_timespec);
  
ok(SPVM::TestCase::Sys::Time::Util->timespec_to_nanoseconds);
  
ok(SPVM::TestCase::Sys::Time::Util->microseconds_to_timeval);
  
ok(SPVM::TestCase::Sys::Time::Util->timeval_to_microseconds);
  
ok(SPVM::TestCase::Sys::Time::Util->float_seconds_to_timespec);
  
ok(SPVM::TestCase::Sys::Time::Util->timespec_to_float_seconds);
  
ok(SPVM::TestCase::Sys::Time::Util->float_seconds_to_timeval);
  
ok(SPVM::TestCase::Sys::Time::Util->timeval_to_float_seconds);
  
ok(SPVM::TestCase::Sys::Time::Util->float_seconds_to_nanoseconds);
  
ok(SPVM::TestCase::Sys::Time::Util->nanoseconds_to_float_seconds);
  
ok(SPVM::TestCase::Sys::Time::Util->float_seconds_to_microseconds);
  
ok(SPVM::TestCase::Sys::Time::Util->microseconds_to_float_seconds);
    
ok(SPVM::TestCase::Sys::Time::Util->timeval_interval);
  
ok(SPVM::TestCase::Sys::Time::Util->timespec_interval);

ok(SPVM::TestCase::Sys::Time::Util->add_timespec);

ok(SPVM::TestCase::Sys::Time::Util->add_timeval);

ok(SPVM::TestCase::Sys::Time::Util->subtract_timespec);

ok(SPVM::TestCase::Sys::Time::Util->subtract_timeval);

done_testing;
