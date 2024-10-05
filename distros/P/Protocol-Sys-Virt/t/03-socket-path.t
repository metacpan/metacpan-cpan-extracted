#!perl

use v5.20;
use warnings;

use Test2::V0;

use Protocol::Sys::Virt::UNIXSocket; # imports 'socket_path'

is( socket_path(),
    '/run/libvirt/libvirt-sock',
    '' );
is( socket_path(prefix => '/var'),
    '/var/run/libvirt/libvirt-sock',
    '' );
is( socket_path(readonly => 1),
    '/run/libvirt/libvirt-sock-ro',
    '' );
is( socket_path(readonly => 1),
    '/run/libvirt/libvirt-sock-ro',
    '' );
is( socket_path(hypervisor => 'qemu'),
    '/run/libvirt/libvirt-sock',
    '' );
is( socket_path(driver => 'qemu'),
    '/run/libvirt/libvirt-sock',
    '' );
is( socket_path(hypervisor => 'qemu', driver => 'abc'),
    '/run/libvirt/libvirt-sock',
    '' );
is( socket_path(mode => 'direct', hypervisor => 'qemu'),
    '/run/libvirt/virtqemud-sock',
    '' );
is( socket_path(mode => 'direct', driver => 'qemu'),
    '/run/libvirt/virtqemud-sock',
    '' );
is( socket_path(mode => 'direct', hypervisor => 'qemu', driver => 'abc'),
    '/run/libvirt/virtqemud-sock',
    '' );
is( socket_path(readonly => 1, hypervisor => 'qemu', driver => 'abc'),
    '/run/libvirt/libvirt-sock-ro',
    '' );
is( socket_path(readonly => 1, mode => 'direct', hypervisor => 'qemu'),
    '/run/libvirt/virtqemud-sock-ro',
    '' );
is( socket_path(readonly => 1, mode => 'direct', driver => 'qemu'),
    '/run/libvirt/virtqemud-sock-ro',
    '' );
is( socket_path(readonly => 1, mode => 'direct', hypervisor => 'qemu', driver => 'abc'),
    '/run/libvirt/virtqemud-sock-ro',
    '' );

done_testing;
