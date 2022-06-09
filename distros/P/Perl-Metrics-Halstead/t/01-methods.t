#!/usr/bin/env perl
use strict;
use warnings;

use Test::More;
use Test::Exception;
use Capture::Tiny 'capture';

use_ok 'Perl::Metrics::Halstead';

subtest throws => sub {
    throws_ok {
        Perl::Metrics::Halstead->new
    } qr/Missing required arguments/, 'file required';

    throws_ok {
        Perl::Metrics::Halstead->new( file => 'bogus' )
    } qr/Computation can't continue/, 'bogus file';
};

subtest attrs => sub {
    my $pmh = new_ok 'Perl::Metrics::Halstead' => [ file => 'eg/tester1.pl' ];

    is $pmh->n_operators, 8, 'n_operators';
    is $pmh->n_operands, 1, 'n_operands';
    is $pmh->n_distinct_operators, 5, 'n_distinct_operators';
    is $pmh->n_distinct_operands, 1, 'n_distinct_operands';
    is $pmh->prog_vocab, 6, 'prog_vocab';
    is $pmh->prog_length, 9, 'prog_length';
    is sprintf('%.3f', $pmh->est_prog_length), '11.610', 'est_prog_length';
    is sprintf('%.3f', $pmh->volume), 23.265, 'volume';
    is sprintf('%.3f', $pmh->difficulty), '2.500', 'difficulty';
    is sprintf('%.3f', $pmh->level), '0.400', 'level';
    is sprintf('%.3f', $pmh->lang_level), 3.722, 'lang_level';
    is sprintf('%.3f', $pmh->intel_content), 9.306, 'intel_content';
    is sprintf('%.3f', $pmh->effort), 58.162, 'effort';
    is sprintf('%.3f', $pmh->time_to_program), 3.231, 'time_to_program';
    is sprintf('%.3f', $pmh->delivered_bugs), 0.005, 'delivered_bugs';
};

subtest methods => sub {
    my $pmh = new_ok 'Perl::Metrics::Halstead' => [ file => 'eg/tester1.pl' ];

    my $got = $pmh->dump;
    isa_ok $got, 'HASH';
    is keys %$got, 15, 'dump';

    my ($stdout, $stderr) = capture { $pmh->report };
    ok !$stderr, 'no report errors';
    $got = $pmh->difficulty;
    like $stdout, qr/difficulty: $got/, 'report difficulty';
};

subtest difficulty => sub {
    my $pmh = new_ok 'Perl::Metrics::Halstead' => [ file => 'eg/tester1.pl' ];
    my $got = $pmh->difficulty; # set the initial metric

    $pmh = new_ok 'Perl::Metrics::Halstead' => [ file => 'eg/tester2.pl' ];
    ok $pmh->difficulty > $got, 'increasing difficulty';
    $got = $pmh->difficulty; # reset the metric

    $pmh = new_ok 'Perl::Metrics::Halstead' => [ file => 'eg/tester3.pl' ];
    ok $pmh->difficulty > $got, 'increasing difficulty';
};

done_testing();
