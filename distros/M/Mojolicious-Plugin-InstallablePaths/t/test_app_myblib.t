use strict;
use warnings;

use lib 't/myblib/lib';

use Test::More;
use Test::Mojo;

use MyTest::App;
my $app = MyTest::App->new;

my $t = Test::Mojo->new($app);
$t->get_ok('/')
  ->status_is(200)
  ->text_is( p => 'Hello World' );

done_testing;

