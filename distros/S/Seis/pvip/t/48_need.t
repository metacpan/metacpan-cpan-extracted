use t::ParserTest;

__END__

===
--- code
need Foo;
--- expected
(statements (need (ident "Foo")))
