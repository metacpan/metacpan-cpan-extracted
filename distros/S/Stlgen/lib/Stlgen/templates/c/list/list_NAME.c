/*
copyright 2010 Greg London 
All rights reserved.
 
Licensed under the MIT license.
 
Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:
 
The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.
 
THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
 
*/

// complete c linked list tutorial
// http://cslibrary.stanford.edu/103/

// STL container for "list"
// http://www.cplusplus.com/reference/stl/list/

// need stdlib for malloc and free
#include <stdlib.h>

// need for printf used by default error handler
#include <stdio.h>

// struct for each element in list
struct list_[% Instancename %]_elem {
	struct list_[% Instancename %]_elem *next;
	struct list_[% Instancename %]_elem *prev;
	[% FOREACH section = payload %][% section.type %] [% section.name %];
	[% END %]
};


// struct for entire list object
struct list_[% Instancename %]_list {
	struct list_[% Instancename %]_elem *beforefirst;
	struct list_[% Instancename %]_elem *afterlast;
};

/////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////
// callbacks to list functions, user may override these in their code
/////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////


// prototype now, declare later
void list_[% Instancename %]_iterator(struct list_[% Instancename %]_list *list, void (*callback)(struct list_[% Instancename %]_elem *));

/////////////////////////////////////////////////////////////////////
// element dumper
/////////////////////////////////////////////////////////////////////

// create default behvaivour for printing out the contents of an element.
// user can override based on whatever types they have in element.
// for default, just print address of current element, and prev/next addresses 
// user can copy paste this code and modify it and override the default behaviour.

void list_[% Instancename %]_default_element_dumper(struct list_[% Instancename %]_elem *currelement) {
	printf("\t// element at address %x\n", (unsigned int)currelement);
	printf("\t\tprev = %x\n", (unsigned int)currelement->prev);
	printf("\t\tnext = %x\n", (unsigned int)currelement->next);
	[% FOREACH section = payload %][% section.dumper %]
	[% END %]
}

void (*list_[% Instancename %]_element_dumper_ptr)(struct list_[% Instancename %]_elem *currelement) = &list_[% Instancename %]_default_element_dumper;

/////////////////////////////////////////////////////////////////////
// list dumper
/////////////////////////////////////////////////////////////////////

// create default behvaivour for printing out the contents of an list.
// user can override based on whatever types they have in list.
// user can copy paste this code and modify it and override the default behaviour.

void list_[% Instancename %]_default_list_dumper(struct list_[% Instancename %]_list *currlist) {
	struct list_[% Instancename %]_elem *beforefirst = currlist->beforefirst;
	struct list_[% Instancename %]_elem *afterlast 	 = currlist->afterlast;

	printf("// list at address %u", (unsigned int)currlist);
	printf("{\n");
	printf("'beforefirst' marker:\n");
	(*list_[% Instancename %]_element_dumper_ptr)(beforefirst);

	// print the user elements
	printf("user elements:\n");
	list_[% Instancename %]_iterator(currlist, list_[% Instancename %]_element_dumper_ptr);

	printf("'afterlast' marker:\n");
	(*list_[% Instancename %]_element_dumper_ptr)(afterlast);
}

void (*list_[% Instancename %]_list_dumper_ptr)(struct list_[% Instancename %]_list *currlist) = &list_[% Instancename %]_default_list_dumper;

// create a normal function to dereference the pointer for the user and dump the list
void list_[% Instancename %]_list_dumper(struct list_[% Instancename %]_list *currlist){
	(*list_[% Instancename %]_list_dumper_ptr)(currlist);
}

/////////////////////////////////////////////////////////////////////
// error handling
/////////////////////////////////////////////////////////////////////


int list_[% Instancename %]_error_handler_recursive_flag=0;

// This is the default error handler, report and exit.
void list_[% Instancename %]_default_error_handler(
	struct list_[% Instancename %]_list *list,
	struct list_[% Instancename %]_elem *elem,
	char *errmsg, 
	int errnum
){
	if(list_[% Instancename %]_error_handler_recursive_flag) {
		printf("recursively hit an error condition. Exiting.\n");
		exit(1);
	}
	list_[% Instancename %]_error_handler_recursive_flag=1;
	printf("%s (%d)\n", errmsg, errnum);
	printf("Error occurred from element at address %u\n", (unsigned int)elem);
	list_[% Instancename %]_list_dumper(list);
	list_[% Instancename %]_error_handler_recursive_flag=0;
	exit(errnum);

}

// all errors use this pointer to an error handler
// this allows the code to set it to a default
// but also allows the user to assign the pointer
// to point to their own error handler
// this allows user to change error behaviour
// without changing any code in this file.
void (*list_[% Instancename %]_errorhandler_ptr)(
	struct list_[% Instancename %]_list *list,
	struct list_[% Instancename %]_elem *elem,
	char *errmsg, 
	int errnum
) = &list_[% Instancename %]_default_error_handler;

// provide a function to dereference the error handler pointer.
// since speed isn't important here, shouldn't cause a problem.
void list_[% Instancename %]_errorhandler(
	struct list_[% Instancename %]_list *list,
	struct list_[% Instancename %]_elem *elem,
	char *errmsg, 
	int errnum
){
	(*list_[% Instancename %]_errorhandler_ptr)(
		list,
		elem,
		errmsg,
		errnum
	);
}


/////////////////////////////////////////////////////////////////////
// element free
/////////////////////////////////////////////////////////////////////

// by default, elements are destructed by setting prev/next pointers
// to null and then freeing the element.
// if the element contains a pointer to something that also needs to be freed,
// user can override the default behaviour with their own element destructor.

void list_[% Instancename %]_default_element_free(struct list_[% Instancename %]_elem *currelement) {
	// free the element
	free(currelement);
}

void (*list_[% Instancename %]_element_free_ptr)(struct list_[% Instancename %]_elem *currelement) = 
	&list_[% Instancename %]_default_element_free;

/////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////
// normal list functions.
/////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////


// the list contains several different "markers"
// the user data of the list is from "first" to "last"
// in the drawing below.
// This is also referred to as "front" to "back".
// you can push data onto the "front" or onto the "back".
//
// There are also forward iterators and reverse iterators.
// the forward iterator goes from "begin" to "end".
// "end" is one element past the last user element in list.
// the reverse iterator goes from "rbegin" to "rend"
// "rend" is one element befor the first user element in list.
// Both "end" and "rend" are non-data elements in the linked list.
// they are allocated but they hold no user data.

// beforefirst	first	last	afterlast
// internal	user....user	internal
//         	front  	back
// 		begin>>>>>>>>>>>end	forward iterator
// rend<<<<<<<<<<<<<<<<<rbegin 		reverse iterator
//
// the list object is a struct that contains two pointers,
// "beforefirst" and "afterlast".

// constructor function
struct	list_[% Instancename %]_list *list_[% Instancename %]_constructor (void) {

	struct list_[% Instancename %]_list *thislist = NULL;
	struct list_[% Instancename %]_elem *beforefirst = NULL;
	struct list_[% Instancename %]_elem *afterlast = NULL;

