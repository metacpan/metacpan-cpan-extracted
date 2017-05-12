#!perl

use strict;
use warnings;

use Test::Command tests => 9;

use Test::More;

use Config;

my @sig_names = split ' ', $Config{'sig_name'};
my @sig_nums  = split ' ', $Config{'sig_num'};
my %sig; @sig{@sig_names} = @sig_nums;

## determine whether we can run perl or not

system qq($^X -e 1) and BAIL_OUT('error calling perl via system');

SKIP:
   {
   skip("not sure about Win32 signal support", 9) if $^O eq 'MSWin32';
   signal_is_undef(qq($^X -e "exit 0"));
   signal_is_undef(qq($^X -e "exit 1"));
   signal_is_undef(qq($^X -e "exit 255"));
   signal_is_undef([$^X, '-e', 1]);
   skip("no SIGTERM found", 5) if ! exists $sig{'TERM'};
   is(signal_value([$^X,  '-e', 'kill ' . $sig{'TERM'} . ', $$']), $sig{'TERM'},
      "signal_value is SIGTERM" );;
   signal_is_defined([$^X,  '-e', 'kill ' . $sig{'TERM'} . ', $$']);
   signal_cmp_ok([$^X,  '-e', 'kill ' . $sig{'TERM'} . ', $$'], '>', -1 );
   signal_isnt_num([$^X,  '-e', 'kill ' . $sig{'TERM'} . ', $$'], $sig{'TERM'} + 1 );
   signal_is_num([$^X,  '-e', 'kill ' . $sig{'TERM'} . ', $$'], $sig{'TERM'} );
   }
