use t::ParserTest;
__END__

=== RT #67784
--- code
class.new
--- expected
(statements (methodcall (ident "class") (ident "new")))
