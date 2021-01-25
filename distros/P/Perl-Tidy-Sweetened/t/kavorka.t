use lib 't/lib';
use Test::More;
use TidierTests qw(run_test $indent);

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

run_test( <<'RAW', <<'TIDIED', 'Simple classmethod usage', '',  );
classmethod name1{
}
sub name2{
}
RAW
classmethod name1 {
}

sub name2 {
}
TIDIED

run_test( <<'RAW', <<'TIDIED', 'Simple classmethods with underscores ', '',  );
classmethod name_1{
}
RAW
classmethod name_1 {
}
TIDIED

run_test( <<'RAW', <<'TIDIED', 'classmethod with signature', '',  );
classmethod name1 (class: $that) {
}
classmethod name2( :$arg1, :$arg2 ){
}
sub name3 {}
RAW
classmethod name1 (class: $that) {
}

classmethod name2 ( :$arg1, :$arg2 ) {
}
sub name3 { }
TIDIED

run_test( <<'RAW', <<'TIDIED', 'Simple objectmethod usage', '',  );
objectmethod name1{
}
sub name2{
}
RAW
objectmethod name1 {
}

sub name2 {
}
TIDIED

run_test( <<'RAW', <<'TIDIED', 'Simple objectmethods with underscores ', '',  );
objectmethod name_1{
}
RAW
objectmethod name_1 {
}
TIDIED

run_test( <<'RAW', <<'TIDIED', 'objectmethod with signature', '',  );
objectmethod name1 (class: $that) {
}
objectmethod name2( :$arg1, :$arg2 ){
}
sub name3 {}
RAW
objectmethod name1 (class: $that) {
}

objectmethod name2 ( :$arg1, :$arg2 ) {
}
sub name3 { }
TIDIED

run_test( <<'RAW', <<'TIDIED', 'Functions', '',  );
fun morning ($name) {
    say "Hi $name";
}
RAW
fun morning ($name) {
    say "Hi $name";
}
TIDIED

run_test( <<'RAW', <<'TIDIED', 'Functions with underscore in name', '',  );
fun morn_ing ($name) {
    say "Hi $name";
}
RAW
fun morn_ing ($name) {
    say "Hi $name";
}
TIDIED

run_test( <<'RAW', <<'TIDIED', 'Functions with multi-line paramaters', '',  );
fun morning ( Str :$name,
              Int :$age,
            ) {
    say "Hi $name";
}
RAW
fun morning ( Str :$name,
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

sub name2 {$indent# Trailing comment
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

sub name2 : Attrib(Arg) {$indent# comment
}
TIDIED

run_test( <<'RAW', <<'TIDIED', 'but begin', '',  );
method foo () but begin { 'bar' }
RAW
method foo () but begin { 'bar' }
TIDIED

run_test( <<'RAW', <<'TIDIED', 'around modifiers', '',  );
around  foo(Str :$bar, Str :$baz?)   {
say "hi";
}
RAW
around foo (Str :$bar, Str :$baz?) {
    say "hi";
}
TIDIED

run_test( <<'RAW', <<'TIDIED', 'before modifiers', '',  );
before  foo(Str :$bar, Str :$baz?)   {
say "hi";
}
RAW
before foo (Str :$bar, Str :$baz?) {
    say "hi";
}
TIDIED

run_test( <<'RAW', <<'TIDIED', 'after modifiers', '',  );
after foo(Str :$bar, Str :$baz?)   {
say "hi";
}
RAW
after foo (Str :$bar, Str :$baz?) {
    say "hi";
}
TIDIED

done_testing;
