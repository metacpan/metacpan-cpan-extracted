use lib 'lib', 't';
use warnings;
use strict;
use Test::More tests => 10;
use IO::All;

io->dir('t/output')->rmtree;

require TestC;
my $test = TestC->new;
no strict 'refs';
$test->quiet(1);
$test->extract_files(1);

ok(io('t/output/file1.html')->exists);
ok(io('t/output/file2.html')->exists);
ok(io('t/output/file3.html')->exists);
ok(io('t/output/file4.html')->exists);
ok(io('t/output/file5.html')->exists);
is(io('t/output/file1.html')->all, 
   "<!-- BEGIN file1 -->\n<hr>\n<!-- END file1 -->\n"
  );
is(io('t/output/file2.html')->all, 
   "<!-- BEGIN file2 -->\n<hr>\n<!-- END file2 -->\n"
  );
is(io('t/output/file3.html')->all, 
   " <hr>\n<!-- END file3 -->\n"
  );
is(io('t/output/file4.html')->all, 
   "<!-- BEGIN file4 -->\n<hr> \n"
  );
is(io('t/output/file5.html')->all, 
   " <hr>\n\n"
  );
