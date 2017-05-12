
# need to set PERL5LIB to go up one directory and down into the "lib" directory so it will see Stlgen.pm
# file from the debug directory.

PERL5LIB=../lib

# this is the command to run the test script, compile the c code, and bring the c code up in the editor.
./debug.pl ; gcc -Wall list_uint.c list_uint_main.c;

./a.out
