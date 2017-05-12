#define DEF_CHARACTER(tag,str,token,type) <!ELEMENT tag EMPTY><!-- str -->
#define DEF_KEYWORD(tag,token) <!ELEMENT tag EMPTY>
#define DEF_PP_DIRECTIVE(tag,str,token) <!ELEMENT tag ()><!-- str -->
#define DEF_OPERATOR(tag,str,token) <!ELEMENT tag EMPTY><!-- str -->
#define DEF_DECLARATOR(tag,str,token) <!ELEMENT tag EMPTY><!-- str -->
#define DEF_RULE(tag,token) <!ELEMENT tag ()>
#define DEF_MISC(tag,token) <!ELEMENT tag ()>

#include "token.def"

#undef DEF_CHARACTER
#undef DEF_KEYWORD
#undef DEF_PP_DIRECTIVE
#undef DEF_OPERATOR
#undef DEF_DECLARATOR
#undef DEF_RULE
#undef DEF_MISC

