use lib 't/lib';
use Test::More;
use TidierTests;

run_test( <<'RAW', <<'TIDIED', 'Two simple args', '',  );
sub foo ($left, $right) {
    return $left + $right;
}
RAW
sub foo ($left, $right) {
    return $left + $right;
}
TIDIED

run_test( <<'RAW', <<'TIDIED', 'Ignore one arg ', '',  );
sub foo ($first, $, $third) {
    return "first=$first, third=$third";
}
RAW
sub foo ($first, $, $third) {
    return "first=$first, third=$third";
}
TIDIED

run_test( <<'RAW', <<'TIDIED', 'Default value ', '',  );
sub foo ($left, $right = 0) {
    return $left + $right;
}
RAW
sub foo ($left, $right = 0) {
    return $left + $right;
}
TIDIED

run_test( <<'RAW', <<'TIDIED', 'More complicated default ', '',  );
my $auto_id = 0;

sub foo ($thing, $id = $auto_id++) {
    print "$thing has ID $id";
}
RAW
my $auto_id = 0;

sub foo ($thing, $id = $auto_id++) {
    print "$thing has ID $id";
}
TIDIED

run_test( <<'RAW', <<'TIDIED', 'Ignored default value', '',  );
sub foo ($thing, $ = 1) {
    print $thing;
}
RAW
sub foo ($thing, $ = 1) {
    print $thing;
}
TIDIED

run_test( <<'RAW', <<'TIDIED', 'Really ignore default value', '',  );
sub foo ($thing, $ =) {
    print $thing;
}
RAW
sub foo ($thing, $ =) {
    print $thing;
}
TIDIED

run_test( <<'RAW', <<'TIDIED', 'Slurpy', '',  );
sub foo ($filter, @inputs) {
    print $filter->($_) foreach @inputs;
}
RAW
sub foo ($filter, @inputs) {
    print $filter->($_) foreach @inputs;
}
TIDIED

run_test( <<'RAW', <<'TIDIED', 'Ignored slurpy', '',  );
sub foo ($thing, @) {
    print $thing;
}
RAW
sub foo ($thing, @) {
    print $thing;
}
TIDIED

run_test( <<'RAW', <<'TIDIED', 'Hash as an arg', '',  );
sub foo ($filter, %inputs) {
    print $filter->($_, $inputs{$_})
        foreach sort keys %inputs;
}
RAW
sub foo ($filter, %inputs) {
    print $filter->( $_, $inputs{$_} )
      foreach sort keys %inputs;
}
TIDIED

run_test( <<'RAW', <<'TIDIED', 'Ignored hash', '',  );
sub foo ($thing, %) {
    print $thing;
}
RAW
sub foo ($thing, %) {
    print $thing;
}
TIDIED

run_test( <<'RAW', <<'TIDIED', 'Empty args', '',  );
sub foo () {
    return 123;
}
RAW
sub foo () {
    return 123;
}
TIDIED

run_test( <<'RAW', <<'TIDIED', 'Args and a prototype', '',  );
sub foo :prototype($$) ($left, $right) {
    return $left + $right;
}
RAW
sub foo : prototype($$) ( $left, $right ) {
    return $left + $right;
}
TIDIED

run_test( <<'RAW', <<'TIDIED', 'Empty hash as default value', '',  );
sub foo( $x, $y = {} ){
    return $x+$y;
}
RAW
sub foo ( $x, $y = {} ) {
    return $x + $y;
}
TIDIED

SKIP: {
skip 'Perl::Tidy version 20160301 has a bug that impacts this test', 2
  if $Perl::Tidy::VERSION eq '20160301';
run_test( <<'RAW', <<'TIDIED', '5.20 annoymous sub', '',  );
$j->map(
  sub ( $x, $ = 0 ) {
   $x->method();
  }
);
RAW
$j->map(
    sub ( $x, $ = 0 ) {
        $x->method();
    }
);
TIDIED
}

run_test( <<'RAW', <<'TIDIED', '5.20 annoymous sub 2 ', '',  );
my $x = sub ( $x, $ = 0 ) {
   $x->method();
  };
RAW
my $x = sub ( $x, $ = 0 ) {
    $x->method();
};
TIDIED

run_test( <<'RAW', <<'TIDIED', 'Simple declaraion and use', '',  );
use strict;
use warnings;
sub foo ( $left, $right ) {
    return $left + $right;
}
say foo( $a, $b );
RAW
use strict;
use warnings;

sub foo ( $left, $right ) {
    return $left + $right;
}
say foo( $a, $b );
TIDIED

done_testing;
