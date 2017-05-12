use warnings;
use strict;

our $totaltests;
BEGIN { $totaltests = 48; }
use Test::More tests => $totaltests;

BEGIN { use_ok('Net::ParSCP') };

#########################

SKIP: {
  skip("Developer test", $totaltests-1) unless ($ENV{DEVELOPER} && -x "script/parpush" && ($^O =~ /nux$/));

     rename "$ENV{HOME}/.csshrc", "$ENV{HOME}/csshrc";
     my $output = `script/parpush -v 'orion:.bashrc beowulf:.bashrc' europa:/tmp/bashrc.@# 2>&1`;
     like($output, qr{scp\s+beowulf:.bashrc\s+europa:.tmp.bashrc.beowulf}, 'using macro for source machine: remote target');
     like($output, qr{scp\s+orion:.bashrc europa:/tmp/bashrc.orion}, 'using macro for source machine: remote target');
     rename "$ENV{HOME}/csshrc", "$ENV{HOME}/.csshrc";

     # Range
     $output = `script/parpush -v -d Makefile 127.0.0.1..5:/tmp/ 2>&1`;
     my $ok = $output =~  m{
            scp\s+Makefile\s+127.0.0.3:/tmp/.+
            scp\s+Makefile\s+127.0.0.1:/tmp/.+
            scp\s+Makefile\s+127.0.0.5:/tmp/.+
            scp\s+Makefile\s+127.0.0.4:/tmp/.+
            scp\s+Makefile\s+127.0.0.2:/tmp/
     }xs;
     ok($ok,'checking ranges');

     $output = `script/parpush -v 'orion:.bashrc beowulf:.bashrc' europa:/tmp/bashrc.@# 2>&1`;
     like($output, qr{scp\s+beowulf:.bashrc\s+europa:.tmp.bashrc.beowulf}, 'using macro for source machine: remote target');
     like($output, qr{scp\s+orion:.bashrc europa:/tmp/bashrc.orion}, 'using macro for source machine: remote target');
     ok(!$?, 'macro for source machine: status 0');

     $output = `script/parpush -n =europa -v MANIFEST  beo-europa:/tmp/@# 2>&1`;
     ok(!$?, 'macro from local to remote: status 0');
     like($output, qr{scp  MANIFEST beowulf:/tmp/europa}, 'using -n =europa and macro from local machine: remote target');
     like($output, qr{scp  MANIFEST orion:/tmp/europa}, 'using -n  =europa and macro from local machine: remote target');

     $output = `script/parpush -v MANIFEST  beo-europa:/tmp/@# 2>&1`;
     ok(!$?, 'macro from local to remote: status 0');
     like($output, qr{scp  MANIFEST beowulf:/tmp/localhost}, 'using macro from local machine: remote target');
     like($output, qr{scp  MANIFEST orion:/tmp/localhost}, 'using macro from local machine: remote target');

     $output = `script/parpush -n localhost=orionbashrc -v orion:.bashrc :/tmp/@= 2>&1`;
     ok(!$?, 'macro target from remote to local: status 0');
     like($output, qr{scp -r orion:.bashrc /tmp/orionbashrc}, 'using -n localhost=orionbashrc with target macro to local machine');

     $output = `script/parpush -n orion=orionbashrc -v orion:.bashrc :/tmp/@# 2>&1`;
     ok(!$?, 'macro source with -n from remote to local: status 0');
     like($output, qr{Executing system command:\s+scp -r orion:.bashrc /tmp/orionbashrc}, 'using -n orion=orionbashrc with source macro to local machine');

     $output = `script/parpush -n orion=ORION -n beowulf=BEO -v 'orion:.bashrc beowulf:.bashrc' europa:/tmp/bashrc.@# 2>&1`;
     ok(!$?, 'macro for source with 2 -n options: status 0');
     like($output, qr{scp  beowulf:.bashrc europa:/tmp/bashrc.BEO}, 'macro for source with 2 -n options: correct command 1');
     like($output, qr{scp  orion:.bashrc europa:/tmp/bashrc.ORION}, 'macro for source with 2 -n options: correct command 2');
     
     system('rm -fR /tmp/bashrc.BEOW /tmp/bashrc.ORI');

SKIP: {
     skip('Files /tmp/bashrc.BEOW and /tmp/bashrc.ORI exist', 5) if (-e '/tmp/bashrc.BEOW' || -e '/tmp/bashrc.ORI');

     $output = `script/parpush -n orion=ORI -n beowulf=BEOW -v 'orion:.bashrc beowulf:.bashrc' :/tmp/bashrc.@# 2>&1`;
     ok(!$?, 'macro for source with 2 -n options (to local): status 0');
     like($output, qr{scp -r beowulf:.bashrc /tmp/bashrc.BEOW}, 'macro for source with 2 -n options (to local): correct command 1');
     like($output, qr{scp -r orion:.bashrc /tmp/bashrc.ORI}, 'macro for source with 2 -n options (to local): correct command 2');
     ok(-e '/tmp/bashrc.BEOW', '/tmp/bashrc.BEOW remote file transferred');
     ok(-e '/tmp/bashrc.ORI', 'remote file transferred');
}

     $output = `script/parpush -h`;
     ok(!$?, 'help: status 0');
     like($output, qr{Name:\s+parpush - Secure transfer of files between clusters via SSH},'help:Name');
     like($output, qr{Usage:\s+parpush}, 'help: Usage');
     like($output, qr{Options:\s+--configfile file}, 'help:Options');
     like($output, qr{--xterm}, 'help: xterm option');

     # cluster to cluster copy
     $output = `script/parpush -v beo:.bashrc beo:/tmp/bashrc_at_@# 2>&1`;
     like($output, qr{scp  beowulf:.bashrc beowulf:/tmp/bashrc_at_beowulf}, 'cluster2cluster: b->b');
     like($output, qr{scp  europa:.bashrc beowulf:/tmp/bashrc_at_europa}, 'cluster2cluster: e->b');
     like($output, qr{scp  orion:.bashrc beowulf:/tmp/bashrc_at_orion}, 'cluster2cluster: o->b');

     like($output, qr{scp  beowulf:.bashrc europa:/tmp/bashrc_at_beowulf}, 'cluster2cluster: b->e');
     like($output, qr{scp  europa:.bashrc europa:/tmp/bashrc_at_europa}, 'cluster2cluster: e->e');
     like($output, qr{scp  orion:.bashrc europa:/tmp/bashrc_at_orion}, 'cluster2cluster: o->e');

     like($output, qr{scp  beowulf:.bashrc orion:/tmp/bashrc_at_beowulf}, 'cluster2cluster: b->o');
     like($output, qr{scp  europa:.bashrc orion:/tmp/bashrc_at_europa}, 'cluster2cluster: e->o');
     like($output, qr{scp  orion:.bashrc orion:/tmp/bashrc_at_orion}, 'cluster2cluster: o->o');

     $output = `script/parpush -v beo:.bashrc beo-europa:/tmp/BASHRC_AT_@# 2>&1`;
     like($output, qr{scp  beowulf:.bashrc beowulf:/tmp/BASHRC_AT_beowulf}, 'cluster2cluster: b->b');
     like($output, qr{scp  europa:.bashrc beowulf:/tmp/BASHRC_AT_europa}, 'cluster2cluster: e->b');
     like($output, qr{scp  orion:.bashrc beowulf:/tmp/BASHRC_AT_orion}, 'cluster2cluster: o->b');

     like($output, qr{scp  beowulf:.bashrc orion:/tmp/BASHRC_AT_beowulf}, 'cluster2cluster: b->o');
     like($output, qr{scp  europa:.bashrc orion:/tmp/BASHRC_AT_europa}, 'cluster2cluster: e->o');
     like($output, qr{scp  orion:.bashrc orion:/tmp/BASHRC_AT_orion}, 'cluster2cluster: o->o');

     # One-liner
     $output = `perl -Ilib -MNet::ParSCP -e '\$VERBOSE = 1; parpush(sourcefile=>q{MANIFEST}, destination=>q{beo-europa:/tmp/})' 2>&1`;
     ok(!$?, 'one liner: status 0');
     like($output, qr{scp  MANIFEST beowulf:/tmp/}, 'one liner: scp to b');
     like($output, qr{scp  MANIFEST orion:/tmp/}, 'one liner: scp to o');
}



