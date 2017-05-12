use t::ParserTest;
__END__

===
--- code
Test::version_lt
--- expected
(statements (ident "Test::version_lt"))

===
--- code
ok_auto
--- expected
(statements (ident "ok_auto"))
