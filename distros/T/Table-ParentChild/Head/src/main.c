#include "../Head/src/head.h"
#include "element.h"
#include <stdio.h>
#include <stdlib.h>

int main( void ) {
	head	*head_row;
	element	*this_element;
	element	*next_element;
	int i;

	head_row = (head *) malloc( sizeof( head ));

	for( i = 0; i < 100; i++ ) {
		next_element = (element *) malloc( sizeof( element ));
		next_element->value = (float) i;
		next_element->head_row = head_row;
		next_element->next_row = NULL;
		if( i == 0 ) {
			head_row->first = next_element;

		} else {
			this_element->next_row = next_element;
		}
		this_element = next_element;
	}

	this_element = head_row->first;
	while( this_element ) {
		next_element = this_element->next_row;
		printf( "This element is %f\n", this_element->value );
		this_element = next_element;
	}

	exit( 0 );
}
