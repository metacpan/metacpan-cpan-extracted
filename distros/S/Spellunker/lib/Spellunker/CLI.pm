package Spellunker::CLI;
use strict;
use warnings;
use utf8;

use Spellunker;

sub new {
    my $class = shift;
    bless {}, $class;
}

sub run {
    my $self = shift;

    my $engine = Spellunker->new();
    while (<>) {
        my @words = $engine->check_line($_);
        print "Bad: $_ at line $.\n" for @words;
    }
}

1;

