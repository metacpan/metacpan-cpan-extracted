use t::ParserTest;
__END__

===
--- code
package Foo { }
--- expected
(statements (package (ident "Foo") (block)))
