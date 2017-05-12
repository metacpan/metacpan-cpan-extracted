use t::ParserTest;

__END__

===
--- code
1 while 2
--- expected
(statements (while (int 2) (int 1)))
