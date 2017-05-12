use t::ParserTest;
__END__

===
--- code
method foo { }
--- expected
(statements (method (ident "foo") (nop) (block)))
