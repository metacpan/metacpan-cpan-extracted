=== foo
--- input: 10.0.0.100
--- expected: foo

=== bar
--- input: 10.1.0.8
--- expected: bar

=== not match
--- input: 192.168.1.2
--- expected: NOT_MATCH

=== foo min
--- input: 10.0.0.0
--- expected: foo

=== foo max
--- input: 10.0.0.255
--- expected: foo

=== invalid IP
--- input: 11.0.999.1
--- expected: NOT_MATCH

=== 0.0.0.0
--- input: 0.0.0.0
--- expected: NOT_MATCH

=== 255.255.255.255
--- input: 255.255.255.255
--- expected: NOT_MATCH

=== bigfoo
--- input: 10.255.255.255
--- expected: bigfoo

=== foo2
--- input: 10.2.0.1
--- expected: foo2
