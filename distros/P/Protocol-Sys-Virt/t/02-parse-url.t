#!perl

use v5.20;
use warnings;

use Test2::V0;

use Protocol::Sys::Virt::URI; # imports 'parse_url'

my $conn = bless {}, 'Sys::Async::Virt::Connection';

is( { parse_url( 'qemu:///system' ) },
    { base => 'qemu:///system', proxy => 'qemu:///system', name => 'qemu:///system',
      hypervisor => 'qemu', type => 'system', query => {} },
    '' );
is( { parse_url( 'qemu+unix:///system' ) },
    { base => 'qemu+unix:///system', proxy => 'qemu:///system', name => 'qemu:///system',
      hypervisor => 'qemu', transport => 'unix', type => 'system', query => {} },
    '' );
is( { parse_url( 'qemu:///system?mode=legacy' ) },
    { base => 'qemu:///system', proxy => 'qemu:///system?mode=legacy', name => 'qemu:///system',
      hypervisor => 'qemu', type => 'system', query => { mode => 'legacy' } },
    '' );
is( { parse_url( 'qemu+unix:///system?mode=legacy' ) },
    { base => 'qemu+unix:///system', proxy => 'qemu:///system?mode=legacy', name => 'qemu:///system',
      hypervisor => 'qemu', transport => 'unix', type => 'system', query => { mode => 'legacy' } },
    '' );
is( { parse_url( 'qemu+tcp://libvirt-host/system?mode=legacy' ) },
    { base => 'qemu+tcp://libvirt-host/system', proxy => 'qemu:///system?mode=legacy', name => 'qemu:///system',
      hypervisor => 'qemu', transport => 'tcp', host => 'libvirt-host', type => 'system', query => { mode => 'legacy' } },
    '' );

is( { parse_url( 'qemu:///session' ) },
    { base => 'qemu:///session', proxy => 'qemu:///session', name => 'qemu:///session',
      hypervisor => 'qemu', type => 'session', query => {} },
    '' );
is( { parse_url( 'qemu+unix:///session' ) },
    { base => 'qemu+unix:///session', proxy => 'qemu:///session', name => 'qemu:///session',
      hypervisor => 'qemu', transport => 'unix', type => 'session', query => {} },
    '' );
is( { parse_url( 'qemu:///session?mode=legacy' ) },
    { base => 'qemu:///session', proxy => 'qemu:///session?mode=legacy', name => 'qemu:///session',
      hypervisor => 'qemu', type => 'session', query => { mode => 'legacy' } },
    '' );
is( { parse_url( 'qemu+unix:///session?mode=legacy' ) },
    { base => 'qemu+unix:///session', proxy => 'qemu:///session?mode=legacy', name => 'qemu:///session',
      hypervisor => 'qemu', transport => 'unix', type => 'session', query => { mode => 'legacy' } },
    '' );
is( { parse_url( 'qemu+tcp://libvirt-host/session?mode=legacy' ) },
    { base => 'qemu+tcp://libvirt-host/session', proxy => 'qemu:///session?mode=legacy', name => 'qemu:///session',
      hypervisor => 'qemu', transport => 'tcp', host => 'libvirt-host', type => 'session', query => { mode => 'legacy' } },
    '' );
is( { parse_url( 'qemu+tcp://libvirt-host:12345/session?mode=legacy' ) },
    { base => 'qemu+tcp://libvirt-host:12345/session', proxy => 'qemu:///session?mode=legacy', name => 'qemu:///session',
      hypervisor => 'qemu', transport => 'tcp', host => 'libvirt-host', port => '12345', type => 'session',
      query => { mode => 'legacy' } },
    '' );

is( { parse_url( 'qemu+ext:///system?command=/opt/run-some-command%20my-arg' ) },
    { base => 'qemu+ext:///system', proxy => 'qemu:///system',  name => 'qemu:///system',
      hypervisor => 'qemu', transport => 'ext', type => 'system',
      query => { command => '/opt/run-some-command my-arg' } },
    '' );


done_testing;
