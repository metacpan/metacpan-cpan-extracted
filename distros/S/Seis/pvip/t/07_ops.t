use t::ParserTest;

__END__

===
--- code
?$x
--- expected
(statements (unary_boolean (variable "$x")))

===
--- code
^$n
--- expected
(statements (unary_upto (variable "$n")))

===
--- code
0b0101 +^ 0b1111
--- expected
(statements (bin_xor (int 5) (int 15)))

===
--- code
1 and 2
--- expected
(statements (logical_and (int 1) (int 2)))

===
--- code
1 andthen 2
--- expected
(statements (logical_andthen (int 1) (int 2)))

===
--- code
1===3
--- expected
(statements (chain (int 1) (value_identity (int 3))))

===
--- code
1 cmp 3
--- expected
(statements (cmp (int 1) (int 3)))

===
--- code
$a +<= 3
--- expected
(statements (inplace_blshift (variable "$a") (int 3)))

===
--- code
$a +<= 3;
$a +>= 1;
--- expected
(statements (inplace_blshift (variable "$a") (int 3)) (inplace_brshift (variable "$a") (int 1)))

===
--- code
$a+<=3;$a+>=3
--- expected
(statements (inplace_blshift (variable "$a") (int 3)) (inplace_brshift (variable "$a") (int 3)))

===
--- code
$a <=> 3
--- expected
(statements (num_cmp (variable "$a") (int 3)))

===
--- code
say |@arr
--- expected
(statements (funcall (ident "say") (args (unary_flatten_object (variable "@arr")))))

===
--- code
7 .. 9
--- expected
(statements (range (int 7) (int 9)))

===
--- code
7 !~~ 9
--- expected
(statements (chain (int 7) (not_smart_match (int 9))))

===
--- code
7 & 9
--- expected
(statements (junctive_and (int 7) (int 9)))

===
--- code
7 S& 9
--- expected
(statements (junctive_sand (int 7) (int 9)))

===
--- code
7 | 9
--- expected
(statements (junctive_or (int 7) (int 9)))

===
--- code
!!$n
--- expected
(statements (not (not (variable "$n"))))

===
--- code
$a **= 2;
--- expected
(statements (inplace_pow (variable "$a") (int 2)))

===
--- code
10 %%  3
--- expected
(statements (is_divisible_by (int 10) (int 3)))

===
--- code
10 !%%  3
--- expected
(statements (not_divisible_by (int 10) (int 3)))

===
--- code
10 =:= 3
--- expected
(statements (chain (int 10) (container_identity (int 3))))

===
--- code
$a Z $b
--- expected
(statements (z (variable "$a") (variable "$b")))

===
--- code
$a := $b
--- expected
(statements (bind (variable "$a") (variable "$b")))

===
--- code
$a = $b
--- expected
(statements (list_assignment (variable "$a") (variable "$b")))

