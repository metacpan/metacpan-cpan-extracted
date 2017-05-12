#!/usr/bin/env perl
use strict;
use warnings;
use 5.8.0;
BEGIN { $ENV{PERL_RL} = 'EditLine' }
use Term::ReadLine;
use Data::Dumper;

my $t = Term::ReadLine->new('yaperlsh');
print "Using: " . $t->ReadLine, "\n";
while (defined($_ = $t->readline('perl> '))) {
    print ddf(eval($_)), "\n";
    warn $@ if $@;
    $t->addhistory($_) if /\S/;
}

sub ddf {
    local $Data::Dumper::Terse = 1;
    Data::Dumper::Dumper(@_)
}
