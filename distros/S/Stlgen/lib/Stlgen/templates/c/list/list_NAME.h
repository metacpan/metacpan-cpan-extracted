#ifndef list_[% Instancename %]_HEADER_
#define list_[% Instancename %]_HEADER_

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


/////////////////////////////////////////////////////////////////////
// error handling
/////////////////////////////////////////////////////////////////////

// This is the default error handler, report and exit.
void list_[% Instancename %]_default_error_handler(
	struct list_[% Instancename %]_list *list,
	struct list_[% Instancename %]_elem *elem,
	char *errmsg, 
	int errnum
);

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
);

/////////////////////////////////////////////////////////////////////
// compare function for sorting
/////////////////////////////////////////////////////////////////////

// this is the default element compare function (used for sorting, etc)
// do a simple numeric compare of first record in element.
int list_[% Instancename %]_default_compare(struct list_[% Instancename %]_elem *element1, struct list_[% Instancename %]_elem *element2);

// all sorts use this pointer to a comparator function
// this allows the code to set it to a default
// and also allows the user to assign the pointer
// to point to their own comparator
// This allows user to change compare behaviour
// without changing any code in this file
int (*list_[% Instancename %]_compare_ptr)(struct list_[% Instancename %]_elem *, struct list_[% Instancename %]_elem *);

/////////////////////////////////////////////////////////////////////
// element destructor
/////////////////////////////////////////////////////////////////////

// by default, elements are destructed by setting prev/next pointers
// to null and then freeing the element.
// if the element contains a pointer to something that also needs to be freed,
// user can override the default behaviour with their own element destructor.

void list_[% Instancename %]_default_element_destructor(struct list_[% Instancename %]_elem *currelement);

void (*list_[% Instancename %]_element_destructor_ptr)(struct list_[% Instancename %]_elem *currelement);


/////////////////////////////////////////////////////////////////////
// element dumper
/////////////////////////////////////////////////////////////////////

// create default behvaivour for printing out the contents of an element.
// user can override based on whatever types they have in element.
// for default, just print address of current element, and prev/next addresses 
// user can copy paste this code and modify it and override the default behaviour.

void list_[% Instancename %]_default_element_dumper(struct list_[% Instancename %]_elem *currelement);

void (*list_[% Instancename %]_element_dumper_ptr)(struct list_[% Instancename %]_elem *currelement);

/////////////////////////////////////////////////////////////////////
// list dumper
/////////////////////////////////////////////////////////////////////

// create default behvaivour for printing out the contents of an list.
// user can override based on whatever types they have in list.
// user can copy paste this code and modify it and override the default behaviour.

void list_[% Instancename %]_default_list_dumper(struct list_[% Instancename %]_list *currlist);

void (*list_[% Instancename %]_list_dumper_ptr)(struct list_[% Instancename %]_list *currlist);

// create a normal function to dereference the pointer for the user and dump the list
void list_[% Instancename %]_list_dumper(struct list_[% Instancename %]_list *currlist);

// provide a function to dereference the error handler pointer.
// since speed isn't important here, shouldn't cause a problem.
void list_[% Instancename %]_errorhandler(
	struct list_[% Instancename %]_list *list,
	struct list_[% Instancename %]_elem *elem,
	char *errmsg, 
	int errnum
);

/////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////
// normal list functions.
/////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////

// constructor
struct	list_[% Instancename %]_list *list_[% Instancename %]_constructor (void);

// destructor function
void list_[% Instancename %]_destructor(struct list_[% Instancename %]_list *list) ;


// push_front function
void	       list_[% Instancename %]_push_front (
	struct list_[% Instancename %]_list *list,
	[% FOREACH section = payload %][% section.type %] [% section.name %]_in[% UNLESS loop.last %],[% END %]
	[% END %]
);

// push_back function
void	list_[% Instancename %]_push_back (
	struct list_[% Instancename %]_list *list,
	[% FOREACH section = payload %][% section.type %] [% section.name %]_in[% UNLESS loop.last %],[% END %]
	[% END %]
);

// pop_front
[% IF payloadsize == 1 %]// only one item in payload, return the value of the payload[% ELSE %]// more than one datum per element, return a pointer to the entire element[% END %]
[% IF payloadsize == 1 %][% FOREACH section = payload %][% section.type %][% END %][% ELSE %]struct list_[% Instancename %]_elem *[% END %]
	list_[% Instancename %]_pop_front (
	struct list_[% Instancename %]_list * list
);

// pop_back
// if only one item in payload, return the value of the payload
// if more than one item, return a pointer to the payload element
[% IF payloadsize == 1 %][% FOREACH section = payload %][% section.type %][% END %][% ELSE %]struct list_[% Instancename %]_elem * [% END %]
	list_[% Instancename %]_pop_back (
	struct list_[% Instancename %]_list * list
);


// increment to next element
struct list_[% Instancename %]_elem *list_[% Instancename %]_elem_plusplus(struct list_[% Instancename %]_list *list, struct list_[% Instancename %]_elem *elem) ;

// decrement to prev element
struct list_[% Instancename %]_elem *list_[% Instancename %]_elem_minusminus(struct list_[% Instancename %]_list *list, struct list_[% Instancename %]_elem *elem) ;

// increment by N elements
struct list_[% Instancename %]_elem *list_[% Instancename %]_elem_increment(struct list_[% Instancename %]_list *list, struct list_[% Instancename %]_elem *elem, unsigned int incval) ;

