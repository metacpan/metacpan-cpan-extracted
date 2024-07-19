#define PERL_NO_GET_CONTEXT // we'll define thread context if necessary (faster)
#include "EXTERN.h"         // globals/constant import locations
#include "perl.h"           // Perl symbols, structures and constants definition
#include "XSUB.h"           // xsubpp functions and macros

int makehist (unsigned char * str, int * hist, int len) {
	int chars[256];
	int histlen = 0;
	for (int i = 0; i < 256; i++) chars[i]=-1;
	for (int i = 0; i < len; i++) {
		if(chars[(int)str[i]] == -1){
			chars[(int)str[i]] = histlen;
			histlen++;
		}
		hist[chars[(int)str[i]]]++;
	}
	return histlen;
}

double entropy (char * str) {
	int len = strlen(str);
	int * hist = (int*)calloc(len,sizeof(int));
	int histlen = makehist(str, hist, len);
	double out = 0;
	for (int i = 0; i < histlen; i++) {
		out -= (double)hist[i] / len * log2((double)hist[i] / len);
	}
	return out;
}

MODULE = Shannon::Entropy::XS  PACKAGE = Shannon::Entropy::XS
PROTOTYPES: ENABLE

SV *
entropy(string)
	SV * string;
	CODE:
		RETVAL = newSVnv(entropy(SvPV_nolen(string)));
	OUTPUT:
		RETVAL

