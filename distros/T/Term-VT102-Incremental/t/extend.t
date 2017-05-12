#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

{
    package MyVT;
    use base 'Term::VT102';
}

{
    package MyVTI;
    use Moose;
    extends 'Term::VT102::Incremental';
    use constant vt_class => 'MyVT';
}

my $vti = MyVTI->new;

isa_ok($vti->vt, 'MyVT');

done_testing;
