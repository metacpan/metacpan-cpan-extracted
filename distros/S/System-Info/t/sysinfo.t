#!/usr/bin/perl

use strict;
use warnings;

$|++;

use Test::More tests => 69;
use Test::NoWarnings;
my $verbose = 0;

BEGIN { use_ok "System::Info", qw( sysinfo sysinfo_hash si_uname ) }

ok defined &sysinfo, "sysinfo  imported";
ok defined &si_uname, "si_uname imported";

{   local $^O = "Generic";
    my $si = System::Info->new;

    isa_ok $si => "System::Info::Base";
    ok $si->cpu_type, $si->cpu_type;
    ok $si->cpu, $si->cpu;
    is $si->ncpu, "", "no ncpu";
    ok $si->os, $si->os;
    ok $si->host, $si->host;
    }

{   my $si = System::Info->new;

    my ($counter, $expect) = (0, 4);

    isa_ok ($si, "System::Info::Base");
    $counter += ok ($si->cpu_type, "cpu_type: " . $si->cpu_type);
    $counter += ok ($si->cpu,      "cpu: "      . $si->cpu);
    SKIP: {
	$si->ncpu or skip "No #cpu code for this platform", 1;
	$counter += ok ($si->ncpu,  "number of cpus: " . $si->ncpu);
	$expect++;
	}
    $counter += ok ($si->os,   $si->os);
    $counter += ok ($si->host, $si->host);

    ok (my $sysinfo = sysinfo (), "sysinfo function");
    is join ( " ", @{ $si }{map "_$_" => qw( host os cpu_type )}),
       $sysinfo, "test sysinfo $sysinfo";

    is ($counter, $expect, "sysinfo: $sysinfo");

    ok (my $si_hash = sysinfo_hash (), "sysinfo_hash function");
    ok (ref $si, "Returns a ref");
    ok (defined $si_hash->{$_}, "Element $_ present and set") for
	qw( cpu cpu_count cpu_cores cpu_type distro hostname os osname osvers );
    }

{   my $si = System::Info->new;
    isa_ok $si, "System::Info::Base";

    my $si_uname = join " ", map $si->$_ => qw( host os cpu ncpu cpu_type );
    is $si->si_uname, $si_uname,              "si_uname";
    is $si->si_uname, $si->si_uname ("a"),    "si_uname (a)";
    is $si->si_uname ("rubbish"), $si_uname,  "si_uname (rubbish)";

    is $si->si_uname ("n"), $si->{_host},     "si_uname (n)";
    is $si->si_uname ("s"), $si->{_os},       "si_uname (s)";
    is $si->si_uname ("m"), $si->{_cpu},      "si_uname (m)";
    is $si->si_uname ("c"), $si->{_ncpu},     "si_uname (c)";
    is $si->si_uname ("p"), $si->{_cpu_type}, "si_uname (p)";

    is $si->si_uname (qw( n s )), "$si->{_host} $si->{_os}",       "si_uname (n, s)";
    is $si->si_uname (qw( n s )), $si->si_uname ("n s"),           "si_uname (n s)";
    is $si->si_uname (qw( s n )), $si->si_uname ("n s"),           "si_uname (s n)";

    is $si->si_uname (qw( n m )), "$si->{_host} $si->{_cpu}",      "si_uname (n, m)";
    is $si->si_uname (qw( n m )), $si->si_uname ("n m"),           "si_uname (n m)";
    is $si->si_uname (qw( m n )), $si->si_uname ("n m"),           "si_uname (m n)";

    is $si->si_uname (qw( n c )), "$si->{_host} $si->{_ncpu}",     "si_uname (n, c)";
    is $si->si_uname (qw( n c )), $si->si_uname ("n c"),           "si_uname (n c)";
    is $si->si_uname (qw( c n )), $si->si_uname ("n c"),           "si_uname (c n)";

    is $si->si_uname (qw( n p )), "$si->{_host} $si->{_cpu_type}", "si_uname (n, p)";
    is $si->si_uname (qw( n p )), $si->si_uname ("n p"),           "si_uname (n p)";
    is $si->si_uname (qw( p n )), $si->si_uname ("n p"),           "si_uname (p n)";

    is $si->si_uname (qw( s m )), "$si->{_os} $si->{_cpu}",        "si_uname (s, m)";
    is $si->si_uname (qw( s m )), $si->si_uname ("s m"),           "si_uname (s m)";
    is $si->si_uname (qw( m s )), $si->si_uname ("s m"),           "si_uname (m s)";

    is $si->si_uname (qw( s c )), "$si->{_os} $si->{_ncpu}",       "si_uname (s, c)";
    is $si->si_uname (qw( s c )), $si->si_uname ("s c"),           "si_uname (s c)";
    is $si->si_uname (qw( c s )), $si->si_uname ("s c"),           "si_uname (c s)";

    is $si->si_uname (qw( s p )), "$si->{_os} $si->{_cpu_type}",   "si_uname (s, p)";
    is $si->si_uname (qw( s p )), $si->si_uname ("s p"),           "si_uname (s p)";
    is $si->si_uname (qw( p s )), $si->si_uname ("s p"),           "si_uname (p s)";

    is $si->si_uname (qw( m c )), "$si->{_cpu} $si->{_ncpu}",      "si_uname (m, c)";
    is $si->si_uname (qw( m c )), $si->si_uname ("m c"),           "si_uname (m c)";
    is $si->si_uname (qw( c m )), $si->si_uname ("m c"),           "si_uname (c m)";

    is $si->si_uname (qw( m p )), "$si->{_cpu} $si->{_cpu_type}",  "si_uname (m, p)";
    is $si->si_uname (qw( m p )), $si->si_uname ("m p"),           "si_uname (m p)";
    is $si->si_uname (qw( p m )), $si->si_uname ("m p"),           "si_uname (p m)";

    is $si->si_uname (qw( c p )), "$si->{_ncpu} $si->{_cpu_type}", "si_uname (c, p)";
    is $si->si_uname (qw( c p )), $si->si_uname ("c p"),           "si_uname (c p)";
    is $si->si_uname (qw( p c )), $si->si_uname ("c p"),           "si_uname (c p)";
    }
