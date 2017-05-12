#!/usr/bin/env perl
use 5.010;
use warnings;
use utf8;

use Puncheur::Runner;

Puncheur::Runner->new('PLite', {
    server => 'Starlet',
    port   => 1988,
})->run;

=comment

# how is this interface.

my $runner = Puncheur::Runner->new('PLite', {
    server => 'Starlet',
    port   => 1988,
}, {
    view => 'MT',
});
$runner->parse_options(@ARGV);
$runner->run;
