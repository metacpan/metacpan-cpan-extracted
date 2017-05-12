use t::ParserTest;

__END__

===
--- code
try { 3 }
--- expected
(statements (try (block (statements (int 3)))))

===
--- code
1
=begin END
--- expected
(statements (int 1))

===
--- code
1
=END
--- expected
(statements (int 1))

===
--- code
1
#`[
]
--- expected
(statements (int 1))

===
--- code
my %hash={a => 1};
--- expected
(statements (list_assignment (my (nop) (variable "%hash")) (hash (pair (string "a") (int 1)))))

===
--- code
\@a
--- expected
(statements (ref (variable "@a")))

===
--- code
@a[1] = 3;
--- expected
(statements (list_assignment (atpos (variable "@a") (int 1)) (int 3)))

===
--- code
()
--- expected
(statements (list))

===
--- code
my @a_o=<x y z>
--- expected
(statements (list_assignment (my (nop) (variable "@a_o")) (list (string "x") (string "y") (string "z"))))

===
--- code
@sines.map();
--- expected
(statements (methodcall (variable "@sines") (ident "map") (args)))

===
--- code
@sines.map({ 3 })
--- expected
(statements (methodcall (variable "@sines") (ident "map") (args (lambda (block (statements (int 3)))))))

===
--- code
-> { 3 }
--- expected
(statements (lambda (params) (block (statements (int 3)))))