	// malloc a list object
	thislist = (struct list_[% Instancename %]_list*)malloc(sizeof(struct list_[% Instancename %]_list));
	if(thislist == NULL) {
		list_[% Instancename %]_errorhandler(
			NULL, 
			NULL, 
			"list_[% Instancename %]_constructor was unable to malloc a list, file __FILE__, line __LINE__",
			100
		);  
		return NULL;
	}

	// malloc a single list element, which will be "rend" 
	beforefirst = (struct list_[% Instancename %]_elem*)malloc(sizeof(struct list_[% Instancename %]_elem));
	if(beforefirst == NULL) {
		list_[% Instancename %]_errorhandler(
			thislist, 
			NULL, 
			"list_[% Instancename %]_constructor was unable to malloc rend element, file __FILE__, line __LINE__",
			110
		);  
		return NULL;
	}

	// malloc a single list element, which will be "end" 
	afterlast = (struct list_[% Instancename %]_elem*)malloc(sizeof(struct list_[% Instancename %]_elem));
	if(afterlast == NULL) {
		list_[% Instancename %]_errorhandler(
			thislist, 
			NULL, 
			"list_[% Instancename %]_constructor was unable to malloc end element, file __FILE__, line __LINE__",
			120
		);  
		return NULL;
	}


	// initialize everything
	thislist->beforefirst = beforefirst;
	thislist->afterlast   = afterlast;

	beforefirst->next = afterlast;
	beforefirst->prev = NULL;

	afterlast->next = NULL;
	afterlast->prev = beforefirst;

	// return a pointer to list object
	return thislist;
}

// destructor function
void list_[% Instancename %]_destructor(struct list_[% Instancename %]_list *list) {

	struct list_[% Instancename %]_elem *beginelement, *endelement, *currelement, *nextelement;


	if(list==NULL){
		list_[% Instancename %]_errorhandler(
			NULL, 
			NULL, 
			"list_[% Instancename %]_destructor was given a null list, file __FILE__, line __LINE__",
			200
		);  
		return;
	}

	beginelement = list->beforefirst;
	endelement = list->afterlast;

	currelement=beginelement; 
	while(currelement!=endelement) {

		if(currelement==NULL){
			list_[% Instancename %]_errorhandler(
				list, 
				NULL, 
				"list_[% Instancename %]_destructor encountered null element, file __FILE__, line __LINE__",
				210
			);  
			return;
		}
		// get 'next' pointer because we're about to delete this element.
		nextelement = currelement->next;

		// null out the pointers in this element, then free this element
		currelement->next = NULL;
		currelement->prev = NULL;
		(*list_[% Instancename %]_element_free_ptr)(currelement);

		// next
		currelement = nextelement;
	}

	// free the last element
	endelement->next = NULL;
	endelement->prev = NULL;
	(*list_[% Instancename %]_element_free_ptr)(endelement);
	

	// null out the list pointers and then free the list
	list->beforefirst = NULL;
	list->afterlast   = NULL;
	free(list);
}


// push_front function
void	       list_[% Instancename %]_push_front (
	struct list_[% Instancename %]_list *list,
	[% FOREACH section = payload %][% section.type %] [% section.name %]_in[% UNLESS loop.last %],[% END %]
	[% END %]
){
	if(list == NULL) {
		list_[% Instancename %]_errorhandler(
			NULL, 
			NULL, 
			"list_[% Instancename %]_push_front given a null list, file __FILE__, line __LINE__",
			300
		);  
		return;
	}

	struct list_[% Instancename %]_elem *beforefirst = list->beforefirst;
	struct list_[% Instancename %]_elem *oldfirst    = beforefirst->next;


	struct list_[% Instancename %]_elem *oneelement = NULL;
	oneelement = (struct list_[% Instancename %]_elem*)malloc(sizeof(struct list_[% Instancename %]_elem));
	if(oneelement == NULL) {
		list_[% Instancename %]_errorhandler(
			list, 
			NULL, 
			"list_[% Instancename %]_push_front unable to malloc new element, file __FILE__, line __LINE__",
			310
		);  
		return;
	}

	[% FOREACH section = payload %]oneelement->[% section.name %] = [% section.name %]_in;
	[% END %]

	beforefirst->next = oneelement;
	oneelement->prev = beforefirst;

	oldfirst->prev = oneelement;
	oneelement->next = oldfirst;
}

// push_back function
void	list_[% Instancename %]_push_back (
	struct list_[% Instancename %]_list *list,
	[% FOREACH section = payload %][% section.type %] [% section.name %]_in[% UNLESS loop.last %],[% END %]
	[% END %]
){
	if(list == NULL) {
		list_[% Instancename %]_errorhandler(
			NULL, 
			NULL, 
			"list_[% Instancename %]_push_back given a null list, file __FILE__, line __LINE__",
			400
		);  
		return;
	}

	struct list_[% Instancename %]_elem *afterlast = list->afterlast;
	struct list_[% Instancename %]_elem *oldlast   = afterlast->prev;

	struct list_[% Instancename %]_elem *oneelement = NULL;
	oneelement = (struct list_[% Instancename %]_elem*)malloc(sizeof(struct list_[% Instancename %]_elem));
	if(oneelement == NULL) {
		list_[% Instancename %]_errorhandler(
			list, 
			NULL, 
			"list_[% Instancename %]_push_front unable to malloc new element, file __FILE__, line __LINE__",
			410
		);  
		return;
	}

	[% FOREACH section = payload %]oneelement->[% section.name %] = [% section.name %]_in;
	[% END %]

	oldlast->next = oneelement;
	oneelement->prev = oldlast;

	oneelement->next = afterlast;
	afterlast->prev = oneelement;

}

// pop_front
[% IF payloadsize == 1 %]// only one item in payload, return the value of the payload[% ELSE %]// more than one datum per element, return a pointer to the entire element[% END %]
[% IF payloadsize == 1 %][% FOREACH section = payload %][% section.type %][% END %][% ELSE %]struct list_[% Instancename %]_elem *[% END %]
	list_[% Instancename %]_pop_front (
	struct list_[% Instancename %]_list * list
){
	if(list == NULL) {
		list_[% Instancename %]_errorhandler(
			NULL, 
			NULL, 
			"list_[% Instancename %]_pop_front given a null list, file __FILE__, line __LINE__",
			500
		);  
		[% IF payloadsize == 1 %]
		return ([% section.type %]) 0;
		[% ELSE %]
		return NULL;
		[% END %]
	}

	struct list_[% Instancename %]_elem *beforefirst = list->beforefirst;
	struct list_[% Instancename %]_elem *first = beforefirst->next;
	struct list_[% Instancename %]_elem *second = first->next;

	// popping first element, tie the pointers together to go around it
	beforefirst->next = second;
	second->prev = beforefirst;


	// null out the popped element pointers just in case someone tries to use them later.
	first->next = NULL;
	first->prev = NULL;

	// return value if only one user element in structure. else return pointer to struct
	[% IF payloadsize == 1 %]
	[% FOREACH section = payload %]
	[% section.type %] retval;
	retval = first->[% section.name %];
	(*list_[% Instancename %]_element_free_ptr)(first);
	return retval;
	[% END %]
	[% ELSE %]
	// can't free element, going to return it. User will have to free it when they're done with it.
	return first;
	[% END %]
}

