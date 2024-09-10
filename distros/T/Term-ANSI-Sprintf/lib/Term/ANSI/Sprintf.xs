#define PERL_NO_GET_CONTEXT // we'll define thread context if necessary (faster)
#include "EXTERN.h"         // globals/constant import locations
#include "perl.h"           // Perl symbols, structures and constants definition
#include "XSUB.h"           // xsubpp functions and macros
#include <stdlib.h>         // rand()
#include <string.h>

char * basic_format_map[][2] = {
	{"%bold", "1"},
	{"%italic", "3"},
	{"%underline", "4"},
};

char * basic_color_map[][3] = {
	{"%black_on_red", "30", "41"},
	{"%black_on_green", "30", "42"},
	{"%black_on_yellow", "30", "43"},
	{"%black_on_blue", "30", "44"},
	{"%black_on_magenta", "30", "45"},
	{"%black_on_cyan", "30", "46"},
	{"%black_on_white", "30", "47"},
	{"%black_on_bright_red", "30", "101"},
	{"%black_on_bright_green", "30", "102"},
	{"%black_on_bright_yellow", "30", "103"},
	{"%black_on_bright_blue", "30", "104"},
	{"%black_on_bright_magenta", "30", "105"},
	{"%black_on_bright_cyan", "30", "106"},
	{"%black_on_bright_white", "30", "107"},
	{"%bright_black_on_red", "90", "41"},
	{"%bright_black_on_green", "90", "42"},
	{"%bright_black_on_yellow", "90", "43"},
	{"%bright_black_on_blue", "90", "44"},
	{"%bright_black_on_magenta", "90", "45"},
	{"%bright_black_on_cyan", "90", "46"},
	{"%bright_black_on_white", "90", "47"},
	{"%bright_black_on_bright_red", "90", "101"},
	{"%bright_black_on_bright_green", "90", "102"},
	{"%bright_black_on_bright_yellow", "90", "103"},
	{"%bright_black_on_bright_blue", "90", "104"},
	{"%bright_black_on_bright_magenta", "90", "105"},
	{"%bright_black_on_bright_cyan", "90", "106"},
	{"%bright_black_on_bright_white", "90", "107"},
	{"%red_on_black", "31", "40"},
	{"%red_on_green", "31", "42"},
	{"%red_on_yellow", "31", "43"},
	{"%red_on_blue", "31", "44"},
	{"%red_on_magenta", "31", "45"},
	{"%red_on_cyan", "31", "46"},
	{"%red_on_white", "31", "47"},
	{"%red_on_bright_black", "31", "100"},
	{"%red_on_bright_green", "31", "102"},
	{"%red_on_bright_yellow", "31", "103"},
	{"%red_on_bright_blue", "31", "104"},
	{"%red_on_bright_magenta", "31", "105"},
	{"%red_on_bright_cyan", "31", "106"},
	{"%red_on_bright_white", "31", "107"},
	{"%bright_red_on_black", "91", "40"},
	{"%bright_red_on_green", "91", "42"},
	{"%bright_red_on_yellow", "91", "43"},
	{"%bright_red_on_blue", "91", "44"},
	{"%bright_red_on_magenta", "91", "45"},
	{"%bright_red_on_cyan", "91", "46"},
	{"%bright_red_on_white", "91", "47"},
	{"%bright_red_on_bright_black", "91", "100"},
	{"%bright_red_on_bright_green", "91", "102"},
	{"%bright_red_on_bright_yellow", "91", "103"},
	{"%bright_red_on_bright_blue", "91", "104"},
	{"%bright_red_on_bright_magenta", "91", "105"},
	{"%bright_red_on_bright_cyan", "91", "106"},
	{"%bright_red_on_bright_white", "91", "107"},
	{"%green_on_black", "32", "40"},
	{"%green_on_red", "32", "41"},
	{"%green_on_yellow", "32", "43"},
	{"%green_on_blue", "32", "44"},
	{"%green_on_magenta", "32", "45"},
	{"%green_on_cyan", "32", "46"},
	{"%green_on_white", "32", "47"},
	{"%green_on_bright_black", "32", "100"},
	{"%green_on_bright_red", "32", "101"},
	{"%green_on_bright_yellow", "32", "103"},
	{"%green_on_bright_blue", "32", "104"},
	{"%green_on_bright_magenta", "32", "105"},
	{"%green_on_bright_cyan", "32", "106"},
	{"%green_on_bright_white", "32", "107"},
	{"%bright_green_on_black", "92", "40"},
	{"%bright_green_on_red", "92", "41"},
	{"%bright_green_on_yellow", "92", "43"},
	{"%bright_green_on_blue", "92", "44"},
	{"%bright_green_on_magenta", "92", "45"},
	{"%bright_green_on_cyan", "92", "46"},
	{"%bright_green_on_white", "92", "47"},
	{"%bright_green_on_bright_black", "92", "100"},
	{"%bright_green_on_bright_red", "92", "101"},
	{"%bright_green_on_bright_yellow", "92", "103"},
	{"%bright_green_on_bright_blue", "92", "104"},
	{"%bright_green_on_bright_magenta", "92", "105"},
	{"%bright_green_on_bright_cyan", "92", "106"},
	{"%bright_green_on_bright_white", "92", "107"},
	{"%yellow_on_black", "33", "40"},
	{"%yellow_on_red", "33", "41"},
	{"%yellow_on_green", "33", "42"},
	{"%yellow_on_blue", "33", "44"},
	{"%yellow_on_magenta", "33", "45"},
	{"%yellow_on_cyan", "33", "46"},
	{"%yellow_on_white", "33", "47"},
	{"%yellow_on_bright_black", "33", "100"},
	{"%yellow_on_bright_red", "33", "101"},
	{"%yellow_on_bright_green", "33", "102"},
	{"%yellow_on_bright_blue", "33", "104"},
	{"%yellow_on_bright_magenta", "33", "105"},
	{"%yellow_on_bright_cyan", "33", "106"},
	{"%yellow_on_bright_white", "33", "107"},
	{"%bright_yellow_on_black", "93", "40"},
	{"%bright_yellow_on_red", "93", "41"},
	{"%bright_yellow_on_green", "93", "42"},
	{"%bright_yellow_on_blue", "93", "44"},
	{"%bright_yellow_on_magenta", "93", "45"},
	{"%bright_yellow_on_cyan", "93", "46"},
	{"%bright_yellow_on_white", "93", "47"},
	{"%bright_yellow_on_bright_black", "93", "100"},
	{"%bright_yellow_on_bright_red", "93", "101"},
	{"%bright_yellow_on_bright_green", "93", "102"},
	{"%bright_yellow_on_bright_blue", "93", "104"},
	{"%bright_yellow_on_bright_magenta", "93", "105"},
	{"%bright_yellow_on_bright_cyan", "93", "106"},
	{"%bright_yellow_on_bright_white", "93", "107"},
	{"%blue_on_black", "34", "40"},
	{"%blue_on_red", "34", "41"},
	{"%blue_on_green", "34", "42"},
	{"%blue_on_yellow", "34", "43"},
	{"%blue_on_magenta", "34", "45"},
	{"%blue_on_cyan", "34", "46"},
	{"%blue_on_white", "34", "47"},
	{"%blue_on_bright_black", "34", "100"},
	{"%blue_on_bright_red", "34", "101"},
	{"%blue_on_bright_green", "34", "102"},
	{"%blue_on_bright_yellow", "34", "103"},
	{"%blue_on_bright_magenta", "34", "105"},
	{"%blue_on_bright_cyan", "34", "106"},
	{"%blue_on_bright_white", "34", "107"},
	{"%bright_blue_on_black", "94", "40"},
	{"%bright_blue_on_red", "94", "41"},
	{"%bright_blue_on_green", "94", "42"},
	{"%bright_blue_on_yellow", "94", "43"},
	{"%bright_blue_on_magenta", "94", "45"},
	{"%bright_blue_on_cyan", "94", "46"},
	{"%bright_blue_on_white", "94", "47"},
	{"%bright_blue_on_bright_black", "94", "100"},
	{"%bright_blue_on_bright_red", "94", "101"},
	{"%bright_blue_on_bright_green", "94", "102"},
	{"%bright_blue_on_bright_yellow", "94", "103"},
	{"%bright_blue_on_bright_magenta", "94", "105"},
	{"%bright_blue_on_bright_cyan", "94", "106"},
	{"%bright_blue_on_bright_white", "94", "107"},
	{"%magenta_on_black", "35", "40"},
	{"%magenta_on_red", "35", "41"},
	{"%magenta_on_green", "35", "42"},
	{"%magenta_on_yellow", "35", "43"},
	{"%magenta_on_blue", "35", "44"},
	{"%magenta_on_cyan", "35", "46"},
	{"%magenta_on_white", "35", "47"},
	{"%magenta_on_bright_black", "35", "100"},
	{"%magenta_on_bright_red", "35", "101"},
	{"%magenta_on_bright_green", "35", "102"},
	{"%magenta_on_bright_yellow", "35", "103"},
	{"%magenta_on_bright_blue", "35", "104"},
	{"%magenta_on_bright_cyan", "35", "106"},
	{"%magenta_on_bright_white", "35", "107"},
	{"%bright_magenta_on_black", "95", "40"},
	{"%bright_magenta_on_red", "95", "41"},
	{"%bright_magenta_on_green", "95", "42"},
	{"%bright_magenta_on_yellow", "95", "43"},
	{"%bright_magenta_on_blue", "95", "44"},
	{"%bright_magenta_on_cyan", "95", "46"},
	{"%bright_magenta_on_white", "95", "47"},
	{"%bright_magenta_on_bright_black", "95", "100"},
	{"%bright_magenta_on_bright_red", "95", "101"},
	{"%bright_magenta_on_bright_green", "95", "102"},
	{"%bright_magenta_on_bright_yellow", "95", "103"},
	{"%bright_magenta_on_bright_blue", "95", "104"},
	{"%bright_magenta_on_bright_cyan", "95", "106"},
	{"%bright_magenta_on_bright_white", "95", "107"},
	{"%cyan_on_black", "36", "40"},
	{"%cyan_on_red", "36", "41"},
	{"%cyan_on_green", "36", "42"},
	{"%cyan_on_yellow", "36", "43"},
	{"%cyan_on_blue", "36", "44"},
	{"%cyan_on_magenta", "36", "45"},
	{"%cyan_on_white", "36", "47"},
	{"%cyan_on_bright_black", "36", "100"},
	{"%cyan_on_bright_red", "36", "101"},
	{"%cyan_on_bright_green", "36", "102"},
	{"%cyan_on_bright_yellow", "36", "103"},
	{"%cyan_on_bright_blue", "36", "104"},
	{"%cyan_on_bright_magenta", "36", "105"},
	{"%cyan_on_bright_white", "36", "107"},
	{"%bright_cyan_on_black", "96", "40"},
	{"%bright_cyan_on_red", "96", "41"},
	{"%bright_cyan_on_green", "96", "42"},
	{"%bright_cyan_on_yellow", "96", "43"},
	{"%bright_cyan_on_blue", "96", "44"},
	{"%bright_cyan_on_magenta", "96", "45"},
	{"%bright_cyan_on_white", "96", "47"},
	{"%bright_cyan_on_bright_black", "96", "100"},
	{"%bright_cyan_on_bright_red", "96", "101"},
	{"%bright_cyan_on_bright_green", "96", "102"},
	{"%bright_cyan_on_bright_yellow", "96", "103"},
	{"%bright_cyan_on_bright_blue", "96", "104"},
	{"%bright_cyan_on_bright_magenta", "96", "105"},
	{"%bright_cyan_on_bright_white", "96", "107"},
	{"%white_on_black", "37", "40"},
	{"%white_on_red", "37", "41"},
	{"%white_on_green", "37", "42"},
	{"%white_on_yellow", "37", "43"},
	{"%white_on_blue", "37", "44"},
	{"%white_on_magenta", "37", "45"},
	{"%white_on_cyan", "37", "46"},
	{"%white_on_bright_black", "37", "100"},
	{"%white_on_bright_red", "37", "101"},
	{"%white_on_bright_green", "37", "102"},
	{"%white_on_bright_yellow", "37", "103"},
	{"%white_on_bright_blue", "37", "104"},
	{"%white_on_bright_magenta", "37", "105"},
	{"%white_on_bright_cyan", "37", "106"},
	{"%bright_white_on_black", "97", "40"},
	{"%bright_white_on_red", "97", "41"},
	{"%bright_white_on_green", "97", "42"},
	{"%bright_white_on_yellow", "97", "43"},
	{"%bright_white_on_blue", "97", "44"},
	{"%bright_white_on_magenta", "97", "45"},
	{"%bright_white_on_cyan", "97", "46"},
	{"%bright_white_on_bright_black", "97", "100"},
	{"%bright_white_on_bright_red", "97", "101"},
	{"%bright_white_on_bright_green", "97", "102"},
	{"%bright_white_on_bright_yellow", "97", "103"},
	{"%bright_white_on_bright_blue", "97", "104"},
	{"%bright_white_on_bright_magenta", "97", "105"},
	{"%bright_white_on_bright_cyan", "97", "106"},
	{"%black", "30"},
	{"%red", "31"},
	{"%green", "32"},
	{"%yellow", "33"},
	{"%blue", "34"},
	{"%magenta", "35"},
	{"%cyan", "36"},
	{"%white", "37"},
	{"%bright_black", "90"},
	{"%bright_red", "91"},
	{"%bright_green", "92"},
	{"%bright_yellow", "93"},
	{"%bright_blue", "94"},
	{"%bright_magenta", "95"},
	{"%bright_cyan", "96"},
	{"%bright_white", "97"},
};

