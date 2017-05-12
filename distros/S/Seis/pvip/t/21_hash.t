use t::ParserTest;
__END__

===
--- code
$e<ook!>
--- expected
(statements (atkey (variable "$e") (string "ook!")))

===
--- code
$e<ook?>
--- expected
(statements (atkey (variable "$e") (string "ook?")))

===
--- code
$e<ook.>
--- expected
(statements (atkey (variable "$e") (string "ook.")))

===
--- code
{a => 1}.keys
--- expected
(statements (methodcall (hash (pair (string "a") (int 1))) (ident "keys")))

===
--- code
[{a => 1}.keys]
--- expected
(statements (array (methodcall (hash (pair (string "a") (int 1))) (ident "keys"))))

===
--- code
%hash<key> = $value;
--- expected
(statements (list_assignment (atkey (variable "%hash") (string "key")) (variable "$value")))

