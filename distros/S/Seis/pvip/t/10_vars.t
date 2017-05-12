use t::ParserTest;
__END__

===
--- code
my ($k, $v);
--- expected
(statements (my (nop) (list (variable "$k") (variable "$v"))))

===
--- code
my ($k, $v) = (1,2);
--- expected
(statements (list_assignment (my (nop) (list (variable "$k") (variable "$v"))) (list (int 1) (int 2))))

===
--- code
$var-name
--- expected
(statements (variable "$var-name"))

===
--- code
$var-1
--- expected
(statements (sub (variable "$var") (int 1)))

===
--- code
$$var
--- expected
(statements (scalar_deref (variable "$var")))

===
--- code
@*INC
--- expected
(statements (tw_inc))

===
--- code
$*VM
--- expected
(statements (tw_vm))

===
--- code
$?PACKAGE
--- expected
(statements (tw_package))

===
--- code
$?CLASS
--- expected
(statements (tw_class))

===
--- code
$?MODULE
--- expected
(statements (tw_module))

===
--- code
$~MAIN
--- expected
(statements (slangs "$~MAIN"))

===
--- code
$!
--- expected
(statements (special_variable_exceptions))

===
--- code
$/
--- expected
(statements (special_variable_regexp_match))

===
--- code
$*OSVER
--- expected
(statements (tw_osver))

===
--- code
$*OS
--- expected
(statements (tw_os))

===
--- code
$*PID
--- expected
(statements (tw_pid))

===
--- code
$?OS
--- expected
(statements (tw_os))

===
--- code
$*CWD
--- expected
(statements (tw_cwd))

===
--- code
$*EXECUTABLE_NAME
--- expected
(statements (tw_executable_name))

===
--- code
%*ENV
--- expected
(statements (tw_env))

===
--- code
@$v
--- expected
(statements (array_deref (variable "$v")))

===
--- code
$!x
--- expected
(statements (attribute_variable "$!x"))

===
--- code
$.x
--- expected
(statements (attribute_variable "$.x"))

===
--- code
$^a
--- expected
(statements (tw_a))

=== S03-binding/attributes.t
--- code
our $.x
--- expected
(statements (our (attribute_variable "$.x")))

=== S03-binding/attributes.t
--- code
has $x
--- expected
(statements (has (variable "$x") (nop)))

