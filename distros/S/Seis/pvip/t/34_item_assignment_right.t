use t::ParserTest;
__END__

===
--- code
$a+=$b+=1
--- expected
(statements (inplace_add (variable "$a") (inplace_add (variable "$b") (int 1))))