// pop_back
// if only one item in payload, return the value of the payload
// if more than one item, return a pointer to the payload element
[% IF payloadsize == 1 %][% FOREACH section = payload %][% section.type %][% END %][% ELSE %]struct list_[% Instancename %]_elem * [% END %]
	list_[% Instancename %]_pop_back (
	struct list_[% Instancename %]_list * list
){
	if(list == NULL) {
		list_[% Instancename %]_errorhandler(
			NULL, 
			NULL, 
			"list_[% Instancename %]_pop_back given a null list, file __FILE__, line __LINE__",
			600
		);  
		[% IF payloadsize == 1 %]
		return ([% section.type %]) 0;
		[% ELSE %]
		return NULL;
		[% END %]
	}

	struct list_[% Instancename %]_elem *afterlast = list->afterlast;

	if(afterlast == NULL) {
		list_[% Instancename %]_errorhandler(
			list, 
			NULL, 
			"list_[% Instancename %]_pop_back afterlast points to null element, file __FILE__, line __LINE__",
			610
		);  
		[% IF payloadsize == 1 %]
		return ([% section.type %]) 0;
		[% ELSE %]
		return NULL;
		[% END %]
	}

	struct list_[% Instancename %]_elem *last = afterlast->prev;

	if(last == NULL) {
		list_[% Instancename %]_errorhandler(
			list, 
			afterlast, 
			"list_[% Instancename %]_pop_back last points to null element, file __FILE__, line __LINE__",
			620
		);  
		[% IF payloadsize == 1 %]
		return ([% section.type %]) 0;
		[% ELSE %]
		return NULL;
		[% END %]
	}

	struct list_[% Instancename %]_elem *secondtolast = last->prev;

	if(secondtolast == NULL) {
		list_[% Instancename %]_errorhandler(
			list, 
			last, 
			"list_[% Instancename %]_pop_back secondtolast points to null element, file __FILE__, line __LINE__",
			630
		);  
		[% IF payloadsize == 1 %]
		return ([% section.type %]) 0;
		[% ELSE %]
		return NULL;
		[% END %]
	}

	// popped last element, tie other elements to go around it.
	secondtolast->next = afterlast;
	afterlast->prev = secondtolast;

	// null out the popped element pointers just in case someone tries to use them later.
	last->next = NULL;
	last->prev = NULL;

	// return value if only one user element in structure. else return pointer to struct
	[% IF payloadsize == 1 %]
	[% FOREACH section = payload %]
	[% section.type %] retval;
	retval = last->[% section.name %];
	(*list_[% Instancename %]_element_free_ptr)(last);
	return retval;
	[% END %]
	[% ELSE %]
	// can't free element, going to return it. User will have to free it when they're done with it.
	return last;
	[% END %]
}



// plusplus and minusminus are iterator-related functions.
// they take an element and increment or decrement to the associated element in the list.
// they also do some error checking.
// in C++ code you'll see this as 
//
// list<int>::iterator it=mylist.begin()
// it++;
//
// In c code, you'll do it like this:
//
// list_[% Instancename %]_elem *it=mylist.begin();
// it=list_[% Instancename %]_elem_plusplus(mylist, it);
//
// Unfortunately, there's no easy way to do this:
//
// list_[% Instancename %]_elem_plusplus(it);
//
// where the function modifies in place what "it" points to.
// So you have to use the  it = func(it)  format.
//
// we could make an "iterator type" a pointer to a pointer to an element,
// which would allow us to do a  plusplus(it)  call without a return value,
// but then we couldn't do a simple comparison in our "for" loops and so on,
// as shown below.
//
// FYI: The "list" that the iterator/element belongs to is passed in for 
// error reporting purposes only.


// increment to next element
struct 	list_[% Instancename %]_elem *
	list_[% Instancename %]_elem_plusplus(
	struct list_[% Instancename %]_list *list, 
	struct list_[% Instancename %]_elem *elem 
) {
	if(list == NULL) {
		list_[% Instancename %]_errorhandler(
			NULL, 
			NULL, 
			"list_[% Instancename %]_elem_plusplus given a null list, file __FILE__, line __LINE__",
			700
		);  
		return NULL;
	}

	if(elem == NULL) {
		list_[% Instancename %]_errorhandler(
			list, 
			NULL, 
			"list_[% Instancename %]_elem_plusplus given a null element, file __FILE__, line __LINE__",
			710
		);  
		return NULL;
	}

	struct list_[% Instancename %]_elem *temp = elem->next;
	if(temp==NULL) {
		list_[% Instancename %]_errorhandler(
			list, 
			elem, 
			"list_[% Instancename %]_elem_plusplus incremented to a null element, file __FILE__, line __LINE__",
			720
		);  
		return NULL;
	}
	return temp;
}

// decrement to prev element
struct list_[% Instancename %]_elem *list_[% Instancename %]_elem_minusminus(
	struct list_[% Instancename %]_list *list, 
	struct list_[% Instancename %]_elem *elem 
) {
	if(list == NULL) {
		list_[% Instancename %]_errorhandler(
			NULL, 
			NULL, 
			"list_[% Instancename %]_elem_minusminus given a null list, file __FILE__, line __LINE__",
			730
		);  
		return NULL;
	}

	if(elem == NULL) {
		list_[% Instancename %]_errorhandler(
			list, 
			NULL, 
			"list_[% Instancename %]_elem_minusminus given a null element, file __FILE__, line __LINE__",
			740
		);  
		return NULL;
	}

	struct list_[% Instancename %]_elem *temp = elem->prev;
	if(temp == NULL) {
		list_[% Instancename %]_errorhandler(
			list, 
			elem, 
			"list_[% Instancename %]_elem_minusminus decremented to a null element, file __FILE__, line __LINE__",
			750
		);  
		return NULL;
	}

	return temp;
}

// increment by N elements
struct list_[% Instancename %]_elem *list_[% Instancename %]_elem_increment(
	struct list_[% Instancename %]_list *list, 
	struct list_[% Instancename %]_elem *elem, 
	unsigned int incval
) {
	if(list == NULL) {
		list_[% Instancename %]_errorhandler(
			NULL, 
			NULL, 
			"list_[% Instancename %]_elem_increment given a null list, file __FILE__, line __LINE__",
			760
		);  
		return NULL;
	}

	if(elem == NULL) {
		list_[% Instancename %]_errorhandler(
			list, 
			NULL, 
			"list_[% Instancename %]_elem_increment given a null element, file __FILE__, line __LINE__",
			770
		);  
		return NULL;
	}

	struct list_[% Instancename %]_elem *temp;

	int i;
	for(i=0; i<incval; i=i+1) {

		temp=list_[% Instancename %]_elem_plusplus(list, temp);
		if(temp==NULL) {
			list_[% Instancename %]_errorhandler(
				list, 
				elem, 
				"list_[% Instancename %]_elem_increment incremented to a null element, file __FILE__, line __LINE__",
				790
			);  
			return NULL;
		}
	}
	return temp;
}

