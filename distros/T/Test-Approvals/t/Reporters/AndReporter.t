#! perl
use strict;
use warnings FATAL => qw(all);
use autodie;
use version; our $VERSION = qv('v0.0.5');

use Test::Approvals::Specs qw(describe it run_tests);
use Test::More;
use Test::Approvals::Reporters;

describe 'An AndReporter' => sub {
    my $r = [
        Test::Approvals::Reporters::FakeReporter->new(),
        Test::Approvals::Reporters::FakeReporter->new(),
    ];
    my $and = Test::Approvals::Reporters::AndReporter->new( reporters => $r );
    it 'Invokes multiple reporters' => sub {
        my ($spec) = @_;

        $and->report( 'foo', 'bar' );
        ok $r->[0]->was_called && $r->[1]->was_called, $spec;
    };
};

run_tests();
