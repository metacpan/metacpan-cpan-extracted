use t::ParserTest;

__END__

===
--- code
until 1 { 2 }
--- expected
(statements (until (int 1) (block (statements (int 2)))))

===
--- code
2 until 1
--- expected
(statements (until (int 1) (int 2)))

