use strict;

use Test::More qw/no_plan/;

use Qstruct;


{

Qstruct::load_schema(q{
  qstruct TestSchema1Old {
    a @0 uint32;
    b @1 string;
    c @2 int8;
  }

  qstruct TestSchema1New {
    qa @0 uint32;
    qb @1 string;
    qc @2 int8;
    qd @3 int8;
    qe @4 blob;
  }
});


my $msg1 = TestSchema1Old->encode({
  a => 0xAABBCCDD,
  b => "roflcopter",
  c => 0x40,
});

my $obj1 = TestSchema1New->decode($msg1);

is($obj1->qa, 0xAABBCCDD);
is($obj1->qb, "roflcopter");
is($obj1->qc, 0x40);
is($obj1->qd, 0);
is($obj1->qe, "");


my $msg2 = TestSchema1New->encode({
  qa => 0x12345678,
  qb => "hello world what's up man?",
  qc => 0x28,
  qd => 127,
  qe => "XYZ"x1000,
});

my $obj2 = TestSchema1Old->decode($msg2);

is($obj2->a, 0x12345678);
is($obj2->b, "hello world what's up man?");
is($obj2->c, 0x28);

}



{

Qstruct::load_schema(q{
  qstruct TestSchema2Old {
    a @0 uint32[];
    b @1 uint8[11];
    c @2 string[];
  }

  qstruct AuxSchema2_1 {
    x @0 uint32;
    y @1 uint64;
  }

  qstruct AuxSchema2_2 {
    n @0 string;
    m @1 blob;
  }

  qstruct TestSchema2New {
    a @0 AuxSchema2_1[];
    b @1 uint8[11];
    c @2 AuxSchema2_2[];
  }
});

my $msg1 = TestSchema2Old->encode({
  a => [12345, 67890, 0xFFEEDDCC, 0],
  b => "\x01"x11,
  c => ["OMGOMG", "roflcopter"x1000],
});

my $obj = TestSchema2New->decode($msg1);

is($obj->a->len, 4);
is($obj->a->[0]->x, 12345);
is($obj->a->[0]->y, 0);
is($obj->a->[1]->x, 67890);
is($obj->a->[1]->y, 0);
is($obj->a->[2]->x, 0xFFEEDDCC);
is($obj->a->[2]->y, 0);
is($obj->a->[3]->x, 0);
is($obj->a->[3]->y, 0);

is($obj->b->raw, "\x01"x11);

is($obj->c->len, 2);
is($obj->c->[0]->n, "OMGOMG");
is($obj->c->[0]->m, "");
is($obj->c->[1]->n, "roflcopter"x1000);
is($obj->c->[1]->m, "");

}
