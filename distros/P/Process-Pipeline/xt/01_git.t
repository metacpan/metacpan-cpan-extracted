use strict;
use warnings;
use Test::More;
use Process::Pipeline::DSL;
BEGIN { unlink "Process-Pipeline.tar.gz" }
END   { unlink "Process-Pipeline.tar.gz" }

my $p = proc { "git", "archive", "--format=tar", "--prefix=Process-Pipeline/", "HEAD" }
        proc { set ">" => "Process-Pipeline.tar.gz"; "gzip" };

my $r = $p->start;
ok $r->is_success;
ok -f "Process-Pipeline.tar.gz";

my $p2 = proc { set "2>", "/dev/null"; "tar", "tf", "Process-Pipeline.tar.gz" }
         proc { qw(grep dist.ini) }
         proc { qw(wc -l) };
my $r2 = $p2->start;
ok $r2->is_success;
my $fh = $r2->fh;
chomp(my $num = <$fh>);
is $num, 1;

done_testing;
