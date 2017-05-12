use lib 't/lib';
use Test::More;
use TidierTests;

run_test( <<'RAW', <<'TIDIED', 'Simple method usage', '',  );
method name1{
}
sub name2{
}
RAW
method name1 {
}

sub name2 {
}
TIDIED

run_test( <<'RAW', <<'TIDIED', 'Method with signature', '',  );
method name1 (class: $that) {
}
method name2( :$arg1, :$arg2 ){
}
sub name3 {}
RAW
method name1 (class: $that) {
}

method name2 ( :$arg1, :$arg2 ) {
}
sub name3 { }
TIDIED

run_test( <<'RAW', <<'TIDIED', 'With paramater typing', '',  );
method morning (Str $name) {
    $self->say("Hi ${name}!");
}
RAW
method morning (Str $name) {
    $self->say("Hi ${name}!");
}
TIDIED

run_test( <<'RAW', <<'TIDIED', 'With params with constraints', '',  );
method hello (:$age where { $_ > 0 }) {
}
RAW
method hello (:$age where { $_ > 0 }) {
}
TIDIED

run_test( <<'RAW', <<'TIDIED', 'Multiple line signatures', '',  );
method name1 (Str $bar,
              Int $foo where { $_ > 0 }
             ) {
}
RAW
method name1 (Str $bar,
              Int $foo where { $_ > 0 }
             ) {
}
TIDIED

run_test( <<'RAW', <<'TIDIED', 'Multiple line signatures w/ comment ', '',  );
method name1 (Str $bar,
              Int $foo where { $_ > 0 }
             ) {   # Fun stuff
}
RAW
method name1 (Str $bar,
              Int $foo where { $_ > 0 }
             ) {    # Fun stuff
}
TIDIED

run_test( <<'RAW', <<'TIDIED', 'RT#85076 - handle returns() with signature ', '',  );
method foo ( File :$file! ) returns(Bool) {
}
RAW
method foo ( File :$file! ) returns(Bool) {
}
TIDIED

run_test( <<'RAW', <<'TIDIED', 'RT#85076 - handle returns()', '',  );
method foo returns (Bool) {
}
RAW
method foo returns (Bool) {
}
TIDIED

done_testing;
