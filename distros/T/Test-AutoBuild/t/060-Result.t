# -*- perl -*-

use Test::More tests => 15;
use warnings;
use strict;
use Log::Log4perl;

BEGIN {
  use_ok("Test::AutoBuild::Result");
}

Log::Log4perl::init("t/log4perl.conf");


SIMPLE: {
    my $result = Test::AutoBuild::Result->new(name => "test",
					      label => "Test");
    isa_ok($result, "Test::AutoBuild::Result");

    is($result->name, "test", "name is test");
    is($result->label, "Test", "label is Test");
    ok(!defined $result->start_time, "start time is undefined");
    ok(!defined $result->end_time, "end time is undefined");
    ok(!defined $result->duration, "duration is undefined");
    is($result->log, "", "log is empty");

    $result->start_time(123);
    ok(!defined $result->duration, "duration is undefined");

    $result->end_time(456);
    is($result->duration, 333, "duration is undefined");
}


NESTED: {
    my $result = Test::AutoBuild::Result->new(name => "test",
					      label => "Test");
    isa_ok($result, "Test::AutoBuild::Result");

    ok(!$result->has_results, "no nested results");

    my $subresult = Test::AutoBuild::Result->new(name => "subtest",
						 label => "Sub-test");
    isa_ok($subresult, "Test::AutoBuild::Result");

    $result->add_result($subresult);
    ok($result->has_results, "nested results");

    my @results = $result->results;
    is_deeply(\@results, [$subresult], "got all subresults");
}
