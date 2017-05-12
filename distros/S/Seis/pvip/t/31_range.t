use t::ParserTest;

__END__

===
--- code
1..*
--- expected
(statements (range (int 1) (whatever)))

===
--- code
1..2
--- expected
(statements (range (int 1) (int 2)))
