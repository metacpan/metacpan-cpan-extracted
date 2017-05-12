use t::ParserTest;

__END__

===
--- code
/./
--- expected
(statements (regexp "."))

===
--- code
m/./
--- expected
(statements (regexp "."))
