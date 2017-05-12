use t::ParserTest;
__END__
===
--- code
augment class Foo { }
--- expected
(statements (funcall (ident "augment") (args (class (ident "Foo") (nop) (block)))))
