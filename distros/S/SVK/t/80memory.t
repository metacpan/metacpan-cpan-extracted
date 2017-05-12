#!/usr/bin/perl -w
use strict;
use SVK::Test;
BEGIN {
    plan skip_all => "doesn't work on macosx"
        if $^O eq 'darwin';

  -d '/proc' or 
    eval { require BSD::Resource; } or
    plan( skip_all => "No /proc and no BSD::Resources" );
}
plan tests => 6;

my $curr_mem = sub { -1 };
if( -d '/proc' ) {
  $curr_mem = sub {
    open STAT, "grep '^VmRSS' /proc/$$/status|";
    my $ret = $1 if( <STAT> =~ /:\s*([^\s]*)/ );
    close STAT;
    return $ret;
  }
} else {
  require BSD::Resource;
  $curr_mem = sub {
    my @r = BSD::Resource::getrusage();
    return $r[2];
  }
}

sub no_leak {
  my ($action, $block) = @_;
  my $before = &$curr_mem;
  #diag("$before before $action");
  &$block;
  my $after = &$curr_mem;
  #diag("$after after $action");
  my $diff = $after - $before;
  cmp_ok($diff, '<', $before * 0.03, "Memory use shouldn't increase during $action") and
    $diff > 0 and diag("Memory use grew by $diff during $action");
}

our ($output, $answer);
my ($xd, $svk) = build_test('foo');
$svk->mkdir ('-pm', 'init src', '//mem-src/container');
$svk->mkdir ('-m', 'init dest', '//mem-dest');
$svk->smerge ('-Bm', 'merge init', '//mem-src', '//mem-dest');

our ($copath, $corpath) = get_copath ('memory');

TODO: {
local $TODO = "Fix more leaks";

no_leak('svk co', sub {
  $svk->checkout ('//mem-src', $copath);
});

my $max = 350;
my @names = (1..$max);

for my $name (@names) {
  append_file ("$copath/container/f-$name", "file $name");
}


no_leak('svk add', sub {
  $svk->add ("$copath/container");
});

no_leak('svk ci', sub {
  $svk->commit ('-m', 'add', "$copath/container");
});

no_leak('merge add', sub {
  $svk->smerge ('-Bm', 'merge add', '//mem-src', '//mem-dest');
});

}

no_leak('svk rm', sub {
  $svk->delete ('-m', 'del', "//mem-src/container");
});

no_leak('merge delete', sub {
  $svk->smerge ('-Bm', 'merge del', '//mem-src', '//mem-dest');
});