// decrement by N elements
struct 	list_[% Instancename %]_elem *list_[% Instancename %]_elem_decrement(
	struct list_[% Instancename %]_list *list, 
	struct list_[% Instancename %]_elem *elem, 
	unsigned int decval
) {
	if(list == NULL) {
		list_[% Instancename %]_errorhandler(
			NULL, 
			NULL, 
			"list_[% Instancename %]_elem_decrement given a null list, file __FILE__, line __LINE__",
			800
		);  
		return NULL;
	}

	if(elem == NULL) {
		list_[% Instancename %]_errorhandler(
			list, 
			NULL, 
			"list_[% Instancename %]_elem_decrement given a null element, file __FILE__, line __LINE__",
			810
		);  
		return NULL;
	}

	struct list_[% Instancename %]_elem *temp;

	int i;
	for(i=0; i<decval; i=i+1) {

		temp=list_[% Instancename %]_elem_minusminus(list, temp);
		if(temp==NULL) {
			list_[% Instancename %]_errorhandler(
				list, 
				elem, 
				"list_[% Instancename %]_elem_decrement decremented to a null element, file __FILE__, line __LINE__",
				820
			);  
			return NULL;
		}
	}
	return temp;
}

// advance by N elements, where N can be positive or negative
struct 	list_[% Instancename %]_elem *list_[% Instancename %]_elem_advance(
	struct list_[% Instancename %]_list *list, 
	struct list_[% Instancename %]_elem *elem, 
	unsigned int advanceval
) {
	if(list == NULL) {
		list_[% Instancename %]_errorhandler(
			NULL, 
			NULL, 
			"list_[% Instancename %]_elem_advance given a null list, file __FILE__, line __LINE__",
			900
		);  
		return NULL;
	}

	if(elem == NULL) {
		list_[% Instancename %]_errorhandler(
			list, 
			NULL, 
			"list_[% Instancename %]_elem_advance given a null element, file __FILE__, line __LINE__",
			910
		);  
		return NULL;
	}

	struct list_[% Instancename %]_elem *temp;
	int posval;

	if(advanceval<0) {
		posval = -1 * advanceval;
		temp = list_[% Instancename %]_elem_decrement(list, elem, posval);
	} else {
		temp = list_[% Instancename %]_elem_increment(list, elem, advanceval);
	}
	
	if(temp==NULL){
		list_[% Instancename %]_errorhandler(
			list, 
			elem, 
			"list_[% Instancename %]_elem_advance advanced to a null element, file __FILE__, line __LINE__",
			920
		);  
		return NULL;
	}

	return temp;
}


// note: for the marker functions below, can use them sort of like iterator in C++.
// Sort of, but not quite. For example, in C++, markers are used like this:
//
// list<int>::iterator it;
// for ( it=mylist.begin() ; it != mylist.end(); it++ )
//	{ code that does something to "it" }
//
// In regular c, markers are used like this:
//
// list_[% Instancename %]_elem *it;
// for( it=list_[% Instancename %]_begin(mylist); it != list_[% Instancename %]_end(mylist); it=list_[% Instancename %]_elem_plusplus(it) )
//	{ code that does something to "it" }
// 	
// The idea apparently is that by testing for the "end" marker rather than "NULL", 
// we are more likely to trap pointer-to-null errors, possible memory leaks, and such.
// User is more likely to accidentally set a pointer in an element to NULL 
// than to accidentally set it to "end" marker

// function returns "begin" marker
struct list_[% Instancename %]_elem *list_[% Instancename %]_begin (struct list_[% Instancename %]_list *list) {
	if(list==NULL) {
		list_[% Instancename %]_errorhandler(
			NULL, 
			NULL, 
			"list_[% Instancename %]_elem_begin function received null list, file __FILE__, line __LINE__",
			930
		);  
		return NULL;
	}
	struct list_[% Instancename %]_elem *temp = list->beforefirst;
	if(temp==NULL) {
		list_[% Instancename %]_errorhandler(
			list, 
			NULL, 
			"list_[% Instancename %]_elem_begin beforefirst marker is null, file __FILE__, line __LINE__",
			940
		);  
		return NULL;
	}
	temp = temp->next;
	if(temp==NULL) {
		list_[% Instancename %]_errorhandler(
			list, 
			NULL, 
			"list_[% Instancename %]_elem_begin begin marker is null, file __FILE__, line __LINE__",
			950
		);  
		return NULL;
	}
	return temp;
}

// function returns "end" marker
struct list_[% Instancename %]_elem *list_[% Instancename %]_end (struct list_[% Instancename %]_list *list) {
	if(list==NULL) {
		list_[% Instancename %]_errorhandler(
			NULL, 
			NULL, 
			"list_[% Instancename %]_elem_end function received null list, file __FILE__, line __LINE__",
			1000
		);  
		return NULL;
	}
	struct list_[% Instancename %]_elem *temp = list->afterlast;
	if(temp==NULL) {
		list_[% Instancename %]_errorhandler(
			list, 
			NULL, 
			"list_[% Instancename %]_elem_end afterlast marker is null, file __FILE__, line __LINE__",
			1100
		);  
		return NULL;
	}
	return temp;
}

// function returns "rbegin" marker
struct list_[% Instancename %]_elem *list_[% Instancename %]_rbegin (struct list_[% Instancename %]_list *list) {
	if(list==NULL) {
		list_[% Instancename %]_errorhandler(
			NULL, 
			NULL, 
			"list_[% Instancename %]_elem_rbegin function received null list, file __FILE__, line __LINE__",
			1200
		);  
		return NULL;
	}
	struct list_[% Instancename %]_elem *temp = list->afterlast;
	if(temp==NULL) {
		list_[% Instancename %]_errorhandler(
			list, 
			NULL, 
			"list_[% Instancename %]_elem_rbegin afterlast marker is null, file __FILE__, line __LINE__",
			1210
		);  
		return NULL;
	}
	temp = temp->prev;
	if(temp==NULL) {
		list_[% Instancename %]_errorhandler(
			list, 
			NULL, 
			"list_[% Instancename %]_elem_rbegin last marker is null, file __FILE__, line __LINE__",
			1220
		);  
		return NULL;
	}
	return temp;
}

// function returns "rend" marker
struct list_[% Instancename %]_elem *list_[% Instancename %]_rend (struct list_[% Instancename %]_list *list) {
	if(list==NULL) {
		list_[% Instancename %]_errorhandler(
			NULL, 
			NULL, 
			"list_[% Instancename %]_elem_rend function received null list, file __FILE__, line __LINE__",
			1300
		);  
		return NULL;
	}
	struct list_[% Instancename %]_elem *temp = list->beforefirst;
	if(temp==NULL) {
		list_[% Instancename %]_errorhandler(
			list, 
			NULL, 
			"list_[% Instancename %]_elem_rend beforefirst marker is null, file __FILE__, line __LINE__",
			1310
		);  
		return NULL;
	}
	return temp;
}

// not iterator markers, but general markers from C++ class

// function returns "front" marker (first user element)
struct list_[% Instancename %]_elem *list_[% Instancename %]_front (struct list_[% Instancename %]_list *list) {
	if(list==NULL) {
		list_[% Instancename %]_errorhandler(
			NULL, 
			NULL, 
			"list_[% Instancename %]_elem_front function received null list, file __FILE__, line __LINE__",
			1400
		);  
		return NULL;
	}
	struct list_[% Instancename %]_elem *temp = list->beforefirst;
	if(temp==NULL) {
		list_[% Instancename %]_errorhandler(
			list, 
			NULL, 
			"list_[% Instancename %]_elem_front beforefirst marker is null, file __FILE__, line __LINE__",
			1410
		);  
		return NULL;
	}
	temp = temp->next;
	if(temp==NULL) {
		list_[% Instancename %]_errorhandler(
			list, 
			NULL, 
			"list_[% Instancename %]_elem_front first marker is null, file __FILE__, line __LINE__",
			1420
		);  
		return NULL;
	}
	return temp;
}

