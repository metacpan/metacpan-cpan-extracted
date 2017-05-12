
use strict;
use warnings;
use Test::Needs qw( Moo );
use Test::More tests => 3;

require Moo;
# ABSTRACT: Basic moo test
local $@;
my $failed = 1;
eval q[{
  package Sample;
  use Moo;
  use MooX::Lsub;

  lsub "method"    => sub { 5 };
  lsub "methodtwo" => sub { $_[0]->method + 1 };
  undef $failed;
}];
ok( !$failed, 'No Exceptions' ) or diag $@;
is( Sample->new()->method,    5, 'Injected lazy method returns value' );
is( Sample->new()->methodtwo, 6, 'Injected lazy method returns value' );
