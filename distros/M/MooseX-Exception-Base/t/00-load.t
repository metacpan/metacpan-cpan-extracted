#!/usr/bin/perl

use strict;
use warnings;
use Test::More;
use Test::Warnings;

BEGIN {
    use_ok( 'MooseX::Exception::Base' );
    use_ok( 'MooseX::Exception::Base::Stringify' );
}

diag( "Testing MooseX::Exception::Base $MooseX::Exception::Base::VERSION, Perl $], $^X" );
done_testing();
