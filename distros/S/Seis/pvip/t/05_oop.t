use t::ParserTest;

__END__

===
--- code
class { }
--- expected
(statements (class (nop) (nop) (block)))

===
--- code
class Foo { }
--- expected
(statements (class (ident "Foo") (nop) (block)))

===
--- code
class NotComplex is Cool { }
--- expected
(statements (class (ident "NotComplex") (list (is (ident "Cool"))) (block)))

===
--- code
3.WHAT.gist
--- expected
(statements (methodcall (methodcall (int 3) (ident "WHAT")) (ident "gist")))

===
--- code
multi method foo() { }
--- expected
(statements (multi (method (ident "foo") (nop) (block))))

===
--- code
@foo.push: 3
--- expected
(statements (methodcall (variable "@foo") (ident "push") (args (int 3))))

===
--- code
$foo.^methods
--- expected
(statements (meta_method_call (variable "$foo") (ident "methods") (nop)))

===
--- code
$foo.^methods(3)
--- expected
(statements (meta_method_call (variable "$foo") (ident "methods") (args (int 3))))

===
--- code
class A { has $.b }
--- expected
(statements (class (ident "A") (nop) (block (statements (has (attribute_variable "$.b") (nop))))))

===
--- code
class A { has @.b }
--- expected
(statements (class (ident "A") (nop) (block (statements (has (attribute_variable "@.b") (nop))))))

===
--- code
class A { has $!b }
--- expected
(statements (class (ident "A") (nop) (block (statements (has (attribute_variable "$!b") (nop))))))

===
--- code
class Foo::Bar { }
--- expected
(statements (class (ident "Foo::Bar") (nop) (block)))

===
--- code
role C { }
--- expected
(statements (role (ident "C") (block)))

=== class A is B is C
--- code
class A is B is C { }
--- expected
(statements (class (ident "A") (list (is (ident "B")) (is (ident "C"))) (block)))

=== assign to attribute vars
--- code
class Point { has $!x; method set_x($x) { $!x=$x }; };
--- expected
(statements (class (ident "Point") (nop) (block (statements (has (attribute_variable "$!x") (nop)) (method (ident "set_x") (params (param (nop) (variable "$x") (nop) (int 0))) (block (statements (list_assignment (attribute_variable "$!x") (variable "$x"))))) (nop)))))
