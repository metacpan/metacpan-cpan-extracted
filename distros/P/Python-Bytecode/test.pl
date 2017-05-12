# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 7;
use Python::Bytecode;
ok(1); # If we made it this far, we're ok.

#########################

# Insert your test code below, the Test module is use()ed here so read
# its man page ( perldoc Test ) for help writing this test script.

open IN, "test2.pyc" or die $!;
binmode IN;
my $code = Python::Bytecode->new(\*IN);
ok(defined $code);
is($code->filename, "test2.py");
is((join "\n", map { $_->[0] } $code->disassemble, (),""), <<EOF
     0          SET_LINENO    0
     3          SET_LINENO    1
     6          LOAD_CONST    0 (2)
     9          STORE_NAME    0 [a]
    12          SET_LINENO    2
    15           LOAD_NAME    0 [a]
    18       JUMP_IF_FALSE   12 (to 33)
    21             POP_TOP
    22          SET_LINENO    3
    25           LOAD_NAME    0 [a]
    28          PRINT_ITEM
    29       PRINT_NEWLINE
    30        JUMP_FORWARD    1 (to 34)
>>  33             POP_TOP
>>  34          LOAD_CONST    1 ()
    37        RETURN_VALUE
EOF
);
close IN;

open IN, "test23.pyc" or die $!;
binmode IN;
my $code = Python::Bytecode->new(\*IN);
ok(defined $code);
is($code->filename, "./test23.py");
is((join "\n", map { $_->[0] } $code->disassemble, (),""), <<EOF
     0          LOAD_CONST    0 (2)
     3          STORE_NAME    0 [a]
     6           LOAD_NAME    0 [a]
     9       JUMP_IF_FALSE    9 (to 21)
    12             POP_TOP
    13           LOAD_NAME    0 [a]
    16          PRINT_ITEM
    17       PRINT_NEWLINE
    18        JUMP_FORWARD    1 (to 22)
>>  21             POP_TOP
>>  22          LOAD_CONST    1 ()
    25        RETURN_VALUE
EOF
);

