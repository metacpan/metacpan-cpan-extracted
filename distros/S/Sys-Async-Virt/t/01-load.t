#!perl

use Test2::V0;
use Test::use::ok;

use ok 'Sys::Async::Virt';
use ok 'Sys::Async::Virt::Connection::Local';
use ok 'Sys::Async::Virt::Connection::Process';
use ok 'Sys::Async::Virt::Connection::SSH';
# Add other (indirectly loaded) connection sub-classes here too


done_testing;
