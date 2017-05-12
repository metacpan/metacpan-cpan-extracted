#!/usr/bin/perl
use strict;
use warnings;

use Test::More tests => 1;

use_ok('Module::Packaged::Report');

__END__
{
    my $mpr = Module::Packaged::Report->new(test => 1);
    isa_ok($mpr, 'Module::Packaged::Report');
}

{
    my $mpr = Module::Packaged::Report->new(real => 1);
    isa_ok($mpr, 'Module::Packaged::Report');
}