// function returns "back" marker (last user element)
struct list_[% Instancename %]_elem *list_[% Instancename %]_back (struct list_[% Instancename %]_list *list) {
	if(list==NULL) {
		list_[% Instancename %]_errorhandler(
			NULL, 
			NULL, 
			"list_[% Instancename %]_elem_back function received null list, file __FILE__, line __LINE__",
			1500
		);  
		return NULL;
	}
	struct list_[% Instancename %]_elem *temp = list->afterlast;
	if(temp==NULL) {
		list_[% Instancename %]_errorhandler(
			list, 
			NULL, 
			"list_[% Instancename %]_elem_front afterlast marker is null, file __FILE__, line __LINE__",
			1510
		);  
		return NULL;
	}
	temp = temp->prev;
	if(temp==NULL) {
		list_[% Instancename %]_errorhandler(
			list, 
			NULL, 
			"list_[% Instancename %]_elem_front last marker is null, file __FILE__, line __LINE__",
			1520
		);  
		return NULL;
	}
	return temp;
}



// forward iterator to run a callback on every user element in linked list.
void list_[% Instancename %]_iterator(struct list_[% Instancename %]_list *list, void (*callback)(struct list_[% Instancename %]_elem *)) {
	if(list==NULL) {
		list_[% Instancename %]_errorhandler(
			NULL, 
			NULL, 
			"list_[% Instancename %]_iterator function received null list, file __FILE__, line __LINE__",
			1600
		);  
		return;
	}

	struct list_[% Instancename %]_elem *beginelement, *endelement, *currelement, *nextelement;

	currelement = list->beforefirst;
	beginelement = currelement->next;

	endelement = list->afterlast;

	currelement=beginelement; 
	while(currelement!=endelement) {

		if(currelement==NULL){
			list_[% Instancename %]_errorhandler(
				list, 
				NULL, 
				"list_[% Instancename %]_iterator currelement is null, file __FILE__, line __LINE__",
				1610
			);  
			return;
		}
		// get the next element pointed to before we call the callback.
		// this will allow the callback to do anything it wants, 
		// including destroying the element.
		nextelement = currelement->next;

		(*callback)(currelement);

		currelement = nextelement;
	}
	
}

// reverse iterator to run a callback on every user element in linked list.
// it doesn't test for "NULL" because "NULL" could indicate a memory leak.
// instead, loop until we reach the rend element (before first), then stop.
void	       list_[% Instancename %]_reverse_iterator(
	struct list_[% Instancename %]_list *list,
	void (*callback)(struct list_[% Instancename %]_elem *)
) {
	if(list==NULL) {
		list_[% Instancename %]_errorhandler(
			NULL, 
			NULL, 
			"list_[% Instancename %]_reverse_iterator function received null list, file __FILE__, line __LINE__",
			1700
		);  
		return;
	}

	struct list_[% Instancename %]_elem *beginelement, *endelement, *currelement, *nextelement;

	currelement = list->afterlast;
	beginelement = currelement->prev;

	endelement = list->beforefirst;

	currelement=beginelement; 
	while(currelement!=endelement) {

		if(currelement==NULL){
			list_[% Instancename %]_errorhandler(
				list, 
				NULL, 
				"list_[% Instancename %]_reverse_iterator currelement is null, file __FILE__, line __LINE__",
				1710
			);  
			return;
		}
		// get the next element pointed to before we call the callback.
		// this will allow the callback to do anything it wants, 
		// including destroying the element.
		nextelement = currelement->prev;

		(*callback)(currelement);

		currelement = nextelement;
	}
	
}


// "empty" function
// return 1 if list is empty, else return 0
int list_[% Instancename %]_empty(struct list_[% Instancename %]_list *list) {
	if(list==NULL) {
		list_[% Instancename %]_errorhandler(
			NULL, 
			NULL, 
			"list_[% Instancename %]_empty function received null list, file __FILE__, line __LINE__",
			1800
		);  
		return 1;
	}
	struct list_[% Instancename %]_elem *beforefirst = list->beforefirst;
	if(beforefirst==NULL){
		list_[% Instancename %]_errorhandler(
			list, 
			NULL, 
			"list_[% Instancename %]_empty beforefirst is null, file __FILE__, line __LINE__",
			1810
		);  
		return 1;
	}
	struct list_[% Instancename %]_elem *first       = beforefirst->next;
	if(first==NULL){
		list_[% Instancename %]_errorhandler(
			list, 
			NULL, 
			"list_[% Instancename %]_empty first is null, file __FILE__, line __LINE__",
			1820
		);  
		return 1;
	}
	struct list_[% Instancename %]_elem *afterlast   = list->afterlast;
	if(afterlast==NULL){
		list_[% Instancename %]_errorhandler(
			list, 
			NULL, 
			"list_[% Instancename %]_empty afterlast is null, file __FILE__, line __LINE__",
			1830
		);  
		return 1;
	}

	if(first == afterlast) {
		return 1;
	} else {
		return 0;
	}
}

// size function
// return size of list
int list_[% Instancename %]_size(struct list_[% Instancename %]_list *list) {
	if(list==NULL) {
		list_[% Instancename %]_errorhandler(
			NULL, 
			NULL, 
			"list_[% Instancename %]_size function received null list, file __FILE__, line __LINE__",
			1900
		);  
		return 0;
	}
	struct list_[% Instancename %]_elem *mybegin = list_[% Instancename %]_begin(list);
	if(mybegin==NULL){
		list_[% Instancename %]_errorhandler(
			list, 
			NULL, 
			"list_[% Instancename %]_size mybegin is null, file __FILE__, line __LINE__",
			1910
		);  
		return 0;
	}
	struct list_[% Instancename %]_elem *myend   = list_[% Instancename %]_end(list);
	if(myend==NULL){
		list_[% Instancename %]_errorhandler(
			list, 
			NULL, 
			"list_[% Instancename %]_size myend is null, file __FILE__, line __LINE__",
			1920
		);  
		return 0;
	}
	struct list_[% Instancename %]_elem *it;

	int count=0;

	for( it=mybegin; it != myend; it=it->next ) {
		count=count+1;
		if(it==NULL) {
			list_[% Instancename %]_errorhandler(
				list, 
				NULL, 
				"list_[% Instancename %]_size it pointer is null, file __FILE__, line __LINE__",
				1930
			);  
			return 0;
		}
	}

	return count;
}



// given a list, make a shallow copy of it.
// Note that if the list holds plain data, this will create a completely new unrelated list.
// If the list holds pointers, then those pointers will NOT get deep-copied.
// if you want a deep copy, roll your own.
struct list_[% Instancename %]_list *list_[% Instancename %]_shallow_copy(struct list_[% Instancename %]_list *existinglist) {
	if(existinglist==NULL) {
		list_[% Instancename %]_errorhandler(
			NULL, 
			NULL, 
			"list_[% Instancename %]_shallow_copy function received null list, file __FILE__, line __LINE__",
			2000
		);  
		return NULL;
	}
	struct list_[% Instancename %]_list *newlist = NULL;
	struct list_[% Instancename %]_elem *it = NULL;

