use t::ParserTest;
__END__

===
--- code
KEEP { $x=1 }
--- expected
(statements (keep (lambda (block (statements (list_assignment (variable "$x") (int 1)))))))

===
--- code
UNDO { $x=1 }
--- expected
(statements (undo (lambda (block (statements (list_assignment (variable "$x") (int 1)))))))

===
--- code
KEEP $kept   = 1;
--- expected
(statements (keep (list_assignment (variable "$kept") (int 1))) (nop))

===
--- code
UNDO $undone = 1;
--- expected
(statements (undo (list_assignment (variable "$undone") (int 1))) (nop))

