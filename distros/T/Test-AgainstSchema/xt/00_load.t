#!/usr/bin/perl

use 5.008;
use strict;
use warnings;
use vars qw(@MODULES);

use Test::More;

our $VERSION = '1.000';

BEGIN
{
    @MODULES = qw(Test::AgainstSchema Test::AgainstSchema::XML);

    plan tests => scalar @MODULES;
}

for (@MODULES)
{
    use_ok($_);
}

exit 0;
