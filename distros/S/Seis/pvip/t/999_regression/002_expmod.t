use t::ParserTest;

__END__

===
--- code
1*1,  "{7*1 }"
--- expected
(statements (list (mul (int 1) (int 1)) (string_concat (string "") (statements (mul (int 7) (int 1))))))
