#!/usr/bin/env perl
use strict;
use warnings;

use Test::More;
use Test::Exception;

use_ok 'Perl::Metrics::Halstead';

throws_ok {
    Perl::Metrics::Halstead->new
} qr/Missing required arguments/, 'required file';

throws_ok {
    Perl::Metrics::Halstead->new( file => 'bogus' )
} qr/undefined value/, 'bogus file';

my $pmh = Perl::Metrics::Halstead->new( file => 'eg/tester1.pl' );
isa_ok $pmh, 'Perl::Metrics::Halstead';

is $pmh->n_operators, 8, 'n_operators';
is $pmh->n_operands, 1, 'n_operands';
is $pmh->n_distinct_operators, 5, 'n_distinct_operators';
is $pmh->n_distinct_operands, 1, 'n_distinct_operands';
is $pmh->prog_vocab, 6, 'prog_vocab';
is $pmh->prog_length, 9, 'prog_length';
is sprintf('%.3f', $pmh->est_prog_length), '11.610', 'est_prog_length';
is sprintf('%.3f', $pmh->volume), 23.265, 'volume';
my $x = $pmh->difficulty;
is sprintf('%.3f', $x), '2.500', 'difficulty';
is sprintf('%.3f', $pmh->level), '0.400', 'level';
is sprintf('%.3f', $pmh->lang_level), 3.722, 'lang_level';
is sprintf('%.3f', $pmh->intel_content), 9.306, 'intel_content';
is sprintf('%.3f', $pmh->effort), 58.162, 'effort';
is sprintf('%.3f', $pmh->time_to_program), 3.231, 'time_to_program';
is sprintf('%.3f', $pmh->delivered_bugs), 0.005, 'delivered_bugs';

my $y = $pmh->dump;
isa_ok $y, 'HASH';
is keys %$y, 15, 'dump';

can_ok $pmh, 'report';

$pmh = Perl::Metrics::Halstead->new( file => 'eg/tester2.pl' );
ok $pmh->difficulty > $x, 'increasing difficulty';
$x = $pmh->difficulty;
$pmh = Perl::Metrics::Halstead->new( file => 'eg/tester3.pl' );
ok $pmh->difficulty > $x, 'increasing difficulty';

done_testing();
