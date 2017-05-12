#!perl

use strict;
use warnings;

use Test::More tests => 2;

require_ok('Sys::Filesystem');
use_ok('Sys::Filesystem');

use Config;

my $os_info = join( "-", $Config{osname}, $Config{osvers} );
$^O eq "MSWin32" and eval "use Win32;" and $os_info = join( "-", Win32::GetOSName(), Win32::GetOSVersion() );

diag("Testing Sys::Filesystem $Sys::Filesystem::VERSION, Perl $] ($^X) on $os_info");
