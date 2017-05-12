/*-
 * Copyright (c) 2011 cPanel, Inc.
 * All rights reserved.
 *
 * This library is free software; you can redistribute it and/or modify
 * it under the same terms as Perl itself, either Perl version 5.10.1 or,
 * at your option, any later version of Perl 5 you may have available.
 */

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "sort.h"
#include <string.h>

typedef void (*sort_function_t)(ElementType A[ ], int N, CmpFunction *cmp);

/* The enum and map are in the same order for easy lookup */
typedef enum { VOID, INSERTION, SHELL, HEAP, MERGE, QUICK } SortAlgo;
typedef enum { INT, STR } SortType;

sort_function_t sort_function_map[] = {
		VoidSort
		,InsertionSort	
		,ShellSort
		,HeapSort
		,MergeSort
		,QuickSort
};
/* typedef int (CmpFunction)(const ElementType *a, const ElementType *b); */

CmpFunction *cmp_functionmap[] = {
		compare_int,
		compare_str
};


SV* _jump_to_sort(const SortAlgo method, const SortType type, SV* array) {
	AV* av;
	AV* input;
	SV* reply;
	SV* elt;
		
	av = newAV();
	reply = newRV_noinc((SV *) av);
		
	/* not defined or not a reference */
	if (!array || !SvOK(array) || !SvROK(array) )
		return reply;
	
	input = (AV*) SvRV(array);
	/* should reference a hash */
	if (SvTYPE (input) != SVt_PVAV)
		croak ("expecting a reference to an array");	
		
	int size = av_len(input);
	ElementType elements[size+1];
	int i;
	for ( i = 0; i <= size; ++i) {
		if ( type == INT ) {
			elements[i].i = SvIV(*av_fetch(input, i, 0));
		} else {
			elements[i].s = SvPV_nolen(*av_fetch(input, i, 0));
		}
		/* fprintf(stderr, "number %02d is %d\n", i, elements[i]); */	
	}
	
	/* map to the c method */
	sort_function_map[method]( elements, size + 1, cmp_functionmap[type]);
	
	/* convert into perl types */
	for ( i = 0; i <= size; ++i) {
		if ( type == INT ) {
			av_push(av, newSViv(elements[i].i));
		} else {
			av_push(av, newSVpv(elements[i].s, 0));
		}
	}	
	
	return reply;
}

/* 
 * read perlguts : http://search.cpan.org/~flora/perl-5.14.2/pod/perlguts.pod 
 * 
 * */


MODULE = Sort::XS PACKAGE = Sort::XS

PROTOTYPES: ENABLE

SV* insertion_sort(array)
		SV* array
		CODE:
			RETVAL = _jump_to_sort(INSERTION, INT, array);
		OUTPUT:
			RETVAL

SV* insertion_sort_str(array)
		SV* array
		CODE:
			RETVAL = _jump_to_sort(INSERTION, STR, array);
		OUTPUT:
			RETVAL
			
SV* shell_sort(array)
	SV* array
	CODE:
		RETVAL = _jump_to_sort(SHELL, INT, array);
	OUTPUT:
		RETVAL

SV* shell_sort_str(array)
	SV* array
	CODE:
		RETVAL = _jump_to_sort(SHELL, STR, array);
	OUTPUT:
		RETVAL

SV* heap_sort(array)
	SV* array
	CODE:
		RETVAL = _jump_to_sort(HEAP, INT, array);
	OUTPUT:
		RETVAL

SV* heap_sort_str(array)
	SV* array
	CODE:
		RETVAL = _jump_to_sort(HEAP, STR, array);
	OUTPUT:
		RETVAL

SV* merge_sort(array)
	SV* array
	CODE:
		RETVAL = _jump_to_sort(MERGE, INT, array);
	OUTPUT:
		RETVAL

SV* merge_sort_str(array)
	SV* array
	CODE:
		RETVAL = _jump_to_sort(MERGE, STR, array);
	OUTPUT:
		RETVAL

SV* quick_sort(array)
	SV* array
	CODE:
		RETVAL = _jump_to_sort(QUICK, INT, array);
	OUTPUT:
		RETVAL

SV* quick_sort_str(array)
	SV* array
	CODE:
		RETVAL = _jump_to_sort(QUICK, STR, array);
	OUTPUT:
		RETVAL

SV* void_sort(array)
	SV* array
	CODE:
		RETVAL = _jump_to_sort(VOID, INT, array);
	OUTPUT:
		RETVAL
