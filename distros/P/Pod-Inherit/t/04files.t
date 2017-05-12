#!/usr/bin/perl
use lib 't/auxlib';
use Test::JMM;
use Test::More 'no_plan';
use Test::Differences;
use Test::Pod;
use lib 't/lib';

use_ok('Pod::Inherit');

my @tests = (
# TODO       ['SimpleBaseClass', 'no inheritance, existing POD'],
             ['SimpleSubClass', '"use base", no existing POD'],
             ['SimplePodSubClass', '"use base", existing simple POD'],
             ['PodWithAuthor', '"use base", existing POD with Author+License section'],
             ['AuthorNoPod', '"use base", just Author+License sections'],
             ['OverloadSubClass', '"use base", inherited overloaded behaviour'],
             ['_NotShownSubClass', '"use base", with an _method in the base, and in the class name'],
             ['SkipUnderscoreSubClass', '"use base", with an _method in the base'],
             ['OverrideDoubleSubClass', '"use base", three levels, the sub being defined on 1st and 2nd'],
             ['Deep/Name/Space/Sub', '"use base", with a nice deep namespace'],
             ['InlineSubConfig', 'inline config, skip_underscored + class_map'],
            );

## All these test the output that lands in the same dir as the input
foreach my $test (@tests) {
    my ($class, $testname) = @$test;
    unlink("t/lib/${class}.pod");

    my $pi = Pod::Inherit->new({
                                input_files => ["t/lib/${class}.pm"],
                                # out_dir     => 't/var/',
                               });

    isa_ok($pi, 'Pod::Inherit');

    $pi->write_pod();

    eq_or_diff(
        do { local (@ARGV, $/) = "t/lib/${class}.pod";            <> || 'NO OUTPUT' },
        do { local (@ARGV, $/) = "t/baseline/files/${class}.pod"; <> || 'NO BASELINE' },
        "$class - $testname - out_dir unset");

    pod_file_ok("t/lib/${class}.pod", "$class - ${testname} - Test::Pod passes - out_dir unset");
    unlink("t/lib/${class}.pod");
}

## Now we test dumping the output to a separate filetree.
foreach my $test (@tests) {
    my ($class, $testname) = @$test;
    Path::Class::Dir->new("t/output/files/")->rmtree;

    my $pi = Pod::Inherit->new({
                                input_files => ["t/lib/${class}.pm"],
                                out_dir     => 't/output/files/',
                               });

    isa_ok($pi, 'Pod::Inherit');

    $pi->write_pod();

    # We told it do just this file, and put the output in output/files... so it does.
    my $outpath = "t/output/files/".Path::Class::File->new($class)->basename.".pod";

    ## NB: "scalar" forces a result in list context, otherwise we get
    ## crazy arguments to eq_or_diff
    eq_or_diff(
               do { local (@ARGV, $/) = $outpath;                        <> || 'NO OUTPUT' },
               do { local (@ARGV, $/) = "t/baseline/files/${class}.pod"; <> || 'NO BASELINE' },
               "$class - $testname - out_dir set");

    pod_file_ok($outpath, "$class - ${testname} - Test::Pod passes - out_dir set");
}

Path::Class::Dir->new("t/output/files/")->rmtree;
