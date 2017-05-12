use strict;

use Test::More;
use Qstruct;

eval {
  require Test::ZeroCopy;
};

if ($@) {
  plan skip_all => "Test::ZeroCopy not installed";
} else {
  plan 'no_plan';
}


Qstruct::load_schema(q{
  qstruct MyObj {
    str @0 string;
    str2 @1 string;
    strs @2 string[];
    blob @3 blob;
    blobs @4 blob[];
    hash @5 uint8[32];
  }

  qstruct MyObjWrapper {
    wobj @0 MyObj;
    wobjs @1 MyObj[];
  }
});


{

my $enc = MyObj->build
            ->str("hello world")
            ->str2("hello world"x100)
            ->strs(["HELLLLLLLLLLLLLLLLLLLLLLLLLLO!", "roflcopter"])
            ->blob("Q"x4096)
            ->blobs(["\x00", "Z"x100000])
            ->hash("Q"x32)
            ->encode;

my $obj = MyObj->decode($enc);

{
  $obj->str(my $val);
  Test::ZeroCopy::is_zerocopy($val, $enc);
}

{
  $obj->str2(my $val);
  Test::ZeroCopy::is_zerocopy($val, $enc);
}

{
  $obj->blob(my $val);
  Test::ZeroCopy::is_zerocopy($val, $enc);
}

{
  $obj->hash->raw(my $val);
  Test::ZeroCopy::is_zerocopy($val, $enc);
  my $val2 = $obj->hash->raw;
  Test::ZeroCopy::isnt_zerocopy($val2, $enc);
  is($val, $val2);
}

{
  my $blobs = $obj->blobs;
  for(my $i=0; $i < $blobs->len; $i++) {
    $blobs->get($i, my $val);
    Test::ZeroCopy::is_zerocopy($val, $enc);
    my $val2 = $blobs->get($i);
    Test::ZeroCopy::isnt_zerocopy($val2, $enc);
    is($val, $val2);
  }
}

{
  $obj->strs->foreach(sub {
    Test::ZeroCopy::is_zerocopy($_[0], $enc);
  });
}

}


### Nested

{

my $enc = MyObjWrapper->encode({
            wobj => { str => "HELLO", },
            wobjs => [ { str => "what up"x20 }, { str => "asdf" }, ],
          });

my $obj = MyObjWrapper->decode($enc);

{
  $obj->wobj->str(my $val);
  Test::ZeroCopy::is_zerocopy($val, $enc);
}

{
  $obj->wobjs->[0]->str(my $val);
  Test::ZeroCopy::is_zerocopy($val, $enc);
  $obj->wobjs->foreach(sub {
    $_[0]->str(my $val);
    Test::ZeroCopy::is_zerocopy($val, $enc);
  });
}

}


### Main message data goes out of scope

{
  my $ref_to_val;

  {
    my $enc = MyObj->encode({
                str => "HELLO WORLD",
              });

    my $obj = MyObj->decode($enc);

    $obj->str(my $val);
    Test::ZeroCopy::is_zerocopy($val, $enc);

    $ref_to_val = \$val;
    Test::ZeroCopy::is_zerocopy($$ref_to_val, $enc);
  }

  is($$ref_to_val, "HELLO WORLD", 'enc/obj out of scope');
}
