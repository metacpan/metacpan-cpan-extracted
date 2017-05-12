use t::ParserTest;
__END__

===
--- code
$x."WHAT"()
--- expected
(statements (methodcall (variable "$x") (string "WHAT") (args)))
