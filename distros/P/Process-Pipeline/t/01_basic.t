use strict;
use warnings;
use Test::More;
use Process::Pipeline;
use File::Temp ();

my @echo = ($^X,  "-e",  'print @ARGV');
my @cat  = ($^X, "-ne",  'print');
my @grep = ($^X, "-ne",  'BEGIN { $re = shift } print if /$re/');
my @wc_l = ($^X, "-nle", '$i++; END { print $i }');

subtest fail => sub {
    (undef, my $temp) = File::Temp::tempfile(UNLINK => 0);
    my $r = Process::Pipeline->new
      ->push(sub { my $p = shift; $p->cmd("oooops"); $p->set("2>", $temp) })
      ->push(sub { shift->cmd(@cat)           })
      ->start;
    ok !$r->is_success;
    open my $fh, "<", $temp or die;
    my @line = <$fh>;
    unlink $temp;
    note @line;
};

subtest test1 => sub {
    my $r = Process::Pipeline->new
      ->push(sub { shift->cmd(@echo, "hello") })
      ->push(sub { shift->cmd(@cat)           })
      ->push(sub { shift->cmd(@cat)           })
      ->push(sub { shift->cmd(@cat)           })
      ->start;
    ok $r->is_success;
    note explain $r;
    my $fh = $r->fh;
    my @lines = <$fh>;
    is @lines, 1;
    chomp $lines[0];
    is $lines[0], "hello";
};

subtest test2 => sub {
    my $r = Process::Pipeline->new
      ->push(sub { shift->cmd(@echo, "bar\n", "hello\n", "bar\n") })
      ->push(sub { shift->cmd(@grep, "bar")              })
      ->push(sub { shift->cmd(@wc_l)                     })
      ->start;
    ok $r->is_success;
    my $fh = $r->fh;
    chomp(my $line = <$fh>);
    is $line, 2;
};


done_testing;
