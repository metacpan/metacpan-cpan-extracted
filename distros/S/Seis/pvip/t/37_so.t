use t::ParserTest;
__END__

===
--- code
so 1
--- expected
(statements (so (int 1)))

===
--- code
so sub{}
--- expected
(statements (so (func (nop) (params) (nop) (block))))

===
--- code
not so 0
--- expected
(statements (not (so (int 0))))
