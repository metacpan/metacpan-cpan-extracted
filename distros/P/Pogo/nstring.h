// nstring.h
// 1999 Sey
#ifndef _NSTRING_H_
#define _NSTRING_H_
// working class for a string which can includes '\0'
class nstring {
public:
	char*    str;
	unsigned len;
	nstring();
	nstring(char* str, unsigned len);
	nstring(char* str);
	nstring(const char* str, unsigned len);
	nstring(const char* str);
};

#endif
