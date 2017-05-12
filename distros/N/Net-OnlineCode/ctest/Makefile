all : xor_test

../clib/this_machine.h : gen_this_machine
	./gen_this_machine

gen_this_machine : gen_this_machine.c
	${CC} -o gen_this_machine gen_this_machine.c

xor_test : ../clib/this_machine.h ../clib/xor.o xor_test.c
	${CC} -O2 -I../clib -lrt -o xor_test xor_test.c ../clib/xor.o

clean:
	rm -f *.o *.s xor_test
