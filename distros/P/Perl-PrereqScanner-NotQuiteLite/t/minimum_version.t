use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/..";
use Test::More;
BEGIN { $ENV{PERL_PSNQL_MINVER} = 1 }
use t::Util;

test('say', <<'END', {perl => '5.010', feature => 0});
use feature 'say';
say "hello";
END

test('yada yada yada', <<'END', {perl => '5.012'});
...
END

test('package PACKAGE VERSION', <<'END', {perl => '5.012'});
package Foo 3.14;
END

test('package PACKAGE { }', <<'END', {perl => '5.014'});
package Foo { }
END

test('package PACKAGE { }', <<'END', {perl => '5.014'});
package Foo { foo(); }
END

test('package PACKAGE VERSION { }', <<'END', {perl => '5.014'});
package Foo 3.14 { }
END

test('package PACKAGE VERSION { }', <<'END', {perl => '5.014'});
package Foo 3.14 { foo(); }
END

test('package PACKAGE VERSION { }', <<'END', {perl => '5.014'});
package Foo v0.0.1 { }
END

test('package PACKAGE VERSION { }', <<'END', {perl => '5.014'});
package Foo v0.0.1 { foo() }
END

test('use feature', <<'END', {perl => '5.010', feature => 0});
use feature ();
END

test('use feature unicode_strings', <<'END', {perl => '5.012', feature => 0});
use feature "unicode_strings";
END

test('use feature unicode_eval', <<'END', {perl => '5.016', feature => 0});
use feature "unicode_eval";
END

test('use feature current_sub', <<'END', {perl => '5.016', feature => 0});
use feature "current_sub";
END

test('use feature fc', <<'END', {perl => '5.016', feature => 0});
use feature "fc";
END

test('use feature lexical_subs', <<'END', {perl => '5.018', feature => 0});
use feature "lexical_subs";
END

test('use feature :5.14', <<'END', {perl => '5.014', feature => 0});
use feature ":5.14";
END

test('use feature :5.16', <<'END', {perl => '5.016', feature => 0});
use feature ":5.16";
END

test('use feature :5.18', <<'END', {perl => '5.018', feature => 0});
use feature ":5.18";
END

test('defined_or', <<'END', {perl => '5.010'});
1 // 2;
END

test('defined_or', <<'END', {perl => '5.010'});
$x //= 2;
END

test('smartmatch', <<'END', {perl => '5.010'});
1 ~~ 2;
END

test('%+', <<'END', {perl => '5.010'});
%+;
END

test('$+{}', <<'END', {perl => '5.010'});
$+{"a"};
END

test('@+{}', <<'END', {perl => '5.010'});
@+{"a"};
END

test('%-', <<'END', {perl => '5.010'});
%-;
END

test('$-{}', <<'END', {perl => '5.010'});
$-{"a"};
END

test('@-{}', <<'END', {perl => '5.010'});
@-{"a"};
END

test('when', <<'END', {perl => '5.010', feature => 0});
use feature 'switch';
when (1) { }
END

test('when', <<'END', {perl => '5.010', feature => 0});
use feature 'switch';
when ([1,2,3]) { }
END

# TODO: sideff when is actually since 5.012
todo_test('sideff when', <<'END', {perl => '5.012', feature => 0});
use feature 'switch';
print "$_," when [1,2,3];
END

test('when', <<'END', {perl => '5.010', feature => 0});
use feature 'switch';
sub foo {}
warn; when (1) { foo(); }
END

test('split //', <<'END', {});
split // => 3;
END

test('split //', <<'END', {});
split //, 3;
END

test('split //', <<'END', {});
split //;
END

