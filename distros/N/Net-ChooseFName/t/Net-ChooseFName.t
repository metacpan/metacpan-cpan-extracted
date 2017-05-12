#!/usr/bin/perl -w
# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Net-ChooseFName.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use strict;
use Test::More tests => 52;
use File::Path 'rmtree';
BEGIN { use_ok('Net::ChooseFName') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

my @URLS = qw(
	http://arxiv.org/ps/math.AG/0309155.gz?front&dpi=300&font=bitmapped
	http://arxiv.org/dvi/math.AG/0309155.gz?front&dpi=300&font=bitmapped
	http://arxiv.org/pdf/math.AG/0309155.pdf?front
);

ok((!-d 'tmp' or rmtree 'tmp'), 'directory removed');
my $o = Net::ChooseFName->new(root => 'tmp');

is($o->find_name_by_url($URLS[0], undef, 'application/postscript'),
   'tmp/0309155.ps', 'with type application/postscript, no suff');
is($o->find_name_by_url($URLS[1], undef, 'application/x-dvi'),
   'tmp/0309155.dvi', 'with type application/x-dvi');
is($o->find_name_by_url($URLS[2], undef, 'application/pdf'),
   'tmp/0309155.pdf', 'with type application/pdf');
is($o->find_name_by_url($URLS[2]),
   'tmp/0309155.pdf', 'no type');
is($o->find_name_by_url($URLS[2]),
   'tmp/0309155.pdf', 'no type');
ok(open(F, '> tmp/0309155.pdf'), 'touch file');
ok(close(F), 'done');
is($o->find_name_by_url($URLS[2]),
   'tmp/0309155.pdf', 'no type');

$o = Net::ChooseFName->new(root => 'tmp', 'hierarchical' => 1);
is($o->find_name_by_url($URLS[0], undef, 'application/postscript'),
   'tmp/ps/math.AG/0309155.ps', 'with type application/postscript, no suff');
is($o->find_name_by_url($URLS[1], undef, 'application/x-dvi'),
   'tmp/dvi/math.AG/0309155.dvi', 'with type application/x-dvi, no suff');
ok(-d 'tmp/dvi/math.AG', 'directory exists');
is($o->find_name_by_url($URLS[2], undef, 'application/pdf'),
   'tmp/pdf/math.AG/0309155.pdf', 'with type application/pdf');
is($o->find_name_by_url($URLS[2]),
   'tmp/pdf/math.AG/0309155.pdf', 'no type');
is($o->find_name_by_url($URLS[2]),
   'tmp/pdf/math.AG/0309155.pdf', 'no type');
ok(open(F, '> tmp/pdf/math.AG/0309155.pdf'), 'touch file');
ok(close(F), 'done');
is($o->find_name_by_url($URLS[2]),
   'tmp/pdf/math.AG/0309155.pdf', 'no type');
ok(unlink('tmp/pdf/math.AG/0309155.pdf'), 'unlink touched');

$o = Net::ChooseFName->new(root => 'tmp', hierarchical => 1, cache_name => 0);
is($o->find_name_by_url($URLS[2]),
   'tmp/pdf/math.AG/0309155.pdf', 'no type');
is($o->find_name_by_url($URLS[2]),
   'tmp/pdf/math.AG/0309155.pdf', 'no type');
ok(open(F, '> tmp/pdf/math.AG/0309155.pdf'), 'touch file');
ok(close(F), 'done');
is($o->find_name_by_url($URLS[2]),
   'tmp/pdf/math.AG/0309155001.pdf', 'no type');

$o = Net::ChooseFName->new(root => 'tmp', hierarchical => 1);
is($o->find_name_by_url($URLS[2]),
   'tmp/pdf/math.AG/0309155001.pdf', 'no type');

$o = Net::ChooseFName->new(root => 'tmp', hierarchical => 1,
			   ignore_existing_files => 1);
is($o->find_name_by_url($URLS[2]),
   'tmp/pdf/math.AG/0309155.pdf', 'no type');

ok(unlink('tmp/pdf/math.AG/0309155.pdf'), 'unlink touched');

$o = Net::ChooseFName->new(root => 'tmp/tmp', 'hierarchical' => 1, 'mkpath' => 0);
is($o->find_name_by_url($URLS[0], undef, 'application/postscript'),
   'tmp/tmp/ps/math.AG/0309155.ps', 'with type application/postscript, no suff');
is($o->find_name_by_url($URLS[1], undef, 'application/x-dvi'),
   'tmp/tmp/dvi/math.AG/0309155.dvi', 'with type application/x-dvi, no suff');
ok(! -d 'tmp/tmp/dvi/math.AG', 'directory does not exists');
is($o->find_name_by_url($URLS[2], undef, 'application/pdf'),
   'tmp/tmp/pdf/math.AG/0309155.pdf', 'with type application/pdf');
is($o->find_name_by_url($URLS[2]),
   'tmp/tmp/pdf/math.AG/0309155.pdf', 'no type');

$o = Net::ChooseFName->new(root => 'tmp', 'hierarchical' => 1, max_length => 6);
is($o->find_name_by_url($URLS[0], undef, 'application/postscript'),
   'tmp/ps/math.A/030.ps', 'with type application/postscript, no suff');
is($o->find_name_by_url($URLS[1], undef, 'application/x-dvi'),
   'tmp/dvi/math.A/03.dvi', 'with type application/x-dvi, no suff');
ok(-d 'tmp/dvi/math.A', 'directory exists');
is($o->find_name_by_url($URLS[2], undef, 'application/pdf'),
   'tmp/pdf/math.A/03.pdf', 'with type application/pdf');
is($o->find_name_by_url($URLS[2]),
   'tmp/pdf/math.A/03.pdf', 'no type');

$o = Net::ChooseFName->new(root => 'tmp', 'hierarchical' => 1,
			   suggested_only_basename => 0);
is($o->find_name_by_url($URLS[0], 'paper.eps', 'application/postscript'),
   'tmp/paper.ps', 'with type application/postscript, suggested, no suff');

$o = Net::ChooseFName->new(root => 'tmp', 'hierarchical' => 1);
is($o->find_name_by_url($URLS[0], 'paper.eps', 'application/postscript'),
   'tmp/ps/math.AG/paper.ps', 'with type application/postscript, suggested, no suff');

$o = Net::ChooseFName->new(root => 'tmp');
is($o->find_name_by_url($URLS[0], 'paper.eps', 'application/postscript'),
   'tmp/paper.ps', 'with type application/postscript, suggested, no suff');

$o = Net::ChooseFName->new(root => 'tmp', suggested_only_basename => 1);
is($o->find_name_by_url($URLS[0], 'paper.eps', 'application/postscript'),
   'tmp/paper.ps', 'with type application/postscript, suggested, no suff');

my $long = # 'http://groups-beta.google.com/group/comp.lang.perl/browse_thread/thread/3ee08b1ef5ae3c12/30a234783d298f2e?q=beg%2Fyour+group:*.perl.*+author:Larry+author:Wall&_done=%2Fgroups%3Fas_q%3Dbeg%2Fyour%26as_epq%3D%26as_oq%3D%26as_eq%3D%26btnG%3DGoogle+Search+News%26as_ugroup%3D*.perl.*%26as_usubject%3D%26as_uauthors%3DLarry+Wall%26as_umsgid%3D%26lr%3D%26as_drrb%3Dq%26as_qdr%3D%26as_mind%3D29%26as_minm%3D3%26as_miny%3D1981%26as_maxd%3D26%26as_maxm%3D10%26as_maxy%3D2005%26num%3D50%26as_scoring%3Dr%26&_doneTitle=Back+to+Search&&d#30a234783d298f2e';
 'http://groups-beta.google.com/group/comp.lang.perl/browse_thread/thread/3ee08b1ef5ae3c12/30a234783d298f2e?q=beg%2Fyour+%22local($_)+works%22+group:*.perl.*+author:Larry+author:Wall&_done=%2Fgroups%3Fas_q%3Dbeg%2Fyour%26as_epq%3Dlocal($_)+works%26as_oq%3D%26as_eq%3D%26btnG%3DGoogle+Search+News%26as_ugroup%3D*.perl.*%26as_usubject%3D%26as_uauthors%3DLarry+Wall%26as_umsgid%3D%26lr%3D%26as_drrb%3Dq%26as_qdr%3D%26as_mind%3D29%26as_minm%3D3%26as_miny%3D1981%26as_maxd%3D26%26as_maxm%3D10%26as_maxy%3D2005%26num%3D50%26as_scoring%3Dr%26&_doneTitle=Back+to+Search&&d#30a234783d298f2e';
$o = Net::ChooseFName->new(root => 'tmp', 'hierarchical' => 1);
is($o->find_name_by_url($long),
   'tmp/group/comp.lang.perl/browse_thread/thread/3ee08b1ef5ae3c12/30a234783d298f2e',
   'long URL with query');

$o = Net::ChooseFName->new(root => 'tmp', hierarchical => 1, site_dir => 1);
is($o->find_name_by_url($long),
   'tmp/groups-beta.google.com/group/comp.lang.perl/browse_thread/thread/3ee08b1ef5ae3c12/30a234783d298f2e',
   'long URL with query');

$o = Net::ChooseFName->new(root => 'tmp', hierarchical => 1,
			   site_dir => 1, 'max_length' => 12);
is($o->find_name_by_url($long),
   'tmp/groups-beta./group/comp.lang.pe/browse_threa/thread/3ee08b1ef5ae/30a234783d29',
   'long URL with query');

$o = Net::ChooseFName->new(root => 'tmp', hierarchical => 1, site_dir => 1,
			   use_query => '@q=');
my $q = <<'EOQ';
@q=q=beg@2Fyour+@22local($_)+works@22+group@3A@2A.perl.@2A+author@3ALarry+author@3AWall&_done=@2Fgroups@3Fas_q@3Dbeg@2Fyour@26as_epq@3Dlocal($_)+works@26as_oq@3D@26as_eq@3D@26btnG@3DGoogle+Search+News@26as_ugroup@3D@2A.perl.@2A@26as_usubje
EOQ
chop $q;
is($o->find_name_by_url($long),
   "tmp/groups-beta.google.com/group/comp.lang.perl/browse_thread/thread/3ee08b1ef5ae3c12/30a234783d298f2e$q",
   'long URL with query');

$o = Net::ChooseFName->new(root => 'tmp', hierarchical => 1, site_dir => 1,
			   use_query => '@q=', dir_query => 1);
my $rest = 'ct@3D@26as_uauth';
is($o->find_name_by_url($long),
   "tmp/groups-beta.google.com/group/comp.lang.perl/browse_thread/thread/3ee08b1ef5ae3c12/30a234783d298f2e/$q$rest",
   'long URL with query');

$o = Net::ChooseFName->new(root => 'tmp', hierarchical => 1, site_dir => 1,
			   use_query => '@q=', dir_query => 1, keep_space => 1);
(my $llong = $long) =~ s/\+/%20/g;
(my $qq = "$q$rest") =~ s/\+/ /g;
is($o->find_name_by_url($llong),
   "tmp/groups-beta.google.com/group/comp.lang.perl/browse_thread/thread/3ee08b1ef5ae3c12/30a234783d298f2e/$qq",
   'long URL with query');

$o = Net::ChooseFName->new(root => 'tmp', hierarchical => 1, site_dir => 1,
			   use_query => '@q=', dir_query => 1, tolower => 1);
is($o->find_name_by_url($long),
   lc "tmp/groups-beta.google.com/group/comp.lang.perl/browse_thread/thread/3ee08b1ef5ae3c12/30a234783d298f2e/$q$rest",
   'long URL with query');

$o = Net::ChooseFName->new(root => 'tmp', hierarchical => 1, site_dir => 1,
			   use_query => '@q=', dir_query => 1, '8+3' => 1);
is($o->find_name_by_url($long),
   'tmp/groups-b.com/group/comp_lan.pel/browse_t.ead/thread/3ee08b1e.c12/30a23478.f2e/@q=q=beg.@2h',
   'long URL with query');

(my $r = $rest) =~ s/.....$/.html/;
$o = Net::ChooseFName->new(root => 'tmp', hierarchical => 1, site_dir => 1,
			   use_query => '@q=', dir_query => 1);
is($o->find_name_by_url($long, undef, 'text/html'),
   "tmp/groups-beta.google.com/group/comp.lang.perl/browse_thread/thread/3ee08b1ef5ae3c12/30a234783d298f2e/$q$r",
   'long URL with query');

$o = Net::ChooseFName->new(root => 'tmp', hierarchical => 1, site_dir => 1,
			   use_query => '@q=', dir_query => 1, '8+3' => 1);
is($o->find_name_by_url($long, undef, 'text/html'),
   'tmp/groups-b.com/group/comp_lan.pel/browse_t.ead/thread/3ee08b1e.c12/30a23478.f2e/@q=q=beg.htm',
   'long URL with query');

