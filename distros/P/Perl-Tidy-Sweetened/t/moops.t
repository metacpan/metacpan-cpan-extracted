use lib 't/lib';
use Test::More;
use TidierTests;

run_test( <<'RAW', <<'TIDIED', 'Simple class defn', '',  );
class Person {
  has 'name' => (is => 'rw');
}
RAW
class Person {
    has 'name' => ( is => 'rw' );
}
TIDIED

run_test( <<'RAW', <<'TIDIED', 'Class defn with Moose', '1',  );
class Person using Moose {
  has 'name' => ( is => 'rw' );
}
RAW
class Person using Moose {
    has 'name' => ( is => 'rw' );
}
TIDIED

run_test( <<'RAW', <<'TIDIED', 'Class defn with version ', '',  );
class Person 1.2 {
  has 'name' => ( is => 'rw' );
}
RAW
class Person 1.2 {
    has 'name' => ( is => 'rw' );
}
TIDIED

run_test( <<'RAW', <<'TIDIED', 'Role defn', '',  );
role NamedThing {
  has 'balance' => ( is => 'rw' );
}
RAW
role NamedThing {
    has 'balance' => ( is => 'rw' );
}
TIDIED

run_test( <<'RAW', <<'TIDIED', 'Class with role', '',  );
class Person with NamedThing;
RAW
class Person with NamedThing;
TIDIED

run_test( <<'RAW', <<'TIDIED', 'Class that extends another', '',  );
class Employee extends Person {
   has job_title => (is=>'ro');
}
RAW
class Employee extends Person {
    has job_title => ( is => 'ro' );
}
TIDIED

run_test( <<'RAW', <<'TIDIED', 'Class that extends another with ::', '',  );
class Employee extends Person::Object {
   has job_title => (is=>'ro');
}
RAW
class Employee extends Person::Object {
    has job_title => ( is => 'ro' );
}
TIDIED

run_test( <<'RAW', <<'TIDIED', 'Class that extends and role', '1',  );
class Employee extends Person with Employment {
   has job_title => (is=>'ro');
}
RAW
class Employee extends Person with Employment {
    has job_title => ( is => 'ro' );
}
TIDIED

run_test( <<'RAW', <<'TIDIED', 'Class with lexical_has', '',  );
class Employee extends Person {
   lexical_has job_title => (is=>'ro');
}
RAW
class Employee extends Person {
    lexical_has job_title => ( is => 'ro' );
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

run_test( <<'RAW', <<'TIDIED', 'Class with attribute', '1',  );
class Person :mutable {
   lexical_has job_title => (is=>'ro');
}
RAW
class Person : mutable {
    lexical_has job_title => ( is => 'ro' );
}
TIDIED

done_testing;
