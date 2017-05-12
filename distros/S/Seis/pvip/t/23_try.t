use t::ParserTest;
__END__

===
--- code
try eval "1"
--- expected
(statements (try (funcall (ident "eval") (args (string "1")))))
