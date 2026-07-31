#!perl
use 5.022;
use strict;
use warnings;
use Test::More;
use SION;

# exports
can_ok 'main', qw(encode_sion decode_sion);
ok !main->can('true'), 'true is not exported by default';
{
    package ExportOk;
    SION->import(qw(true false is_bool));
}
can_ok 'ExportOk', qw(true false is_bool);
ok SION::is_bool( SION::true() ),   'is_bool(true)';
ok SION::is_bool( SION::false() ),  'is_bool(false)';
ok !SION::is_bool(1),               '1 is not a boolean';
ok !SION::is_bool('true'),          '"true" is not a boolean';

# constructor and chaining
my $s = SION->new;
isa_ok $s, 'SION';
for my $method (
    qw( utf8 ascii indent space_before space_after canonical
        allow_nonref allow_blessed convert_blessed pretty
        max_depth indent_length )
  )
{
    isa_ok + SION->new->$method, 'SION', "->$method returns \$self";
}

# accessors
is $s->get_utf8,      0, 'get_utf8 default';
is $s->utf8->get_utf8, 1, 'utf8 sets';
is $s->utf8(0)->get_utf8, 0, 'utf8(0) clears';
is $s->get_max_depth, 512, 'default max_depth';
is $s->max_depth(3)->get_max_depth, 3, 'max_depth(3)';
is $s->get_indent_length, 4, 'default indent_length';

# pretty toggles the three
my $p = SION->new->pretty;
ok $p->get_indent && $p->get_space_before && $p->get_space_after,
  'pretty enables indent, space_before, space_after';
$p->pretty(0);
ok !( $p->get_indent || $p->get_space_before || $p->get_space_after ),
  'pretty(0) disables them';

# allow_nonref
{
    my $strict = SION->new->allow_nonref(0);
    ok !eval { $strict->encode(42);     1 }, 'encode nonref croaks';
    ok !eval { $strict->decode('42');   1 }, 'decode nonref croaks';
    is $strict->encode( [42] ), '[42]', 'arrays are fine';
    is( SION->new->encode(42), '42', 'allow_nonref on by default' );
    is( SION->new->decode('42'), 42, 'allow_nonref on by default (decode)' );
}

# max_depth
{
    my $shallow = SION->new->max_depth(1);
    is_deeply $shallow->decode('[1]'), [1], 'depth 1 ok';
    ok !eval { $shallow->decode('[[1]]'); 1 }, 'decode beyond max_depth croaks';
    like $@, qr/nesting/, '... mentioning nesting';
    is $shallow->encode( [1] ), '[1]', 'encode depth 1 ok';
    ok !eval { $shallow->encode( [ [1] ] ); 1 },
      'encode beyond max_depth croaks';
}

# self-referential structure hits max_depth instead of looping forever
{
    my $loop = [];
    push @$loop, $loop;
    ok !eval { SION->new->encode($loop); 1 }, 'circular structure croaks';
}

# functional interface round trip
{
    my $data = { a => [ 1, 2.5, 'three' ], b => undef };
    is_deeply decode_sion( encode_sion($data) ), $data,
      'encode_sion/decode_sion round trip';
}

# version
like $SION::VERSION, qr/^\d/, 'VERSION is set';

done_testing;