	// create a list
	newlist = list_[% Instancename %]_constructor();
	if(newlist == NULL) {
		list_[% Instancename %]_errorhandler(
			existinglist, 
			NULL, 
			"list_[% Instancename %]_shallow_copy newlist pointer is null, file __FILE__, line __LINE__",
			2010
		);  
		return NULL;
	}

	// list_[% Instancename %]_elem *it;
	// for( it=list_[% Instancename %]_begin(mylist); it != list_[% Instancename %]_end(mylist); it=it->next )
	//	{ code that does something to "it" }
	for(it=list_[% Instancename %]_begin(existinglist); it != list_[% Instancename %]_end(existinglist); it=it->next) {
		if(it==NULL) {
			list_[% Instancename %]_errorhandler(
				existinglist, 
				NULL, 
				"list_[% Instancename %]_shallow_copy it pointer is null, file __FILE__, line __LINE__",
				2020
			);  
			return NULL;
		}
		list_[% Instancename %]_push_back (
			existinglist,
			[% FOREACH section = payload %]it->[% section.name %][% UNLESS loop.last %],[% END %]
			[% END %]	
		);
	}

	return newlist;
}


// "insert" function
void	       list_[% Instancename %]_insert (
	struct list_[% Instancename %]_list *list,
	struct list_[% Instancename %]_elem *currentelement,
	[% FOREACH section = payload %][% section.type %] [% section.name %]_in[% UNLESS loop.last %],[% END %]
	[% END %]
){
	if(list==NULL) {
		list_[% Instancename %]_errorhandler(
			NULL, 
			NULL, 
			"list_[% Instancename %]_insert function received null list, file __FILE__, line __LINE__",
			2100
		);  
		return;
	}

	struct list_[% Instancename %]_elem *prevelem = currentelement->prev;

	if(prevelem==NULL){
		list_[% Instancename %]_errorhandler(
			list, 
			NULL, 
			"list_[% Instancename %]_insert prevelem is null, file __FILE__, line __LINE__",
			2110
		);  
		return;
	}

	struct list_[% Instancename %]_elem *newelement = NULL;
	newelement = (struct list_[% Instancename %]_elem*)malloc(sizeof(struct list_[% Instancename %]_elem));
	if(newelement == NULL) {
		list_[% Instancename %]_errorhandler(
			list, 
			NULL, 
			"list_[% Instancename %]_insert newelement is null, file __FILE__, line __LINE__",
			2120
		);  
		return;
	}

	[% FOREACH section = payload %]newelement->[% section.name %] = [% section.name %]_in;
	[% END %]

	prevelem->next = newelement;
	newelement->prev = prevelem;

	newelement->next = currentelement;
	currentelement->prev = newelement;
}

// "insert n" function
// cant overload functions in C, have to use a different function name
void	       list_[% Instancename %]_insert_n (
	struct list_[% Instancename %]_list *list,
	unsigned int count,
	struct list_[% Instancename %]_elem *currentelement,
	[% FOREACH section = payload %][% section.type %] [% section.name %]_in[% UNLESS loop.last %],[% END %]
	[% END %]
){
	if(list==NULL) {
		list_[% Instancename %]_errorhandler(
			NULL, 
			NULL, 
			"list_[% Instancename %]_insert_n function received null list, file __FILE__, line __LINE__",
			2200
		);  
		return;
	}
	int iter;
	for(iter=0; iter<count; iter=iter+1) {
		 list_[% Instancename %]_insert (
			list,
			currentelement,
			[% FOREACH section = payload %][% section.name %]_in[% UNLESS loop.last %],[% END %]
			[% END %]
		);
	}
}

// "erase" function
// delete one element being pointed to
struct list_[% Instancename %]_elem *
	       list_[% Instancename %]_erase (
	struct list_[% Instancename %]_list *list,
	struct list_[% Instancename %]_elem *currentelement
){
	if(list==NULL) {
		list_[% Instancename %]_errorhandler(
			NULL, 
			NULL, 
			"list_[% Instancename %]_erase function received null list, file __FILE__, line __LINE__",
			2300
		);  
		return NULL;
	}

	if(currentelement==NULL) {
		list_[% Instancename %]_errorhandler(
			list, 
			NULL, 
			"list_[% Instancename %]_erase function received null currentelement, file __FILE__, line __LINE__",
			2310
		);  
		return NULL;
	}

	struct list_[% Instancename %]_elem *prevelem = currentelement->prev;
	struct list_[% Instancename %]_elem *nextelem = currentelement->next;

	if(prevelem==NULL) {
		list_[% Instancename %]_errorhandler(
			list, 
			currentelement, 
			"list_[% Instancename %]_erase function prevelem is null, file __FILE__, line __LINE__",
			2320
		);  
		return NULL;
	}

	if(nextelem==NULL){
		list_[% Instancename %]_errorhandler(
			list, 
			currentelement, 
			"list_[% Instancename %]_erase function nextelem is null, file __FILE__, line __LINE__",
			2330
		);  
		return NULL;
	}

	// null out the popped element pointers just in case someone tries to use them later.
	currentelement->next = NULL;
	currentelement->prev = NULL;
	(*list_[% Instancename %]_element_free_ptr)(currentelement);

	return nextelem;
}

// "erase n" function
// cant overload functions in C, have to use a different function name
struct list_[% Instancename %]_elem *
	       list_[% Instancename %]_erase_n (
	struct list_[% Instancename %]_list *list,
	unsigned int count,
	struct list_[% Instancename %]_elem *currentelement
){
	if(list==NULL) {
		list_[% Instancename %]_errorhandler(
			NULL, 
			NULL, 
			"list_[% Instancename %]_erase_n function received null list, file __FILE__, line __LINE__",
			2400
		);  
		return NULL;
	}

	if(currentelement==NULL) {
		list_[% Instancename %]_errorhandler(
			list, 
			NULL, 
			"list_[% Instancename %]_erase_n function received null currentelement, file __FILE__, line __LINE__",
			2410
		);  
		return NULL;
	}
	struct list_[% Instancename %]_elem *retval = currentelement;

	int iter;
	for(iter=0; iter<count; iter=iter+1) {
		retval = list_[% Instancename %]_erase (list,retval);
		if(retval==NULL) {
			list_[% Instancename %]_errorhandler(
				list, 
				NULL, 
				"list_[% Instancename %]_erase_n function retval is null, file __FILE__, line __LINE__",
				2420
			);  
			return NULL;
		}
	}
	return retval;
}


// "swap" function
// swap contents of two lists.
void	       list_[% Instancename %]_swap (
	struct list_[% Instancename %]_list *list1,
	struct list_[% Instancename %]_list *list2
){
	struct list_[% Instancename %]_elem *temp1;
	struct list_[% Instancename %]_elem *temp2;
	
	if(list1==NULL) {
		list_[% Instancename %]_errorhandler(
			NULL, 
			NULL, 
			"list_[% Instancename %]_swap function received null list1, file __FILE__, line __LINE__",
			2500
		);  
		return;
	}
	if(list2==NULL) {
		list_[% Instancename %]_errorhandler(
			NULL, 
			NULL, 
			"list_[% Instancename %]_swap function received null list2, file __FILE__, line __LINE__",
			2510
		);  
		return;
	}
	temp1=list1->beforefirst;
	temp2=list1->afterlast;

	list1->beforefirst = list2->beforefirst;
	list1->afterlast   = list2->afterlast;

	list2->beforefirst = temp1;
	list2->afterlast   = temp2;
}


