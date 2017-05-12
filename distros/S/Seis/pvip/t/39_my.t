use t::ParserTest;
__END__

===
--- code
my Int $days = 24;
--- expected
(statements (list_assignment (my (ident "Int") (variable "$days")) (int 24)))
