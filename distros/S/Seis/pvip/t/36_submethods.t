use t::ParserTest;
__END__

===
--- code
class Foo        { has $.foo_build; submethod BUILD() { $!foo_build++ } }
--- expected
(statements (class (ident "Foo") (nop) (block (statements (has (attribute_variable "$.foo") (nop)) (int 0) (ident "build") (submethod (ident "BUILD") (nop) (block (statements (attribute_variable "$!foo") (int 0) (postinc (ident "build")))))))))

===
--- code
submethod DESTROY { }
--- expected
(statements (submethod (ident "DESTROY") (nop) (block)))
