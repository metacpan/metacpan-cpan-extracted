use t::ParserTest;

__END__

===
--- code
($t.p ~ "a")
--- expected
(statements (string_concat (methodcall (variable "$t") (ident "p")) (string "a")))
