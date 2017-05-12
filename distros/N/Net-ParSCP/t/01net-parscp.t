# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Net-ParSCP.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use warnings;
use strict;
use Test::More tests => 16;
BEGIN { use_ok('Net::ParSCP') };

#########################

SKIP: {
  skip("Developer test", 15) unless ($ENV{DEVELOPER} && -x "script/parpush" && ($^O =~ /nux$/));

     my $output = `script/parpush -v MANIFEST  beo-chum:/tmp 2>&1`;
     my $ok = $output =~ m{Executing system command:\s+scp\s+MANIFEST beowulf:/tmp.*scp\s+MANIFEST europa:/tmp.*scp\s+MANIFEST orion:/tmp}s;
     ok($ok, 'Not Illegal machine names');

     $output = `script/parpush -v MANIFEST  trutu-orion:/tmp 2>&1`;
     like($output, qr/(identifier \(trutu\) does not correspond)|(ssh:.*not known)/, 'Illegal cluster name');

     $output = `script/parpush -v MANIFEST  beo-europa/tmp 2>&1`;
     like($output, qr{Destination 'beo-europa/tmp' must have.*colon}, 'colon missed');

     $output = `script/parpush -v MANIFEST  beo-europa:/tmp 2>&1`;
     like($output, qr{\w+ output:\s+\w+ output:\s*}, 'difference: successful connection');

     $output = `script/parpush -v MANIFEST  beo*europa:/tmp 2>&1`;
     like($output, qr{Executing system command:\s+scp  MANIFEST europa:/tmp}, 'interseccion: successful connection');

     $output = `script/parpush -v MANIFEST  beo:europa:/tmp 2>&1`;
     like($output, qr{Error.\sDestination\s'beo:europa:/tmp'\smust\shave.*colon\s\(:\).\sSkipping\stransfer}, 'double colon error');

     $output = `script/parpush -v MANIFEST  beo-europa: 2>&1`;
     like($output, qr{\w+ output:\s+\w+ output:\s*}, 'empty path: successful connection');

     $output = `script/parpush -v MANIFEST  pleuropa: 2>&1`;
     unlike($output, qr/(identifier \(chum\) does not correspond)|(ssh:.*not known)/, 'non declared but existing machine');

     system('rm -fR /tmp/.bashrc /tmp/tutu/');

SKIP: {
     skip('Files /tmp/.bashrc and /tmp/tutu/ exists',6) if (-e '/tmp/.bashrc' || -e '/tmp/tutu/');

     $output = `script/parpush -v 'orion:.bashrc beowulf:tutu/' :/tmp/ 2>&1`;
     like($output, qr{Executing system command:\s+scp -r orion:.bashrc\s+/tmp/}, '2 remotes to local: scp command orion');
     like($output, qr{Executing system command:\s+scp -r beowulf:tutu/\s+/tmp/}, '2 remotes to local: scp command beowulf');
     like($output, qr{localhost output:\s*$}, 'remote to local: no warnings');
     ok(-e '/tmp/.bashrc', 'remote file transferred');
     ok(-x '/tmp/tutu', 'remote dir transferred');
     ok(!$?, 'remote to local: status 0');
}

     $output = `script/parpush -h`;
     like($output, qr{^Name:\s+parpush - Secure transfer of files between clusters via SSH}, 'help flag');
}



