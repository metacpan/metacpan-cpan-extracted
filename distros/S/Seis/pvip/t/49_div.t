use t::ParserTest;
__END__
===
--- code
1 div 2
--- expected
(statements (integer_division (int 1) (int 2)))
