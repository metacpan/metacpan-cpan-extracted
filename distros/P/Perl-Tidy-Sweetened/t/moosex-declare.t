use lib 't/lib';
use Test::More;
use TidierTests;

run_test( <<'RAW', <<'TIDIED', 'Simple class defn', '',  );
class BankAccount {
  has 'balance' => ( is => 'rw' );
}
RAW
class BankAccount {
    has 'balance' => ( is => 'rw' );
}
TIDIED

run_test( <<'RAW', <<'TIDIED', 'Class defn with method', '',  );
class BankAccount {
    has 'balance' => ( is => 'rw' );
    method deposit (Num $amount){
    $self->inc_balance( $amount );
    }
}
RAW
class BankAccount {
    has 'balance' => ( is => 'rw' );

    method deposit (Num $amount) {
        $self->inc_balance($amount);
    }
}
TIDIED

run_test( <<'RAW', <<'TIDIED', 'Multipart class', '',  );
class A::Point {
    has $!x  is  ro  = 1 ;
}
RAW
class A::Point {
    has $!x is ro = 1;
}
TIDIED

run_test( <<'RAW', <<'TIDIED', 'Class with attrs (GH#5)', '',  );
class A::Point is dirty {
    has $!x  is  ro  = 1 ;
}
RAW
class A::Point is dirty {
    has $!x is ro = 1;
}
TIDIED

done_testing;
