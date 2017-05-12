#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"


MODULE = String::MMM		PACKAGE = String::MMM		

void
match_strings(hidden,target,colors)
	char *hidden;
        char *target;
        int colors;
    INIT:
	 int i;
  	 int blacks = 0;
  	 int whites = 0;
  	 int colors_in_string_h[colors], colors_in_string_t[colors];
    PPCODE:
    for ( i = 0; i < colors; i++ ) {
    	colors_in_string_h[i] =  colors_in_string_t[i] = 0;
    }
    for ( i = 0; i < strlen( hidden ); i++ ) {
    	if ( hidden[i] == target[i] ) {
      	   blacks++;
    	} else {
      	  colors_in_string_h[hidden[i] - 'A']++;
      	  colors_in_string_t[target[i] - 'A']++;
    	}
    }
    for ( i = 0; i < colors; i ++ ) {
      if ( colors_in_string_h[i] && colors_in_string_t[i] ) {
        whites += ( colors_in_string_h[i] <  colors_in_string_t[i])?
	  colors_in_string_h[i]: colors_in_string_t[i];
       }
    }
    XPUSHs(sv_2mortal(newSViv(blacks)));
    XPUSHs(sv_2mortal(newSViv(whites)));

void
s_match_strings(hidden,target,colors)
	char *hidden;
        char *target;
        int colors;
    INIT:
	 int i;
  	 int blacks = 0;
  	 int whites = 0;
  	 int colors_in_string_h[colors], colors_in_string_t[colors];
    PPCODE:
    for ( i = 0; i < colors; i++ ) {
    	colors_in_string_h[i] =  colors_in_string_t[i] = 0;
    }
    for ( i = 0; i < strlen( hidden ); i++ ) {
    	if ( hidden[i] == target[i] ) {
      	   blacks++;
    	} else {
      	  colors_in_string_h[hidden[i] - 'A']++;
      	  colors_in_string_t[target[i] - 'A']++;
    	}
    }
    for ( i = 0; i < colors; i ++ ) {
      if ( colors_in_string_h[i] && colors_in_string_t[i] ) {
        whites += ( colors_in_string_h[i] <  colors_in_string_t[i])?
	  colors_in_string_h[i]: colors_in_string_t[i];
       }
    }
    char str[7];
    sprintf(str, "%db%dw", blacks, whites );
    XPUSHs(sv_2mortal(newSVpv(str,0)));

void
match_strings_a(hidden,target)
	char *hidden;
        char *target;
    INIT:
	 int i;
  	 int blacks = 0;
  	 int whites = 0;
	 int colors = 26;
  	 int colors_in_string_h[colors], colors_in_string_t[colors];
    PPCODE:
    for ( i = 0; i < colors; i++ ) {
    	colors_in_string_h[i] =  colors_in_string_t[i] = 0;
    }
    for ( i = 0; i < strlen( hidden ); i++ ) {
    	if ( hidden[i] == target[i] ) {
      	   blacks++;
    	} else {
      	  colors_in_string_h[hidden[i] - 'a']++;
      	  colors_in_string_t[target[i] - 'a']++;
    	}
    }
    for ( i = 0; i < colors; i ++ ) {
      if ( colors_in_string_h[i] && colors_in_string_t[i] ) {
        whites += ( colors_in_string_h[i] <  colors_in_string_t[i])?
	  colors_in_string_h[i]: colors_in_string_t[i];
       }
    }
    XPUSHs(sv_2mortal(newSViv(blacks)));
    XPUSHs(sv_2mortal(newSViv(whites)));

void
match_arrays(hidden_ref,target_ref, colors)
	SV* hidden_ref;
        SV* target_ref;
	unsigned int colors;
    INIT:
	 int i;
  	 int blacks = 0;
  	 int whites = 0;
  	 int colors_in_string_h[colors], colors_in_string_t[colors];
    PPCODE:
    AV* hidden;
    AV* target;
    hidden = (AV*) SvRV(hidden_ref);
    target = (AV*) SvRV(target_ref);	
    for ( i = 0; i < colors; i++ ) {
    	colors_in_string_h[i] =  colors_in_string_t[i] = 0;
    }
    for ( i = 0; i <= av_len( hidden ); i++ ) {
    	int hidden_val = SvIV(*av_fetch(hidden,i,0));
	int target_val = SvIV(*av_fetch(target,i,0));
	printf( "%d  h %d t %d\n", i, hidden_val, target_val );
    	if ( hidden_val == target_val ) {
      	   blacks++;
    	} else {
      	  colors_in_string_h[ hidden_val ]++;
      	  colors_in_string_t[ target_val ]++;
    	}
    }
    printf("\n");
    for ( i = 0; i < colors; i ++ ) {
      if ( colors_in_string_h[i] && colors_in_string_t[i] ) {
        whites += ( colors_in_string_h[i] <  colors_in_string_t[i])?
	  colors_in_string_h[i]: colors_in_string_t[i];
       }
    }
    XPUSHs(sv_2mortal(newSViv(blacks)));
    XPUSHs(sv_2mortal(newSViv(whites)));