use t::ParserTest;
__END__

===
--- code
sub { }
--- expected
(statements (func (nop) (params) (nop) (block)))

===
--- code
sub ok_auto { }
--- expected
(statements (func (ident "ok_auto") (params) (nop) (block)))

===
--- code
sub is-true() { True }
--- expected
(statements (func (ident "is-true") (params) (nop) (block (statements (ident "True")))))

===
--- code
sub foo() is export { }
--- expected
(statements (func (ident "foo") (params) (export) (block)))

===
--- code
sub foo($n) { }
--- expected
(statements (func (ident "foo") (params (param (nop) (variable "$n") (nop) (int 0))) (nop) (block)))

===
--- code
sub foo(Int $n) { }
--- expected
(statements (func (ident "foo") (params (param (ident "Int") (variable "$n") (nop) (int 0))) (nop) (block)))

===
--- code
sub foo(Str $n="Ah") { }
--- expected
(statements (func (ident "foo") (params (param (ident "Str") (variable "$n") (string "Ah") (int 0))) (nop) (block)))

===
--- code
(-> $n { say($n) })(5)
--- expected
(statements (funcall (lambda (params (param (nop) (variable "$n") (nop) (int 0))) (block (statements (funcall (ident "say") (args (variable "$n")))))) (args (int 5))))

===
--- code
sub foo($n is copy) { }
--- expected
(statements (func (ident "foo") (params (param (nop) (variable "$n") (nop) (int 1))) (nop) (block)))
