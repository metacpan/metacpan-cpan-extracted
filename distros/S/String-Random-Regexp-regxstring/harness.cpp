/* This code is provided by bliako and is heavily based on the
   original main.cpp supplied with the C++ library
*/

#include <iostream>
#include <fstream>
#include <string>
#include <cstdlib>
#include <cctype>

#include <string.h>

#include "harness.h"
#include "regxstring.h"

#define DEBUG 1

static std::string Trim(std::string str){
#if DEBUG==1
	std::cerr << "Trim: entering with '" << str << "'." << std::endl;
#endif
	size_t i = 0,e = str.length();
	for(;i < e && std::isspace(str[i]);++i);
	size_t j = e;
	for(;j > i && std::isspace(str[j - 1]);--j);
#if DEBUG==1
	std::string ret = i < j ? str.substr(i,j - i) : "";
	std::cerr << "Trim: leaving with '" << ret << "'." << std::endl;
	return ret;
#else
	return (i < j ? str.substr(i,j - i) : "");
#endif
}

static std::string pre_handle(
	const std::string & str
){
#if DEBUG==1
	std::cerr << "pre_handle: entering with '" << str << "'." << std::endl;
#endif
	std::string ret = Trim(str);
	if(!ret.empty()){
		if(ret[0] != '^')
			ret.insert(ret.begin(),'^');
		if(ret[ret.size() - 1] != '$')
			ret.push_back('$');
	}
#if DEBUG==1
	std::cerr << "pre_handle: leaving with '" << ret << "'." << std::endl;
#endif
	return ret;
}

/* Given the number of random strings to produce and a regex string
   it will return the array of random strings (as char**).
   Caller must free the returned array
*/
char ** regxstring_generate_random_strings_from_regex(
	const char *regx,/* the regex */
	int N,		 /* number of strings to produce */
	int debug	 /* set to 1 for debugging */
){
#if DEBUG==1
	std::cerr << "regxstring_generate_random_strings_from_regex: entering with '" << std::string(regx) << "'." << std::endl;
#endif
	CRegxString regxstr;
	regxstr.ParseRegx(pre_handle(std::string(regx)).c_str());

	if(debug>0) regxstr.Debug(std::cerr);

	char **ret, *astring;

	if( (ret=(char **)malloc(N*sizeof(char *))) == NULL ){ std::cerr << "regxstring_generate_random_strings_from_regex() : error, failed to allocate memory for " << N << " random strings (to return)."; return (char **)NULL; }

	for(int i = 0;i < N;++i){
		const char *rs = regxstr.RandString();
		if( rs != NULL ){
			ret[i] = strdup(rs);
		} else {
			ret[i] = (char *)malloc(sizeof(char));
			*(ret[i]) = 0;
		}
	}
#if DEBUG==1
	std::cerr << "regxstring_generate_random_strings_from_regex: leaving with 1st string as '" << std::string(ret[0]) << "'." << std::endl;
#endif
	return ret;
}
