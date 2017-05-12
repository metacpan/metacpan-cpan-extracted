use t::ParserTest;
__END__

===
--- code
(1,)
--- expected
(statements (list (int 1)))

===
--- code
pi / 4, "/";
--- expected
(statements (list (div (pi) (int 4)) (string "\/")))

