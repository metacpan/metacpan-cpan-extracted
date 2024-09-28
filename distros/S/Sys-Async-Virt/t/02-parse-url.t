#!perl

use v5.20;
use warnings;

use Test2::V0;

use Sys::Async::Virt::Connection;

my $conn = bless {}, 'Sys::Async::Virt::Connection';

is( { $conn->_parse_url( 'qemu:///system' ) },
    { base => 'qemu:///system', hypervisor => 'qemu', type => 'system', query => {} },
    '' );
is( { $conn->_parse_url( 'qemu+unix:///system' ) },
    { base => 'qemu+unix:///system', hypervisor => 'qemu',
      transport => 'unix', type => 'system', query => {} },
    '' );
is( { $conn->_parse_url( 'qemu:///system?mode=legacy' ) },
    { base => 'qemu:///system', hypervisor => 'qemu',
      type => 'system', query => { mode => 'legacy' } },
    '' );
is( { $conn->_parse_url( 'qemu+unix:///system?mode=legacy' ) },
    { base => 'qemu+unix:///system', hypervisor => 'qemu',
      transport => 'unix', type => 'system', query => { mode => 'legacy' } },
    '' );

is( { $conn->_parse_url( 'qemu:///session' ) },
    { base => 'qemu:///session', hypervisor => 'qemu', type => 'session', query => {} },
    '' );
is( { $conn->_parse_url( 'qemu+unix:///session' ) },
    { base => 'qemu+unix:///session', hypervisor => 'qemu',
      transport => 'unix', type => 'session', query => {} },
    '' );
is( { $conn->_parse_url( 'qemu:///session?mode=legacy' ) },
    { base => 'qemu:///session', hypervisor => 'qemu',
      type => 'session', query => { mode => 'legacy' } },
    '' );
is( { $conn->_parse_url( 'qemu+unix:///session?mode=legacy' ) },
    { base => 'qemu+unix:///session', hypervisor => 'qemu',
      transport => 'unix', type => 'session', query => { mode => 'legacy' } },
    '' );

is( { $conn->_parse_url( 'qemu+ext:///system?command=/opt/run-some-command%20my-arg' ) },
    { base => 'qemu+ext:///system', hypervisor => 'qemu',
      transport => 'ext', type => 'system',
      query => { command => '/opt/run-some-command my-arg' } },
    '' );


done_testing;
