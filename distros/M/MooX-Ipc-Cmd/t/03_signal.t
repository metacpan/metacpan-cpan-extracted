#!/usr/bin/perl -w
use strict;
use Test::More;
use Config;


package test;
use Moo;
use MooX::Options;
with qw(MooX::Ipc::Cmd);
1;


package main;

use Log::Any::Adapter('Stdout');
use constant SIGKILL => 9;
if ($^O eq "MSWin32") {
	plan skip_all => "Signals not implemented on Win32";
} else {
	plan tests => 3;
}
my $test=test->new(_cmd_kill=>0);

# We want to invoke our sub-commands using Perl.

my $perl_path = $Config{perlpath};

if ($^O ne 'VMS') {
        $perl_path .= $Config{_exe}
                unless $perl_path =~ m/$Config{_exe}$/i;
}

use_ok("MooX::Ipc::Cmd","run");

chdir("t");

#  $test->_system([$perl_path,'signaler.pl' ,0 ]);
#  ok(1);

 eval {
 	$test->_system([$perl_path,"signaler.pl",SIGKILL]);
 };

 is($@->has_signal , 1);
 is($@->signal , 'KILL');

1;
