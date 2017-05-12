use t::ParserTest;
__END__

===
--- code
has $.x = 3;
--- expected
(statements (has (attribute_variable "$.x") (int 3)))

