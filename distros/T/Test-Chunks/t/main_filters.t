use Test::Chunks tests => 5;

is(next_chunk->xxx, "I lmike mike\n");
is(next_chunk->xxx, "I like mikey");
is(next_chunk->xxx, "123\n");
is(next_chunk->xxx, "I like MIKEY");

run_is xxx => 'yyy';

sub mike1 {
    s/ike/mike/g;
};

sub mike2 {
    $_ = 'I like mikey';
    return 123;
};

sub mike3 {
    s/ike/heck/;
    return "123\n";
}

sub mike4 {
    $_ = 'I like MIKEY';
    return;
};

sub yyy { s/x/y/g }

__DATA__
===
--- xxx mike1
I like ike

===
--- xxx mike2
I like ike

===
--- xxx mike3
I like ike

===
--- xxx mike4
I like ike

===
--- xxx lines yyy
xxx xxx
  xxx xxx
--- yyy
yyy yyy
  yyy yyy