// "clear" callback used by "clear" function
void callback_list_[% Instancename %]_clear(struct list_[% Instancename %]_elem *currelem){
	struct list_[% Instancename %]_elem *elemprev;
	struct list_[% Instancename %]_elem *elemnext;

	// find next and prev elements
	elemprev = currelem->prev;
	elemnext = currelem->next;

	// error check
	if(elemprev==NULL) {
		list_[% Instancename %]_errorhandler(
			NULL, 
			NULL, 
			"list_[% Instancename %]_clear function elemprev is null, file __FILE__, line __LINE__",
			2600
		);  
		return;
	}

	if(elemnext==NULL){
		list_[% Instancename %]_errorhandler(
			NULL, 
			NULL, 
			"list_[% Instancename %]_clear function elemnext is null, file __FILE__, line __LINE__",
			2610
		);  
		return;
	}

	// set prev/next elements to point to each other, going around current element
	elemprev->next = elemnext;
	elemnext->prev = elemprev;

	// set current pointers to null in case anyone tries to use them in future.
	currelem->prev = NULL;
	currelem->next = NULL;

	// free current element
	(*list_[% Instancename %]_element_free_ptr)(currelem);
}

// "clear" function
// empties the contents of a list, call destructors on all its elements
void	       list_[% Instancename %]_clear (
	struct list_[% Instancename %]_list *list
){
	if(list==NULL) {
		list_[% Instancename %]_errorhandler(
			NULL, 
			NULL, 
			"list_[% Instancename %]_clear function received null list, file __FILE__, line __LINE__",
			2700
		);  
		return;
	}
	list_[% Instancename %]_iterator(list, &callback_list_[% Instancename %]_clear);
}

/////////////////////////////////////////////////////////////////////
// compare function for sorting
/////////////////////////////////////////////////////////////////////

// this is the default element compare function (used for sorting, etc)
// do a simple numeric compare of first record in element.
// return -1 if alpha <  bravo
// return  0 if alpha == bravo
// return  1 if alpha >  bravo
int list_[% Instancename %]_default_compare(struct list_[% Instancename %]_elem *alpha, struct list_[% Instancename %]_elem *bravo){
	if(alpha==NULL) {
		list_[% Instancename %]_errorhandler(
			NULL, 
			NULL, 
			"list_[% Instancename %]_default_compare function received null alpha element, file __FILE__, line __LINE__",
			2800
		);  
		return 0;
	}

	if(bravo==NULL) {
		list_[% Instancename %]_errorhandler(
			NULL, 
			NULL, 
			"list_[% Instancename %]_default_compare function received null bravo element, file __FILE__, line __LINE__",
			2810
		);  
		return 0;
	}

	[% FOREACH section = payload %]
	[% section.type %] alphaval = alpha->[% section.name %];
	[% section.type %] bravoval = bravo->[% section.name %];
	[% LAST %]
	[% END %]

	int retval=3;

	if(alphaval == bravoval) { retval=0; }
	if(alphaval <  bravoval) { retval=-1; }
	if(alphaval >  bravoval) { retval=1; }

	return retval;
}

// all sorts use this pointer to a comparator function
// this allows the code to set it to a default
// and also allows the user to assign the pointer
// to point to their own comparator
// This allows user to change compare behaviour
// without changing any code in this file
int (*list_[% Instancename %]_compare_ptr)(struct list_[% Instancename %]_elem *, struct list_[% Instancename %]_elem *) = &list_[% Instancename %]_default_compare;


// "merge" function
// take two sorted lists (alpha and bravo) and merge all elements of bravo into 
// alpha so that alpha is still sorted. At the end, bravo list is empty.
// will use "list_[% Instancename %]_compare_ptr", so declare that first
void	       list_[% Instancename %]_merge (
	struct list_[% Instancename %]_list *alpha,
	struct list_[% Instancename %]_list *bravo
){

	if(alpha==NULL) {
		list_[% Instancename %]_errorhandler(
			NULL, 
			NULL, 
			"list_[% Instancename %]_merge function received null alpha list, file __FILE__, line __LINE__",
			2900
		);  
		return;
	}
	if(bravo==NULL) {
		list_[% Instancename %]_errorhandler(
			NULL, 
			NULL, 
			"list_[% Instancename %]_merge function received null bravo list, file __FILE__, line __LINE__",
			2910
		);  
		return;
	}
	struct list_[% Instancename %]_elem *alphaiter;
	struct list_[% Instancename %]_elem *bravoiter, *bravoiternext;

	struct list_[% Instancename %]_elem *alphabeforefirst;
	struct list_[% Instancename %]_elem *alphaafterlast;

	struct list_[% Instancename %]_elem *bravobeforefirst;
	struct list_[% Instancename %]_elem *bravoafterlast;

	struct list_[% Instancename %]_elem *alphaprev;
	int	cmpval;

	// get markers for alpha list
	alphabeforefirst = alpha->beforefirst;

	if(alphabeforefirst==NULL){
		list_[% Instancename %]_errorhandler(
			alpha, 
			NULL, 
			"list_[% Instancename %]_merge function alphabeforefirst is null, file __FILE__, line __LINE__",
			2920
		);  
		return;
	}


	alphaafterlast = alpha->afterlast;

	if(alphaafterlast==NULL){
		list_[% Instancename %]_errorhandler(
			alpha, 
			NULL, 
			"list_[% Instancename %]_merge function alphaafterlast is null, file __FILE__, line __LINE__",
			2930
		);  
		return;
	}


	// get markers for bravo list
	bravobeforefirst = bravo->beforefirst;

	if(bravobeforefirst==NULL){
		list_[% Instancename %]_errorhandler(
			bravo, 
			NULL, 
			"list_[% Instancename %]_merge function bravobeforefirst is null, file __FILE__, line __LINE__",
			2940
		);  
		return;
	}


	bravoafterlast = bravo->afterlast;

	if(bravoafterlast==NULL){
		list_[% Instancename %]_errorhandler(
			bravo, 
			NULL, 
			"list_[% Instancename %]_merge function bravoafterlast is null, file __FILE__, line __LINE__",
			2950
		);  
		return;
	}


	// initialize the iterators
	alphaiter=alphabeforefirst->next;
	bravoiter=bravobeforefirst->next;

	// error check
	if(alphaiter==NULL){
		list_[% Instancename %]_errorhandler(
			alpha, 
			NULL, 
			"list_[% Instancename %]_merge function alphaiter is null, file __FILE__, line __LINE__",
			2960
		);  
		return;
	}

	if(bravoiter==NULL){
		list_[% Instancename %]_errorhandler(
			bravo, 
			NULL, 
			"list_[% Instancename %]_merge function bravoiter is null, file __FILE__, line __LINE__",
			2970
		);  
		return;
	}

	while(bravoiter != bravoafterlast) {

		if(alphaiter == alphaafterlast) {
			// if at end of alpha list, then always take bravo element
			cmpval = 1;
		} else {
			// return -1 if alpha <  bravo
			// return  0 if alpha == bravo
			// return  1 if alpha >  bravo
			cmpval = (*list_[% Instancename %]_compare_ptr)(alphaiter, bravoiter);
		}
		if(cmpval == 1){ 	// if bravo element should be next

			// note that when we move an element from bravo to alpha,
			// bravoiterator starts pointing at bravolist, but ends up pointing at alpha list.
			// so just before we move bravoiter, we need to get the next element
			// and keep it as bravoiternext.
			bravoiternext=bravoiter->next;
	
			alphaprev = alphaiter->prev;
			
			alphaprev->next = bravoiter;
			bravoiter->prev = alphaprev;

			bravoiter->next = alphaiter;
			alphaiter->prev = bravoiter;

			// now restore bravoiter to point to bravo list
			bravoiter = bravoiternext;

			if(bravoiter==NULL){
				list_[% Instancename %]_errorhandler(
					bravo, 
					NULL, 
					"list_[% Instancename %]_merge function bravoiter is null, file __FILE__, line __LINE__",
					2980
				);  
				return;
			}

		} else {		// otherwise alpha element should be next

			alphaiter = alphaiter->next;

			if(alphaiter==NULL){
				list_[% Instancename %]_errorhandler(
					alpha, 
					NULL, 
					"list_[% Instancename %]_merge function alphaiter is null, file __FILE__, line __LINE__",
					2990
				);  
				return;
			}
		}

	}

	// bravo list should be empty when we're done, so make it empty
	bravobeforefirst->next = bravoafterlast;
	bravoafterlast->prev = bravobeforefirst;

}
 
