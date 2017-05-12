#!/usr/bin/perl
use strict;
use warnings;
use SVN::Dump;

my $dump = SVN::Dump->new({file => @ARGV ? $ARGV[0] : '-'});

while ( my $rec = $dump->next_record() ) {
    print $rec->as_string();
}

