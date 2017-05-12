// nstring.cxx
// 1999 Sey
#include <stdio.h>
#include "nstring.h"

nstring::nstring() { str = NULL; len = 0; }
nstring::nstring(char* str, unsigned len) { this->str = str; this->len = len; }
nstring::nstring(char* str) { this->str = str; len = strlen(str) + 1; }
nstring::nstring(const char* str, unsigned len) { 
	this->str = (char*)str; this->len = len; 
}
nstring::nstring(const char* str) { 
	this->str = (char*)str; len = strlen(str) + 1; 
}

