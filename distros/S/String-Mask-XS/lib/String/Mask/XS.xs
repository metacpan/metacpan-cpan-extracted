#define PERL_NO_GET_CONTEXT // we'll define thread context if necessary (faster)
#include "EXTERN.h"         // globals/constant import locations
#include "perl.h"           // Perl symbols, structures and constants definition
#include "XSUB.h"           // xsubpp functions and macros
#include <stdlib.h>         // rand()
#include <string.h>

static char* replace_char_start (char* str, char * mask_char, size_t length) {
	if (length == 0) return str;
	int i = 0; 
	while(i < length) {
		int pos = (strlen(str) - 1) - i;
		if (str[pos] != '.' && str[pos] != '@') {
			str[pos] = *mask_char;
		}
		i++;
	}
   	return str;
}

static char* replace_char_end (char* str, char * mask_char, size_t length) {
	if (length == 0) return str;
	int i = 0; 
	while(i < length) {
		if (str[i] != '.' && str[i] != '@') {
			str[i] = *mask_char;
		}
		i++;
	}
   	return str;
}

static char* replace_char_middle (char* str, char * mask_char, size_t length) {
	if (length == 0) return str;
	int half = floor(length / 2);
   	str = replace_char_start(str, mask_char, length - half);
	str = replace_char_end(str, mask_char, half);
	return str;
}

static char* replace_char_email (char* str, char * mask_char, size_t length) {
	if (length == 0) return str;
	int pos = (strlen(str) - 1);
	while ( str[pos] != '@' ) {
		if (str[pos] != '.') {
			str[pos] = *mask_char;
		}
		pos--;
	}
	pos--;
	while(length > 0) {
		if (str[pos] != '.' && str[pos] != '@') {
			str[pos] = *mask_char;
		}
		pos--;
		length--;
	}
   	return str;
}

static char * mask_string (char * str, char * pos, double len, char * mask_char) {
	if (strcmp(pos, "end") == 0) {
		return replace_char_end(str, mask_char, strlen(str) - len);
	} else if (strcmp(pos, "middle") == 0) {
		return replace_char_middle(str, mask_char, strlen(str) - len);
	} else if (strcmp(pos, "email") == 0) {
		return replace_char_email(str, mask_char, len);
	}
	return replace_char_start(str, mask_char, strlen(str) - len);;
}
 
MODULE = String::Mask::XS  PACKAGE = String::Mask::XS
PROTOTYPES: ENABLE

char *
mask(...)
	CODE:
		char * str = SvPV_nolen(ST(0));
  		char * pos = items > 1 ? SvPV_nolen(ST(1)) : "start";
  		double len = items > 2 ? SvIV(ST(2)) : floor(strlen(str) / 2);
  		char * mask_char = items > 3 ? SvPV_nolen(ST(3)) : "*";
		RETVAL = mask_string(str, pos, len, mask_char);
	OUTPUT:
		RETVAL
