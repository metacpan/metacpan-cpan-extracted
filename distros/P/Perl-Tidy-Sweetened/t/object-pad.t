use lib 't/lib';
use Test::More;
use TidierTests;

run_test( <<'RAW', <<'TIDIED', 'Simple class defn', '',  );
class Person{
field $eyes
}
RAW
class Person {
    field $eyes;
}
TIDIED

run_test( <<'RAW', <<'TIDIED', 'Class defn with signature', '',  );
class Person($){
field $eyes
}
RAW
class Person ($) {
    field $eyes;
}
TIDIED

run_test( <<'RAW', <<'TIDIED', 'Class defn with attributes', '',  );
class Person :Struct :repr(native){
field $eyes
}
RAW
class Person :Struct :repr(native) {
    field $eyes;
}
TIDIED

run_test( <<'RAW', <<'TIDIED', 'Class defn with version ', '',  );
class Person 1.2{
field @eyes = 2;
}
RAW
class Person 1.2 {
    field @eyes = 2;
}
TIDIED


run_test( <<'RAW', <<'TIDIED', 'Role defn', '',  );
role NamedThing {
  field 'balance';
}
RAW
role NamedThing {
    field 'balance';
}
TIDIED

run_test( <<'RAW', <<'TIDIED', 'Class with role', '',  );
class Person with NamedThing;
RAW
class Person with NamedThing;
TIDIED

run_test( <<'RAW', <<'TIDIED', 'Class that extends another', '',  );
class Employee :isa(Person) {
   field job_title;
}
RAW
class Employee :isa(Person) {
    field job_title;
}
TIDIED

run_test( <<'RAW', <<'TIDIED', 'Class with field with default value when omitted', '',  );
class Employee{
   field job_title  = 'employee';
}
RAW
class Employee {
    field job_title = 'employee';
}
TIDIED

run_test( <<'RAW', <<'TIDIED', 'Class with field with default value when empty', '',  );
class Employee{
   field job_title  ||= 'employee';
}
RAW
class Employee {
    field job_title ||= 'employee';
}
TIDIED

run_test( <<'RAW', <<'TIDIED', 'Class with field with default value when undefined', '',  );
class Employee{
   field job_title  //= 'employee';
}
RAW
class Employee {
    field job_title //= 'employee';
}
TIDIED

run_test( <<'RAW', <<'TIDIED', 'Class that extends another with ::', '',  );
class Employee  :isa(Person::Object)  {
   field job_title;
}
class Person  :does(ROLE)  {
   field $name;
}
RAW
class Employee :isa(Person::Object) {
    field job_title;
}

class Person :does(ROLE) {
    field $name;
}
TIDIED

run_test( <<'RAW', <<'TIDIED', 'Class defn with method', '',  );
class BankAccount {
    field 'balance'  = 0;
    method deposit (Num $amount){
    $self->inc_balance( $amount );
    }
}
RAW
class BankAccount {
    field 'balance' = 0;

    method deposit (Num $amount) {
        $self->inc_balance($amount);
    }
}
TIDIED

run_test( <<'RAW', <<'TIDIED', 'Class defn with field, :param, method, signatures', '',  );
class Point {
field  $x :param = 0;
field $y  :param  =  0;
 
method move ($dX, $dY) {
$x += $dX;
$y += $dY;
}
method describe () {
print "A point at ($x, $y)\n";
}
}
RAW
class Point {
    field $x :param = 0;
    field $y :param = 0;

    method move ($dX, $dY) {
        $x += $dX;
        $y += $dY;
    }

    method describe () {
        print "A point at ($x, $y)\n";
    }
}
TIDIED


done_testing;
