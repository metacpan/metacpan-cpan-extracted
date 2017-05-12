use t::ParserTest;

__END__

===
--- code
sub foo(*@a) { }
--- expected
(statements (func (ident "foo") (params (param (nop) (vargs (variable "@a")) (nop) (int 0))) (nop) (block)))

===
--- code
method foo(*@a) { }
--- expected
(statements (method (ident "foo") (params (param (nop) (vargs (variable "@a")) (nop) (int 0))) (block)))

===
--- code
sub foo(*@a is rw) { }
--- expected
(statements (func (ident "foo") (params (param (nop) (vargs (variable "@a")) (nop) (int 2))) (nop) (block)))
