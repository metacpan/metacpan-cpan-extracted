


#include <stdio.h>
#include "list_uint.h"

int main (void) {



	printf ("hello\n");


	struct list_uint_list *mylist;

	mylist = list_uint_constructor();

	list_uint_push_back(mylist, 21);
	list_uint_push_back(mylist, 99);
	list_uint_push_back(mylist, 33);
	list_uint_push_back(mylist, 34);
	list_uint_push_back(mylist, 67);
	list_uint_push_back(mylist, 12);
	list_uint_push_back(mylist, 28);
	list_uint_push_back(mylist, 55);
	list_uint_push_back(mylist, 76);

	list_uint_sort(mylist);

	printf("\n\n\nThis is the sorted list\n");
	list_uint_list_dumper(mylist);

	return 0;
}

