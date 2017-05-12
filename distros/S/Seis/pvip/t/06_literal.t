use t::ParserTest;

__END__

===
--- code
:10<0>
--- expected
(statements (int 0))

===
--- code
:10<1>
--- expected
(statements (int 1))

===
--- code
:16<deadbeef>
--- expected
(statements (int 3735928559))

===
--- code
:lang<perl5>
--- expected
(statements (pair (string "lang") (string "perl5")))

===
--- code
q/a'/
--- expected
(statements (string "a'"))

===
--- code
q{a'}
--- expected
(statements (string "a'"))

===
--- code
q|a'|
--- expected
(statements (string "a'"))

===
--- code
{ 'baz' => 3 }
--- expected
(statements (hash (pair (string "baz") (int 3))))

===
--- code
{ 'baz' => 3, }
--- expected
(statements (hash (list (pair (string "baz") (int 3)))))

===
--- code
{ "bar" => 3, "boz" => 4  }
--- expected
(statements (hash (list (pair (string "bar") (int 3)) (pair (string "boz") (int 4)))))

===
--- code
[1]
--- expected
(statements (array (int 1)))

===
--- code
1e1
--- expected
(statements (number 10.))

===
--- code
IO::Path
--- expected
(statements (ident "IO::Path"))

===
--- code
2i
--- expected
(statements (complex 2.))

===
--- code
::Foo
--- expected
(statements (ident "::Foo"))

===
--- code
2.18503986326152i
--- expected
(statements (complex 2.18504))

===
--- code
.5i
--- expected
(statements (complex 0.5))

===
--- code
0xC0
--- expected
(statements (int 192))
