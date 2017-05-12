#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'String::PictureFormat' ) || print "Bail out!\n";
}

diag( "Testing String::PictureFormat $String::PictureFormat::VERSION, Perl $], $^X" );

__END__