// decrement by N elements
struct list_[% Instancename %]_elem *list_[% Instancename %]_elem_decrement(struct list_[% Instancename %]_list *list, struct list_[% Instancename %]_elem *elem, unsigned int decval) ;

// advance by N elements, where N can be positive or negative
struct list_[% Instancename %]_elem *list_[% Instancename %]_elem_advance(struct list_[% Instancename %]_list *list, struct list_[% Instancename %]_elem *elem, unsigned int advanceval) ;

// function returns "begin" marker
struct list_[% Instancename %]_elem *list_[% Instancename %]_begin (struct list_[% Instancename %]_list *list) ;

// function returns "end" marker
struct list_[% Instancename %]_elem *list_[% Instancename %]_end (struct list_[% Instancename %]_list *list) ;

// function returns "rbegin" marker
struct list_[% Instancename %]_elem *list_[% Instancename %]_rbegin (struct list_[% Instancename %]_list *list) ;

// function returns "rend" marker
struct list_[% Instancename %]_elem *list_[% Instancename %]_rend (struct list_[% Instancename %]_list *list) ;

// not iterator markers, but general markers from C++ class

// function returns "front" marker (first user element)
struct list_[% Instancename %]_elem *list_[% Instancename %]_front (struct list_[% Instancename %]_list *list) ;

// function returns "back" marker (last user element)
struct list_[% Instancename %]_elem *list_[% Instancename %]_back (struct list_[% Instancename %]_list *list) ;



// forward iterator to run a callback on every user element in linked list.
void list_[% Instancename %]_iterator(struct list_[% Instancename %]_list *list, void (*callback)(struct list_[% Instancename %]_elem *)) ;

// reverse iterator to run a callback on every user element in linked list.
// it doesn't test for "NULL" because "NULL" could indicate a memory leak.
// instead, loop until we reach the rend element (before first), then stop.
void	       list_[% Instancename %]_reverse_iterator(
	struct list_[% Instancename %]_list *list,
	void (*callback)(struct list_[% Instancename %]_elem *)
);

// "empty" function
// return 1 if list is empty, else return 0
int list_[% Instancename %]_empty(struct list_[% Instancename %]_list *list) ;

// size function
// return size of list
int list_[% Instancename %]_size(struct list_[% Instancename %]_list *list) ;

// given a list, make a shallow copy of it.
// Note that if the list holds plain data, this will create a completely new unrelated list.
// If the list holds pointers, then those pointers will NOT get deep-copied.
// if you want a deep copy, roll your own.
struct list_[% Instancename %]_list *list_[% Instancename %]_shallow_copy(struct list_[% Instancename %]_list *existinglist);


// "insert" function
void	       list_[% Instancename %]_insert (
	struct list_[% Instancename %]_list *list,
	struct list_[% Instancename %]_elem *currentelement,
	[% FOREACH section = payload %][% section.type %] [% section.name %]_in[% UNLESS loop.last %],[% END %]
	[% END %]
);

// "insert n" function
// cant overload functions in C, have to use a different function name
void	       list_[% Instancename %]_insert_n (
	struct list_[% Instancename %]_list *list,
	unsigned int count,
	struct list_[% Instancename %]_elem *currentelement,
	[% FOREACH section = payload %][% section.type %] [% section.name %]_in[% UNLESS loop.last %],[% END %]
	[% END %]
);

// "erase" function
// delete one element being pointed to
struct list_[% Instancename %]_elem *
	       list_[% Instancename %]_erase (
	struct list_[% Instancename %]_list *list,
	struct list_[% Instancename %]_elem *currentelement
);

// "erase n" function
// cant overload functions in C, have to use a different function name
struct list_[% Instancename %]_elem *
	       list_[% Instancename %]_erase_n (
	struct list_[% Instancename %]_list *list,
	unsigned int count,
	struct list_[% Instancename %]_elem *currentelement
);


// "swap" function
// swap contents of two lists.
void	       list_[% Instancename %]_swap (
	struct list_[% Instancename %]_list *list1,
	struct list_[% Instancename %]_list *list2
);


// "clear" callback used by "clear" function
void callback_list_[% Instancename %]_clear(struct list_[% Instancename %]_elem *currelem);

// "clear" function
// empties the contents of a list, call destructors on all its elements
void	       list_[% Instancename %]_clear (
	struct list_[% Instancename %]_list *list
);


// "merge" function
// take two sorted lists (alpha and bravo) and merge all elements of bravo into 
// alpha so that alpha is still sorted. At the end, bravo list is empty.
void	       list_[% Instancename %]_merge (
	struct list_[% Instancename %]_list *alpha,
	struct list_[% Instancename %]_list *bravo,
	int (*comparecallback)(struct list_[% Instancename %]_elem *,struct list_[% Instancename %]_elem *)
);
 
// this is a function used specifically by the "merge_sort" algorithm.
// take one full list and one empty list and split full list in half
// putting second half into what was the empty list.
void	       list_[% Instancename %]_split_list_down_the_middle (
	struct list_[% Instancename %]_list *full,
	struct list_[% Instancename %]_list *empty,
	int middle
);


// "sort" function
// takes a list and sorts it
// "sort" function will be implemented using the merge-sort algorithm explained here:
// http://en.wikipedia.org/wiki/Merge_sort
// This function is *recursive*, it also creates a lot of temporary lists, which 
// means it uses a bunch of memory. If you want to sort the list without using 
// temporary memory, use a "bubble" sort. It'll be slower, but smaller footprint.
// Note the C++ version sorts the list in place, no return value, so we'll do that too.

void	       list_[% Instancename %]_sort (struct list_[% Instancename %]_list *list);


#endif

