#!/usr/bin/perl

use strict;
use warnings;
use lib 't/lib';

use Test::More;

plan skip_all => 'namespace::autoclean not available'
    unless eval { require namespace::autoclean; 1 };

require AutoCleanWidget;

my $widget = new_ok('AutoCleanWidget');
can_ok($widget, qw<object_id object_uuid>);

done_testing;
