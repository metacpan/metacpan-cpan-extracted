#!/usr/bin/perl

use v5.14;
use warnings;

use Test2::V0;

use POE;
use POE::Future;

eval { require Future::IO;
       Future::IO->VERSION( '0.19' );
       require Future::IO::ImplBase; } or
   plan skip_all => "Future::IO 0.19 is not available";
require Future::IO::Impl::POE;

eval { require Test::Future::IO::Impl;
       Test::Future::IO::Impl->VERSION( '0.17' ); } or
   plan skip_all => "Test::Future::IO::Impl 0.17 is not available";

# Quiet warning
POE::Kernel->run;

Test::Future::IO::Impl::run_tests( qw(
   sleep
   poll_no_hup
   read sysread write syswrite
   connect accept
   send recv
) );

done_testing;
