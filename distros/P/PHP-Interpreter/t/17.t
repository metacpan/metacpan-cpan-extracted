#!/opt/ecelerity/3rdParty/bin/perl -w
use strict;
use Test::More tests => 6;

BEGIN {
    diag "Testing passing resources out of PHP";
    use_ok 'PHP::Interpreter' or die;
}

ok my $p = PHP::Interpreter->new, "Create new PHP interpreter";
ok my $fp = $p->fopen("/tmp/test", "a"), "Open a file with PHP";
ok $p->fwrite($fp, "hello world"), "Write to the file";
ok $p->fclose($fp), "Close the file";

open FILE, "/tmp/test";
my $content = <FILE>;
is $content, "hello world", "File contents are correct";
unlink "/tmp/test";
