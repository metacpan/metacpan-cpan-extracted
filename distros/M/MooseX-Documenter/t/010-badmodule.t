
use Test::More tests => 2;
use Test::Exception;
use strict;
use warnings;
use FindBin;
BEGIN { use_ok('MooseX::Documenter') }

throws_ok {
  MooseX::Documenter->new( "$FindBin::Bin/samplemoose/", 'badmodule' );
}
qr/This module is bad/, 'simple usage of example works.';

