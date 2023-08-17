#!/usr/bin/perl
# t/tlock-2.pl
use strict;
use experimental qw(signatures);

use Test::More 'no_plan';

my ($dir , $tdir);
BEGIN {
    use File::Basename qw(dirname);
    use Cwd qw(abs_path);
    $tdir = dirname(abs_path($0));
    $dir = $tdir =~ s/[^\/]+$/lib/r;
    };

use lib $dir;
use Sys::Tlock dir => $tdir.'/tlock-2.d/' , conf => $tdir.'/tlock.conf' , marker => 'A';

ok (not glob($tdir.'/tlock-2.d/tlock*'));

ok (not tlock_taken 'test-2');
ok (not defined tlock_expiry 'test-2');
ok (not glob($tdir.'/tlock-2.d/A*'));

ok (not tlock_taken 'test-2' , marker => 'B');
ok (not defined tlock_expiry 'test-2' , marker => 'B');
ok (not glob($tdir.'/tlock-2.d/B*'));

my $token1 = tlock_take 'test-2' , 600;

ok (not glob($tdir.'/tlock-2.d/tlock*'));

ok (defined $token1);
ok (tlock_alive 'test-2' , $token1);
ok (tlock_taken 'test-2');
ok ((tlock_expiry 'test-2') == ($token1 + 600));
ok (glob($tdir.'/tlock-2.d/A*'));

ok (not tlock_taken 'test-2' , marker => 'B');
ok (not defined tlock_expiry 'test-2' , marker => 'B');
ok (not glob($tdir.'/tlock-2.d/B*'));

my $token2 = tlock_take 'test-2' , 600 , marker => 'B';

ok (not glob($tdir.'/tlock-2.d/tlock*'));

ok (tlock_alive 'test-2' , $token1);
ok (tlock_taken 'test-2');
ok (glob($tdir.'/tlock-2.d/A*'));

ok (defined $token2);
ok (tlock_alive 'test-2' , $token2 , marker => 'B');
ok (tlock_taken 'test-2' , marker => 'B');
ok ((tlock_expiry 'test-2' , marker => 'B') == ($token2 + 600));
ok (glob($tdir.'/tlock-2.d/B*'));

ok (tlock_release 'test-2' , $token1);

ok (not glob($tdir.'/tlock-2.d/tlock*'));

ok (not tlock_alive 'test-2' , $token1);
ok (not tlock_taken 'test-2');
ok (not defined tlock_expiry 'test-2');
ok (not glob($tdir.'/tlock-2.d/A*'));

ok (tlock_alive 'test-2' , $token2 , marker => 'B');
ok (tlock_taken 'test-2' , marker => 'B');
ok (glob($tdir.'/tlock-2.d/B*'));

ok (tlock_release 'test-2' , $token2 , marker => 'B');

ok (not glob($tdir.'/tlock-2.d/tlock*'));

ok (not tlock_taken 'test-2');
ok (not defined tlock_expiry 'test-2');
ok (not glob($tdir.'/tlock-2.d/A*'));

ok (not tlock_alive 'test-2' , $token2 , marker => 'B');
ok (not tlock_taken 'test-2' , marker => 'B');
ok (not defined tlock_expiry 'test-2' , marker => 'B');
ok (not glob($tdir.'/tlock-2.d/B*'));

__END__
