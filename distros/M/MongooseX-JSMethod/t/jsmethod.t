use strict;
use warnings;

use Test::More tests => 6;

use lib "t/lib";
use_ok("MongooseX::JSMethod");
use_ok("Test");

my $obj = Test->new({name => "The answer", value => 42});

ok($obj->isa("Test"));

ok($obj->{sum}->isa("MongoDB::Code"));
is(length $obj->{sum}->code, 170);
ok($obj->can("sum"));
