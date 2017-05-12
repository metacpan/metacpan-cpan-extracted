use strict;
use warnings;
use Test::More;
use Process::Pipeline::DSL;

my @echo = ($^X,  "-e",  'print @ARGV');
my @cat  = ($^X, "-ne",  'print');
my @grep = ($^X, "-ne",  'BEGIN { $re = shift } print if /$re/');
my @wc_l = ($^X, "-nle", '$i++; END { print $i }');

subtest test1 => sub {
    my $p = proc { @echo, "hello" }
            proc { @cat }
            proc { @cat }
            proc { @cat }
            proc { @cat };
    my $r = $p->start;
    ok $r->is_success;
    note explain $r;
    my $fh = $r->fh;
    my @lines = <$fh>;
    is @lines, 1;
    chomp $lines[0];
    is $lines[0], "hello";
};

subtest test2 => sub {
    my $p = proc { @echo, "bar\n", "hello\n", "bar\n" }
            proc { @grep, "bar" }
            proc { @wc_l };
    my $r = $p->start;
    ok $r->is_success;
    my $fh = $r->fh;
    chomp(my $line = <$fh>);
    is $line, 2;
};


done_testing;
