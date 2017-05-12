use t::ParserTest;
__END__
===
--- code
END { 3 } 
--- expected
(statements (end (block (statements (int 3)))))

===
--- code
BEGIN { 3 } 
--- expected
(statements (begin (block (statements (int 3)))))
