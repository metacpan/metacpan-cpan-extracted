use t::ParserTest;
__END__
===
--- code
e + 0
--- expected
(statements (add (e) (int 0)))
