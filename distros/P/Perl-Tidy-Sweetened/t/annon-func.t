use lib 't/lib';
use Test::More;
use TidierTests;

run_test( <<'RAW', <<'TIDIED', 'Annoymous func (GH#4)', '1',  );
my $foo = func ($x,:$y) { $self->xyzzy($x,$y) };
RAW
my $foo = func ($x,:$y) { $self->xyzzy( $x, $y ) };
TIDIED

run_test( <<'RAW', <<'TIDIED', 'Annoymous func (GH#4)', '1',  );
my $foo = { bar => 1, baz => func ($x,:$y) { $self->xyzzy($x,$y) } };
RAW
my $foo = {
    bar => 1,
    baz => func ($x,:$y) { $self->xyzzy($x, $y) }
};
TIDIED

run_test( <<'RAW', <<'TIDIED', 'Annoymous sub', '',  );
my $foo = sub ( $x, $y ){
      $self->xyzzy( $x,$y )
  };
RAW
my $foo = sub ( $x, $y ) {
    $self->xyzzy( $x, $y );
};
TIDIED

done_testing;
