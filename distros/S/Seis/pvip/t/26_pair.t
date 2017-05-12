use t::ParserTest;

__END__

===
--- code
:$x
--- expected
(statements (pair (string "$x") (variable "$x")))

===
--- code
:todo(1)
--- expected
(statements (pair (string "todo") (int 1)))

===
--- code
:bar[ baz => 42, sloth => 43 ];
--- expected
(statements (pair (string "bar") (list (pair (ident "baz") (int 42)) (pair (ident "sloth") (int 43)))))

===
--- code
:!f
--- expected
(statements (pair (string "f") (false)))