// this is a function used specifically by the "merge_sort" algorithm.
// take one full list and one empty list and split full list in half
// putting second half into what was the empty list.
void	       list_[% Instancename %]_split_list_down_the_middle (
	struct list_[% Instancename %]_list *full,
	struct list_[% Instancename %]_list *empty,
	int middle
){
	if(full==NULL) {
		list_[% Instancename %]_errorhandler(
			NULL, 
			NULL, 
			"list_[% Instancename %]_split... function received null full list, file __FILE__, line __LINE__",
			3000
		);  
		return;
	}
	if(empty==NULL) {
		list_[% Instancename %]_errorhandler(
			NULL, 
			NULL, 
			"list_[% Instancename %]_split... function received null empty list, file __FILE__, line __LINE__",
			3010
		);  
		return;
	}
	struct list_[% Instancename %]_elem *fulllast;
	struct list_[% Instancename %]_elem *fullafterlast;
	struct list_[% Instancename %]_elem *emptyfirst;
	struct list_[% Instancename %]_elem *emptybeforefirst;
	struct list_[% Instancename %]_elem *emptylast;
	struct list_[% Instancename %]_elem *emptyafterlast;

	int iter;




	fullafterlast = full->afterlast;
	if(fullafterlast==NULL){
		list_[% Instancename %]_errorhandler(
			full, 
			NULL, 
			"list_[% Instancename %]_split... function fullafterlast is null, file __FILE__, line __LINE__",
			3013
		);  
		return;
	}

	// emptylast will be fulllast
	// we just haven't hooked it up that way yet.
	emptylast = fullafterlast->prev;
	if(emptylast==NULL){
		list_[% Instancename %]_errorhandler(
			full, 
			NULL, 
			"list_[% Instancename %]_split... function emptylast is null, file __FILE__, line __LINE__",
			3018
		);  
		return;
	}




	fulllast = full->beforefirst;
	if(fulllast==NULL){
		list_[% Instancename %]_errorhandler(
			full, 
			NULL, 
			"list_[% Instancename %]_split... function fulllast is null, file __FILE__, line __LINE__",
			3020
		);  
		return;
	}

	for(iter=1; iter<=middle; iter=iter+1){
		fulllast=fulllast->next;

		if(fulllast==NULL){
			list_[% Instancename %]_errorhandler(
				full, 
				NULL, 
				"list_[% Instancename %]_split... function fulllast is null, file __FILE__, line __LINE__",
				3030
			);  
			return;
		}

		if(fulllast==fullafterlast){
			// report error?
			// hit end of list before hitting middle
			list_[% Instancename %]_errorhandler(
				full, 
				NULL, 
				"list_[% Instancename %]_split... function fulllast is null, file __FILE__, line __LINE__",
				3040
			);  
			return;
		}
	}

	emptyfirst = fulllast->next;

	if(emptyfirst==NULL){
		list_[% Instancename %]_errorhandler(
			empty, 
			NULL, 
			"list_[% Instancename %]_split... function emptyfirst is null, file __FILE__, line __LINE__",
			3050
		);  
		return;
	}

	emptyafterlast = empty->afterlast;
	if(emptyafterlast==NULL){
		list_[% Instancename %]_errorhandler(
			empty, 
			NULL, 
			"list_[% Instancename %]_split... function emptyafterlast is null, file __FILE__, line __LINE__",
			3055
		);  
		return;
	}


	fulllast->next = fullafterlast;
	fullafterlast->prev = fulllast;

	emptybeforefirst = empty->beforefirst;

	if(emptybeforefirst==NULL){
		list_[% Instancename %]_errorhandler(
			empty, 
			NULL, 
			"list_[% Instancename %]_split... function emptybeforefirst is null, file __FILE__, line __LINE__",
			3060
		);  
		return;
	}

	emptybeforefirst->next = emptyfirst;
	emptyfirst->prev = emptybeforefirst;

	emptyafterlast->prev = emptylast;
	emptylast->next = emptyafterlast;

	return;
}


// "sort" function
// takes a list  and sorts it
// "sort" function will be implemented using the merge-sort algorithm explained here:
// http://en.wikipedia.org/wiki/Merge_sort
// This function is *recursive*, it also creates a lot of temporary lists, which 
// means it uses a bunch of memory. If you want to sort the list without using 
// temporary memory, use a "bubble" sort. It'll be slower, but smaller footprint.
// Note the C++ version sorts the list in place, no return value, so we'll do that too.

void list_[% Instancename %]_sort (struct list_[% Instancename %]_list *list){
	if(list==NULL) {
		list_[% Instancename %]_errorhandler(
			NULL, 
			NULL, 
			"list_[% Instancename %]_merge function received null list, file __FILE__, line __LINE__",
			3100
		);  
		return;
	}
	int middle;
	struct list_[% Instancename %]_list *right;

	int listsize = list_[% Instancename %]_size(list);

	if(listsize<=1) {
		return;
	} 

	middle = (int)(listsize/2);

	// create an empty list so we can split original list in half
	right = list_[% Instancename %]_constructor();

	// "list" will be first half, "right" will be second half
	list_[% Instancename %]_split_list_down_the_middle(list, right, middle);

	// sort the two lists
	list_[% Instancename %]_sort(list);
	list_[% Instancename %]_sort(right);

	// now merge them
	list_[% Instancename %]_merge(list, right);

	// delete the "right" list, it was temporary.
	list_[% Instancename %]_destructor(right);	
}











