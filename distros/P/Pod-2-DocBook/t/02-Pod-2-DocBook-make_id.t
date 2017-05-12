#!/usr/bin/perl

use strict;
use warnings;

use Test::More 'no_plan';
#use Test::More tests => 10;

use FindBin qw($Bin);
use lib "$Bin/lib";

BEGIN {
    use_ok ( 'Pod::2::DocBook' ) or exit;
}

exit main();

sub main {
    my $parser = Pod::2::DocBook->new(
        'title' => '~!@#$$% pod file of M::O::Dule ""x'
    );
    
    is($parser->make_id('&txt&'), '_pod_file_of_M::O::Dule_x:txt', 'check id string characters replacement');
    is($parser->make_id('& txt&'), '_pod_file_of_M::O::Dule_x:_txt', 'check id string characters replacement');

    is($parser->make_uniq_id('abc'), '_pod_file_of_M::O::Dule_x:abc', 'check id string characters replacement');
    is($parser->make_uniq_id('abc'), '_pod_file_of_M::O::Dule_x:abc_i1', 'no duplicate ids');
    is($parser->make_uniq_id('abc'), '_pod_file_of_M::O::Dule_x:abc_i2', 'no duplicate ids');
    
    $parser->make_uniq_id('abc')
        foreach (1..10);
    is($parser->make_uniq_id('abc'), '_pod_file_of_M::O::Dule_x:abc_i13', 'no duplicate ids');


    # different base_id
    $parser = Pod::2::DocBook->new(
        'base_id' => 'some/file/somewhere.pm'
    );
    
    is($parser->make_uniq_id('SYNOPSIS'), 'some.file.somewhere.pm:SYNOPSIS', 'check id string characters replacement');
    
    return 0;
}

