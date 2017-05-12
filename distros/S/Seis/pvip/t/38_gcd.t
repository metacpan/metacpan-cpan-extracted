use t::ParserTest;
__END__
=== 
--- code
1 gcd 2
--- expected
(statements (gcd (int 1) (int 2)))

===
--- code
[gcd] 1, 2
--- expected
(statements (reduce (string "gcd") (list (int 1) (int 2))))

=== S06-advanced/recurse.t
--- code
gcd(1147, 1271)
--- expected
(statements (funcall (ident "gcd") (args (int 1147) (int 1271))))

