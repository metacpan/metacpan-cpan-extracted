
#!/usr/bin/perl

use strict;
use warnings;
use PlayStation::MemoryCard;
use Test::Simple tests => 1;

sub getVersion {
    return $PlayStation::MemoryCard::VERSION;
}

ok ( getVersion());