test('split //', <<'END', {});
(split //);
END

test('split //', <<'END', {});
{split //};
END

test('split //', <<'END', {});
{split(//)};
END

test('if //', <<'END', {});
if (//) { };
END

test('map //', <<'END', {});
map //, 3;
END

test('grep //', <<'END', {});
grep //, 3;
END

test('time // time', <<'END', {perl => '5.010'});
time // time;
END

test('->$*', <<'END', {perl => '5.020'});
$sref->$*;
END

test('->@*', <<'END', {perl => '5.020'});
$aref->@*;
END

test('->%*', <<'END', {perl => '5.020'});
$href->%*;
END

test('->&*', <<'END', {perl => '5.020'});
$cref->&*;
END

test('->**', <<'END', {perl => '5.020'});
$gref->**;
END

test('->$#*', <<'END', {perl => '5.020'});
$aref->$#*;
END

test('->*{}', <<'END', {perl => '5.020'});
$gref->*{ $slot };
END

test('->@[]', <<'END', {perl => '5.020'});
$aref->@[ @_ ];
END

test('->@[]', <<'END', {perl => '5.020'});
sub foo {}
$aref->@[ foo() ];
END

test('->@{}', <<'END', {perl => '5.020'});
$href->@{ @_ };
END

test('->@{}', <<'END', {perl => '5.020'});
sub foo {}
$href->@{ foo() };
END

test('->%[]', <<'END', {perl => '5.020'});
$aref->%[ @_ ];
END

test('->%[]', <<'END', {perl => '5.020'});
sub foo {}
$aref->%[ foo() ];
END

test('->%{}', <<'END', {perl => '5.020'});
$href->%{ @_ };
END

test('->%{}', <<'END', {perl => '5.020'});
sub foo {}
$href->%{ foo() };
END

test('proto', <<'END', {});
no feature 'signatures';
sub mylink ($$)        { foo(); }
sub myvec ($$$)        { foo(); }
sub myindex ($$;$)     { foo(); }
sub mysyswrite ($$$;$) { foo(); }
sub myreverse (@)      { foo(); }
sub myjoin ($@)        { foo(); }
sub mypop (\@)         { foo(); }
sub mysplice (\@$$@)   { foo(); }
sub mykeys (\[%@])     { foo(); }
sub myopen (*;$)       { foo(); }
sub mypipe (**)        { foo(); }
sub mygrep (&@)        { foo(); }
sub myrand (;$)        { foo(); }
sub mytime ()          { foo(); }
END

test('Catalyst controllers', <<'END', {'base' => 0, 'Catalyst::Controller' => 0});
use base 'Catalyst::Controller';
sub my_handles : Path('handles') { ... }
sub my_handles : Local { ... }
sub my_handles : Regex('^handles') { ... }
sub index :Path :Args(0) { ... }
sub root : Chained('/') PathPart('/cd') CaptureArgs(1) {
    my ($self, $c, $cd_id) = @_;
    $c->stash->{cd_id} = $cd_id;
    $c->stash->{cd} = $self->model('CD')->find_by_id($cd_id);
}
END

test('signatures', <<'END', {perl => '5.020', feature => 0});
use feature 'signatures';
sub foo :lvalue ($a, $b = 1, @c) { ... }
END

test('signatures', <<'END', {perl => '5.020', feature => 0});
use feature 'signatures';
sub foo ($left, $right) {
    return $left + $right;
}
END

test('signatures', <<'END', {perl => '5.020', feature => 0});
use feature 'signatures';
sub foo ($first, $, $third) {
    return "first=$first, third=$third";
}
END

test('signatures', <<'END', {perl => '5.020', feature => 0});
use feature 'signatures';
sub foo ($left, $right = 0) {
    return $left + $right;
}
END

test('signatures', <<'END', {perl => '5.020', feature => 0});
use feature 'signatures';
sub foo ($first_name, $surname, $nickname = $first_name) {
    print "$first_name $surname is known as \"$nickname\"";
}
END

test('signatures', <<'END', {perl => '5.020', feature => 0});
use feature 'signatures';
sub foo ($thing, $=) {
    print $thing;
}
END

test('signatures', <<'END', {perl => '5.020', feature => 0});
use feature 'signatures';
sub foo ($filter, @inputs) {
    print $filter->($_) foreach @inputs;
}
END

test('signatures', <<'END', {perl => '5.020', feature => 0});
use feature 'signatures';
sub foo ($thing, @) {
    print $thing;
}
END

test('signatures', <<'END', {perl => '5.020', feature => 0});
use feature 'signatures';
sub foo ($filter, %inputs) {
    print $filter->($_, $inputs{$_}) foreach sort keys %inputs;
}
END

test('signatures', <<'END', {perl => '5.020', feature => 0});
use feature 'signatures';
sub foo ($thing, %) {
    print $thing;
}
END

test(':prototype', <<'END', {perl => '5.020'});
sub foo :prototype($) { $_[0] }
END

test(':prototype', <<'END', {perl => '5.020', feature => 0});
use feature 'signatures';
sub foo :prototype($$) ($left, $right) {
    return $left + $right;
}
END

test('bitwise op', <<'END', {perl => '5.022', feature => 0});
use feature 'bitwise';
$a &. $b
END

test('bitwise op', <<'END', {perl => '5.022', feature => 0});
use feature 'bitwise';
$a |. $b
END

test('bitwise op', <<'END', {perl => '5.022', feature => 0});
use feature 'bitwise';
$a ^. $b
END

#SKIP: not implemented?
test('bitwise op', <<'END', {perl => '5.022', feature => 0});
use feature 'bitwise';
$a ~. $b
END

test('bitwise op', <<'END', {perl => '5.022', feature => 0});
use feature 'bitwise';
$a &.= $b
END

test('bitwise op', <<'END', {perl => '5.022', feature => 0});
use feature 'bitwise';
$a |.= $b
END

test('bitwise op', <<'END', {perl => '5.022', feature => 0});
use feature 'bitwise';
$a ^.= $b
END

test('<<>>', <<'END', {perl => '5.022'});
while(<<>>) { ... }
END

test('<<~', <<'END', {perl => '5.026'});
  $var =<<~"HERE";
  foo
  HERE
END

test('${^CAPTURE}', <<'END', {perl => '5.026'});
@{^CAPTURE}[0]
END

test('@{^CAPTURE}', <<'END', {perl => '5.026'});
@{^CAPTURE}
END

test('%{^CAPTURE}', <<'END', {perl => '5.026'});
%{^CAPTURE}
END

test('%{^CAPTURE_ALL}', <<'END', {perl => '5.026'});
%{^CAPTURE_ALL}
END

done_testing;
