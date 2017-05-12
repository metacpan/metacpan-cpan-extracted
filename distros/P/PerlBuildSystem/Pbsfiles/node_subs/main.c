#include <stdio.h>
#include <stdlib.h>

#include "common.h"

void foo(void) ;
void bar(void) ;
void baz(int) ;
void PrintHelloWorld(void) ;

void foo(void) 
{
bar();
}

void bar(void) 
{
	printf("hello world\n");
	foo();
	baz(1);
}

void baz(int x) 
{
	foo();
}


int main(void)
{

foo() ;

PrintHelloWorld() ;

baz(3) ;

return(0) ;
}



