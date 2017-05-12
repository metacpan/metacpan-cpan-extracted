use t::ParserTest;

__END__

===
--- code
Bool::False or 42
--- expected
(statements (logical_or (ident "Bool::False") (int 42)))

