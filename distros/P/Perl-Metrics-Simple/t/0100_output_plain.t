#!/usr/bin/perl

use strict;
use warnings;

use FindBin qw($Bin);
use lib "$Bin/../lib";

use Test::More tests => 2;

my $CLASS_TO_TEST = 'Perl::Metrics::Simple::Output::PlainText';

use_ok($CLASS_TO_TEST);

test_new();

exit;

sub test_new {
    my $fake_analysis = bless {}, 'Perl::Metrics::Simple::Analysis';
    my $subject = $CLASS_TO_TEST->new($fake_analysis);

    isa_ok( $subject, $CLASS_TO_TEST );
}
