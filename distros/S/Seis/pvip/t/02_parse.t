use t::ParserTest;

__END__

===
--- code: 33
--- expected
(statements (int 33))

===
--- code: .33
--- expected
(statements (number 0.33))

===
--- code: 0.33
--- expected
(statements (number 0.33))

===
--- code: 3.14
--- expected
(statements (number 3.14))

===
--- code: 0b1000
--- expected
(statements (int 8))

===
--- code: 0b0100
--- expected
(statements (int 4))

===
--- code: 0b0010
--- expected
(statements (int 2))

===
--- code: 0b0001
--- expected
(statements (int 1))

===
--- code: 0xdeadbeef
--- expected
(statements (int 3735928559))

===
--- code: 0o755
--- expected
(statements (int 493))

===
--- code: -5963
--- expected
(statements (unary_minus (int 5963)))

===
--- code: 3*4
--- expected
(statements (mul (int 3) (int 4)))

===
--- code: 3/4
--- expected
(statements (div (int 3) (int 4)))

===
--- code: 3+4
--- expected
(statements (add (int 3) (int 4)))

===
--- code: 3-4
--- expected
(statements (sub (int "3") (int 4)))

===
--- code: 3-4-2
--- expected
(statements (sub (sub (int "3") (int 4)) (int 2)))

===
--- code: 3+4*2
--- expected
(statements (add (int "3") (mul (int 4) (int 2))))

===
--- code: 3==4
--- expected
(statements (chain (int 3) (eq (int 4))))

===
--- code: say()
--- expected
(statements (funcall (ident "say") (args)))

===
--- code: say(3)
--- expected
(statements (funcall (ident "say") (args (int 3))))

===
--- code: "hoge"
--- expected
(statements (string "hoge"))

===
--- code: (3+4)*2
--- expected
(statements (mul (add (int 3) (int 4)) (int 2)))

===
--- code: $n
--- expected
(statements (variable "$n"))

===
--- code: my $n := 3
--- expected
(statements (bind (my (nop) (variable "$n")) (int 3)))

=== test( '"H" ~ "M"', string_concat(string("H"), string("M")));
--- code: "H" ~ "M"
--- expected
(statements (string_concat (string "H") (string "M")))

===
--- code: if 1 {say(4)}
--- expected
(statements
    (if (int 1)
        (statements
            (funcall (ident "say") (args (int 4))))))

===
--- code: if 1 { say(4) }
--- expected
(statements
    (if (int 1)
        (statements
            (funcall (ident "say") (args (int 4))))))

===
--- code: 1;2
--- expected
(statements
    (int 1)
    (int 2))

===
--- code: []
--- expected
(statements
    (array))

===
--- code: [1,2,3]
--- expected
(statements
    (array (int 1) (int 2) (int 3)))

===
--- code
sub foo() { 4 }
--- expected
(statements (func (ident "foo") (params) (nop) (block (statements (int 4)))))

===
--- code
sub foo() { return 5963 } say(foo());
--- expected
(statements (func (ident "foo") (params) (nop) (block (statements (return (int 5963))))) (funcall (ident "say") (args (funcall (ident "foo") (args)))))

===
--- code
sub foo() { return 5963 }; say(foo());
--- expected
(statements (func (ident "foo") (params) (nop) (block (statements (return (int 5963))))) (funcall (ident "say") (args (funcall (ident "foo") (args)))))

===
--- code
sub foo ($n) {  }
--- expected
(statements (func (ident "foo") (params (param (nop) (variable "$n") (nop) (int 0))) (nop) (block)))

===
--- code: if 1 {4} else {5}
--- expected
(statements
    (if
        (int 1)
        (statements
            (int 4))
        (else
            (int 5)))
)

===
--- code: fib()+fib()
--- expected
(statements
    (add
        (funcall (ident "fib") (args))
        (funcall (ident "fib") (args)))
)

===
--- code: fib($n-1)+fib($n-2)
--- expected
(statements
    (add
        (funcall (ident "fib") (args (sub (variable "$n") (int 1))))
        (funcall (ident "fib") (args (sub (variable "$n") (int 2)))))
)

===
--- code: return 1+2;
--- expected
(statements
    (return (add (int 1) (int 2)))
)

====
--- code
for @a { 1; }
--- expected
(statements (for (variable "@a") (block (statements (int 1)))))

====
--- code
<< a b c >>
--- expected
(statements
    (list (string "a") (string "b") (string "c"))
)

===
--- code
+"0x0a"
--- expected
(statements
    (unary_plus (string "0x0a"))
)

===
--- code
0d9
--- expected
(statements
    (int 9)
)

===
--- code
my $i=3;
--- expected
(statements (list_assignment (my (nop) (variable "$i")) (int 3)))

===
--- code
"3$x4"
--- expected
(statements
    (string_concat
        (string "3")
        (variable "$x4")))

===
--- code
"3$x 4"
--- expected
(statements
    (string_concat
        (string_concat
            (string "3")
            (variable "$x"))
        (string " 4")))

===
--- code
"3\x494"
--- expected
(statements
    (string "3I4"))

===
--- code
-(-1)
--- expected
(statements
    (unary_minus (unary_minus (int 1))))

===
--- code
0_0_1_4
--- expected
(statements
    (int 14))

===
--- code
say('ok ', 11*say('ok 10'));
--- expected
(statements (funcall (ident "say") (args (string "ok ") (mul (int 11) (funcall (ident "say") (args (string "ok 10")))))))

===
--- code
say "ok "
--- expected
(statements (funcall (ident "say") (args (string "ok "))))

===
--- code
say 'ok ', 11*say 'ok 10';
--- expected
(statements (funcall (ident "say") (args (string "ok ") (mul (int 11) (funcall (ident "say") (args (string "ok 10")))))))

===
--- code
1 or 2
--- expected
(statements (logical_or (int 1) (int 2)))

===
--- code
;0 xor say 'ok 7'
--- expected
(statements (nop ) (logical_xor (int 0) (funcall (ident "say") (args (string "ok 7")))))

===
--- code
class { 1 }
--- expected
(statements (class (nop) (nop) (block (statements (int 1)))))

===
--- code
class Foo { 1 }
--- expected
(statements (class (ident "Foo") (nop) (block (statements (int 1)))))

===
--- code
class { method bar() { } }
--- expected
(statements (class (nop) (nop) (block (statements (method (ident "bar") (nop) (block))))))

===
--- code
$o.new().bar()
--- expected
(statements
    (methodcall
        (methodcall (variable "$o") (ident "new") (args ))
        (ident "bar")
        (args)))

===
--- code
Foo.new().bar()
--- expected
(statements (methodcall (methodcall (ident "Foo") (ident "new") (args )) (ident "bar") (args )))

===
--- code
[+] 1..3
--- expected
(statements (reduce (string "+") (range (int 1) (int 3))))

===
--- code
[min] 1..3
--- expected
(statements (reduce (string "min") (range (int 1) (int 3))))
