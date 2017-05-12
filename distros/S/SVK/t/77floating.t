#!/usr/bin/perl -w
use Test::More tests => 12;
use strict;
use SVK::Test;

my ($basexd, $basesvk) = build_test();
our $output;
my ($copath, $corpath) = get_copath ('floating');

is_output($basesvk, 'checkout', ['--floating', '//', $copath], [
        "Syncing //(/) in $corpath to 0.", ]);
ok(-e $copath, 'floating checkout');
ok(-e "$copath/.svk/floating", 'checkout is floating');
ok(-e "$copath/.svk/config", 'config file exists');

my ($xd, $svk) = build_floating_test($corpath);

mkdir "$copath/A";
overwrite_file ("$copath/A/foo", "foobar");
$svk->add ("$copath/A");
$svk->commit ('-m', 'commit message here', "$copath");

is_output($svk, 'checkout', ['--list'], [
            "  Depot Path                    \tPath",
            "========================================================================",
            "  //                            \t$corpath",
	    ], 'one checkout in list');

ok(exists $xd->{checkout}->get($corpath)->{revision}, 'xd is absolute');
my $ref = $xd->{checkout}->{hash};
my @ref = each %$ref;
ok(! exists $xd->{checkout}->get("A/foo")->{revision}, 'xd is not relative');

use YAML::Syck;
my $loaded = LoadFile("$copath/.svk/config");
ok(ref($loaded->{checkout}) eq "Data::Hierarchy::Relative",
   'stored config is relative');
my $checkout = $loaded->{checkout}->to_absolute(Path::Class::Dir->new('/nowhere'));
ok(exists $checkout->get(Path::Class::Dir->new("/nowhere/A/foo"))->{revision}, 'relative lookup');
my ($copath2, $corpath2) = get_copath ('floating2');
rename ($corpath, $corpath2);
($xd, $svk) = build_floating_test($corpath2);

is_output($svk, 'checkout', ['--list'], [
            "  Depot Path                    \tPath",
            "========================================================================",
            "  //                            \t$corpath2",
	    ], 'checkout in list changed');
is_output($svk, 'status', [$corpath2], [], 'clean status');
overwrite_file ("$copath2/A/foo", "barfoo");
overwrite_file ("$copath2/A/other", "text");
$svk->add("$copath2/A/other");
$svk->commit("-m", "Some message", "$copath2/A/other");
is_output_like($svk, 'log', [$corpath2], qr/Some message/);

1;