char * concat(const char* str1, const char* str2) {
	char* result;
	asprintf(&result, "%s%s", str1, str2);
	return result;
}

char *str_replace(char *orig, char *rep, char * map[3], int colour) {
	char * result, * ins, * tmp, * with; 
	int len_rep, len_with, len_front, count;    
    	len_rep = strlen(rep);
    	if (len_rep == 0) return orig; 
	ins = orig;
	for (count = 0; (tmp = strstr(ins, rep)); ++count) {
		ins = tmp + len_rep;
	}
	if (count == 0) return orig;
	if (colour) {
		with = concat("\e[", map[1]);
		if (map[2]) {
			with = concat(with, ";");
			with = concat(with, map[2]);
		}
		with = concat(with, "m%s\e[0m");
	} else {
		with = concat(concat("\e[", map[1]), "m");
	}
    	len_with = strlen(with);
	tmp = result = malloc(strlen(orig) + (len_with - len_rep) * count + 1);
    	if (!result) return orig;
	while (count--) {
		ins = strstr(orig, rep);
		len_front = ins - orig;
		tmp = strncpy(tmp, orig, len_front) + len_front;
		tmp = strcpy(tmp, with) + len_with;
		orig += len_front + len_rep; // move to next "end of rep"
	}
	strcpy(tmp, orig);
	return result;
}

char * preprocess (char * sprint) {
	int size = sizeof(basic_format_map)/sizeof(basic_format_map[0]);
	for (int i = 0; i < size; i++) {
		sprint = str_replace(sprint, basic_format_map[i][0], basic_format_map[i], 0);
	}
	size = sizeof(basic_color_map)/sizeof(basic_color_map[0]);
	for (int i = 0; i < size; i++) {
		sprint = str_replace(sprint, basic_color_map[i][0], basic_color_map[i], 1);
	}
	return sprint;
}
 
MODULE = Term::ANSI::Sprintf  PACKAGE = Term::ANSI::Sprintf
PROTOTYPES: ENABLE

SV *
sprintf(...)
	CODE:
		dSP;
		ENTER;
		SAVETMPS;
		char * sprint = preprocess(SvPV_nolen(ST(0)));
		ST(0) = newSVpv(sprint, strlen(sprint));
		perl_call_method("Term::ANSI::Sprintf::_sprintf", 3);
		SPAGAIN;
		RETVAL = newSVsv(POPs);
		PUTBACK;
		FREETMPS;
		LEAVE;
	OUTPUT:
		RETVAL

