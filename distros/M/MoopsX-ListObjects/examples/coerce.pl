use MoopsX::ListObjects;

class Foo :rw {
  has bar => ( isa => ArrayObj, coerce => 1 );

  has baz => ( isa => HashObj, coerce => 1 );
}

my $foo = Foo->new;

say "-> ArrayObj values:";
$foo->bar([1 .. 5]);
$foo->bar->map(
  sub { say $_ }
);

say "-> sliced() HashObj values:";
$foo->baz( +{ one => 1, two => 2, three => 3 } );
$foo->baz->sliced(qw/one three/)->values->map(
  sub { say $_ }
);
