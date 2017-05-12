#!/usr/bin/env perl 

use strict;
use warnings;
BEGIN {
    push @INC, ('blib/lib', 'blib/arch');
}
use lib '../lib';
use blib;

use Parse::STDF;
use Test::More tests => 3;
note 'Testing Parse::STDF->far()';

my $s = Parse::STDF->new("data/test.stdf"); 

$s->get_record();
ok ( ($s->recname() eq "FAR"), 'FAR record found in data/test.stdf');
my $far = $s->far();
ok ( defined($far), 'FAR object defined');
ok ( $far->{CPU_TYPE} == 2, 'CPU_TYPE == 2'); 
