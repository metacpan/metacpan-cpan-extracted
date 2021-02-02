use lib 't/lib';
use Test::More;
use TidierTests qw(run_test $indent_tc);

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

run_test( <<'RAW', <<'TIDIED', 'Simple methods with underscores ', '',  );
method name_1{
}
RAW
method name_1 {
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

run_test( <<'RAW', <<'TIDIED', 'Functions', '',  );
func morning ($name) {
    say "Hi $name";
}
RAW
func morning ($name) {
    say "Hi $name";
}
TIDIED

run_test( <<'RAW', <<'TIDIED', 'Functions with underscore in name', '',  );
func morn_ing ($name) {
    say "Hi $name";
}
RAW
func morn_ing ($name) {
    say "Hi $name";
}
TIDIED

run_test( <<'RAW', <<'TIDIED', 'Functions with multi-line paramaters', '',  );
func morning ( Str :$name,
               Int :$age,
             ) {
    say "Hi $name";
}
RAW
func morning ( Str :$name,
               Int :$age,
             ) {
    say "Hi $name";
}
TIDIED

run_test( <<'RAW', <<"TIDIED", 'With trailing comments', '',  );
method name1{# Trailing comment
}
sub name2{  # Trailing comment
}
RAW
method name1 {    # Trailing comment
}

sub name2 {$indent_tc# Trailing comment
}
TIDIED

run_test( <<'RAW', <<"TIDIED", 'With attribs trailing comments', '',  );
method name1 :Attrib(Arg) {# comment
}
sub name2 :Attrib(Arg) {  # comment
}
RAW
method name1 : Attrib(Arg) {    # comment
}

sub name2 : Attrib(Arg) {$indent_tc# comment
}
TIDIED

done_testing;
