#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"
#include <wordcut/wcwordcut.h>
#include <string.h>

typedef WcWordcut* String__Thai__Segmentation__wc;
typedef WcWordVector* String__Thai__Segmentation__vector;

MODULE = String::Thai::Segmentation		PACKAGE = String::Thai::Segmentation
PROTOTYPES: ENABLE

String::Thai::Segmentation::wc get_wc(package)
	char *package;
	CODE:
		RETVAL = wc_wordcut_new();
	OUTPUT:
		RETVAL

String::Thai::Segmentation::wc get_custom_wc(package,dictionary_file,wordunit_file);
	char *package;
	guchar* dictionary_file;
	guchar* wordunit_file;
	CODE:
		RETVAL = wc_wordcut_new_custom(dictionary_file,wordunit_file);
	OUTPUT:
		RETVAL

void destroy_wc(package,wc)
	char *package;
	String::Thai::Segmentation::wc wc;	
	CODE:
		wc_wordcut_delete(wc);

gchar* wordcut(package,wc,str);
	char* package;
	String::Thai::Segmentation::wc wc;
	gchar* str;
	CODE:
		char* delimiter;
		gchar* xyz;
		delimiter = "#K_=";
		strcpy(wc->print.delimiter,delimiter);
		xyz =(gchar*) wc_wordcut_cutline(wc,str,strlen(str));
		RETVAL = xyz;
	OUTPUT:
		RETVAL

gchar* string_separate(package,wc,str,separator);
	char* package;
	String::Thai::Segmentation::wc wc;
	gchar* str;
	char* separator
	CODE:
		gchar* xyz;
		strcpy(wc->print.delimiter,separator);
		xyz =(gchar*) wc_wordcut_cutline(wc,str,strlen(str));
		RETVAL = xyz;
	OUTPUT:
		RETVAL