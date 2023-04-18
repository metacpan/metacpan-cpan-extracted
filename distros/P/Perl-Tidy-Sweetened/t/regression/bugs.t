use lib 't/lib';
use Test::More;
use TidierTests;

run_test( <<'RAW', <<'TIDIED', 'RT#83511 - () { rewriten as { ()', '',  );
method name1 () {
}
method name2(){
}
RAW
method name1 () {
}

method name2 () {
}
TIDIED

run_test( <<'RAW', <<'TIDIED', 'RT#83511 - same for func', '',  );
func name1 () {
}
func name2(){
}
RAW
func name1 () {
}

func name2 () {
}
TIDIED

run_test( <<'RAW', <<'TIDIED', 'RT#84868 - prototype with ()', '',  );
func nm (Any $a where qr{(foo)}) {
}
func name2(){
}
RAW
func nm (Any $a where qr{(foo)}) {
}

func name2 () {
}
TIDIED

run_test( <<'RAW', <<'TIDIED', 'RT#84868 - prototype with multiple ()', '',  );
func nm (Any $a where qr{(f)(o)}) {
}
func name2(){
}
RAW
func nm (Any $a where qr{(f)(o)}) {
}

func name2 () {
}
TIDIED

run_test( <<'RAW', <<'TIDIED', 'RT#84868 - Multiple line signatures', '',  );
method nm (Str $bar,
           Int $foo where { $_>(0) }
          ) {
}
RAW
method nm (Str $bar,
           Int $foo where { $_>(0) }
          ) {
}
TIDIED

run_test( <<'RAW', <<'TIDIED', 'RT#84868 - Multiple line signatures w/ comment', '',  );
method nm (Str $bar,
           Int $foo where { $_ > (0) }
          ) {   # Fun stuff
}
RAW
method nm (Str $bar,
           Int $foo where { $_ > (0) }
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
method foo returns(Bool) {
}
RAW
method foo returns(Bool) {
}
TIDIED

run_test( <<'RAW', <<'TIDIED', 'RT#94633 - class WORD::WORD {}', '',  );
class WORD::WORD {
}

class WORD {
}

sub mysub:ATTRIBUTE {
}
RAW
class WORD::WORD {
}

class WORD {
}

sub mysub : ATTRIBUTE {
}
TIDIED

run_test( <<'RAW', <<'TIDIED', 'RT#106398 - Long single line subs', '',  );
sub test ($param) {$param->test->that->breaks->perltidysweetened}
RAW
sub test ($param) { $param->test->that->breaks->perltidysweetened }
TIDIED

run_test( <<'RAW', <<'TIDIED', 'RT#106398 - Long single line subs w/o params', '',  );
sub test {$param->this->is->a->test->that->breaks->perltidysweetened}
RAW
sub test {
    $param->this->is->a->test->that->breaks
      ->perltidysweetened;
}
TIDIED

run_test( <<'RAW', <<'TIDIED', 'RT#106464 - MooseX::Role::Parameterized', '',  );
method   _path  =>  sub  {$path};
RAW
method _path => sub { $path };
TIDIED

done_testing;
