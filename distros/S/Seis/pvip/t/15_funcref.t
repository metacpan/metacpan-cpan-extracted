use t::ParserTest;

__END__

===
--- code
&a
--- expected
(statements (funcref (ident "a")))

===
--- code
my &a = sub { }
--- expected
(statements (list_assignment (my (nop) (funcref (ident "a"))) (func (nop) (params) (nop) (block))))
