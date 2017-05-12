use t::ParserTest;
__END__

===
--- code
is(1,2,);
--- expected
(statements (funcall (ident "is") (args (int 1) (int 2))))

===
--- code
is-true()
--- expected
(statements (funcall (ident "is-true") (args)))

=== It should pass the 'List'
--- code
end (1,2,3)
--- expected
(statements (funcall (ident "end") (args (list (int 1) (int 2) (int 3)))))

===
--- code
end(1,2,3)
--- expected
(statements (funcall (ident "end") (args (int 1) (int 2) (int 3))))

===
--- code
map { $_ }, @a
--- expected
(statements (funcall (ident "map") (args (lambda (block (statements (variable "$_")))) (variable "@a"))))


===
--- code
$is-true.()
--- expected
(statements (funcall (variable "$is-true") (args)))
