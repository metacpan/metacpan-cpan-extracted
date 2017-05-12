use t::ParserTest;
__END__

===
--- code
unless Mu { 1 }
--- expected
(statements (unless (ident "Mu") (statements (int 1))))

===
--- code
live { 3 };
--- expected
(statements (funcall (ident "live") (args (lambda (block (statements (int 3)))))))

===
--- code
@a = map { $_ }, @a
--- expected
(statements (list_assignment (variable "@a") (funcall (ident "map") (args (lambda (block (statements (variable "$_")))) (variable "@a")))))

