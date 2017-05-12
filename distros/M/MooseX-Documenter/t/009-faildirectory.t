
use Test::More tests => 2;
use Test::Exception;
use strict;
use warnings;
BEGIN { use_ok('MooseX::Documenter') }

throws_ok {
  MooseX::Documenter->new( "randomstringthatshouldnotexist/", 'basicsimple' );
}
qr/Directory can not/, 'Correctly threw error with bad directory';
