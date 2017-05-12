/*
 * UUID: bb188d3a-e320-11dc-8b9d-00502c05c241
 * Author: Brian M. Ames, bames@apk.net
 * Copyright: Copyright (C) 2008 by Brian M. Ames
 */

#ifndef _bb188d3a_e320_11dc_8b9d_00502c05c241_
#define _bb188d3a_e320_11dc_8b9d_00502c05c241_

#include <time.h>
#include <utime.h>

#define TREE_STACK_SIZE 256

extern char *nodeString[];
extern char *tokenString[];

#undef DEF_NODE_TYPE
#define DEF_NODE_TYPE(ENUM, NAME) ENUM,
enum node_type_enum {
#include "node.def"
  NODE_TYPE_LAST
};
#undef DEF_NODE_TYPE

//enum tokenIndex;
#define DEF_CHARACTER(tag,str,token,type) token##_INDEX ,
#define DEF_KEYWORD(str,token) token##_INDEX ,
#define DEF_PP_DIRECTIVE(tag,str,token) token##_INDEX ,
#define DEF_OPERATOR(tag,str,token) token##_INDEX ,
#define DEF_DECLARATOR(tag,str,token) token##_INDEX ,
#define DEF_RULE(tag,token) token##_index ,
#define DEF_MISC(str,token) token##_INDEX ,

enum tokenIndex {
#include "token.def"
};

#undef DEF_CHARACTER
#undef DEF_KEYWORD
#undef DEF_PP_DIRECTIVE
#undef DEF_OPERATOR
#undef DEF_DECLARATOR
#undef DEF_RULE
#undef DEF_MISC

struct nodeCommon {
  enum node_type_enum nodeType;
  struct nodeCommon *nextSibling;
  struct nodeCommon *firstChild;   // todo: move later
  enum tokenIndex tokenIndex;

  unsigned int used_flag        : 1;
  unsigned int replaceable_flag : 1;
  unsigned int public_flag      : 1;
  unsigned int private_flag     : 1;
  unsigned int protected_flag   : 1;
  unsigned int static_flag      : 1;
  unsigned int constant_flag    : 1;
  unsigned int volatile_flag    : 1;

  unsigned int lang_flag_23     : 1;
  unsigned int lang_flag_22     : 1;
  unsigned int lang_flag_21     : 1;
  unsigned int lang_flag_20     : 1;
  unsigned int lang_flag_19     : 1;
  unsigned int lang_flag_18     : 1;
  unsigned int lang_flag_17     : 1;
  unsigned int lang_flag_16     : 1;

  unsigned int lang_flag_15     : 1;
  unsigned int lang_flag_14     : 1;
  unsigned int lang_flag_13     : 1;
  unsigned int lang_flag_12     : 1;
  unsigned int lang_flag_11     : 1;
  unsigned int lang_flag_10     : 1;
  unsigned int lang_flag_9      : 1;
  unsigned int lang_flag_8      : 1;

  unsigned int lang_flag_7      : 1;
  unsigned int lang_flag_6      : 1;
  unsigned int lang_flag_5      : 1;
  unsigned int lang_flag_4      : 1;
  unsigned int lang_flag_3      : 1;
  unsigned int lang_flag_2      : 1;
  unsigned int lang_flag_1      : 1;
  unsigned int lang_flag_0      : 1;

    

/*  from GCC
  unsigned side_effects_flag : 1;
  unsigned constant_flag : 1;
  unsigned addressable_flag : 1;
  unsigned volatile_flag : 1;
  unsigned readonly_flag : 1;
  unsigned unsigned_flag : 1;
  unsigned asm_written_flag: 1;
  unsigned nowarning_flag : 1;

  unsigned used_flag : 1;
  unsigned nothrow_flag : 1;
  unsigned static_flag : 1;
  unsigned public_flag : 1;
  unsigned private_flag : 1;
  unsigned protected_flag : 1;
  unsigned deprecated_flag : 1;
  unsigned invariant_flag : 1;

  unsigned lang_flag_0 : 1;
  unsigned lang_flag_1 : 1;
  unsigned lang_flag_2 : 1;
  unsigned lang_flag_3 : 1;
  unsigned lang_flag_4 : 1;
  unsigned lang_flag_5 : 1;
  unsigned lang_flag_6 : 1;
  unsigned visited : 1;
*/
};

/*
 *
 */
struct nodeIdentifier {
  struct nodeCommon common;
  char *identifier;
//  union treeNode *replacement;
};

/*
 *
 */
struct nodeMacro {
  struct nodeCommon common;
  char *identifier;
  short parameterCount;
//  union treeNode firstParameter;
  union treeNode *replacement;
};

/*
 *
 */
struct nodeText {
  struct nodeCommon common;
  char *text;
};

/*
 *
 */
struct nodeComment {
  struct nodeCommon common;
  char *comment;
};

/*
 *
 */
struct nodeError {
  struct nodeCommon common;
  char *format;
};

/*
 *
 */
struct nodeLocation {
  struct nodeCommon common;
  char *file;
  int line;
};

/*
 *
 */
struct nodeFile {
  struct nodeCommon common;
  char *path;
  int lines;
  char *guardId;
  int guarded;
  time_t atime;
  time_t mtime;
};

/*
 *
 */
struct nodeIncludePath {
  struct nodeCommon common;
  char *path;
};

/*
 *
 */
union treeNode {
  struct nodeCommon         common;
  struct nodeIdentifier     identifier;
  struct nodeMacro          macro;
  struct nodeText           text;
  struct nodeComment        comment;
  struct nodeError          error;
  struct nodeLocation       location;
  struct nodeFile           file;
  struct nodeIncludePath    ipath;
};

struct nodeCommon        *newNodeCommon(enum tokenIndex);
struct nodeIdentifier    *newNodeIdentifier(enum tokenIndex);
struct nodeMacro         *newNodeMacro(enum tokenIndex);
struct nodeText          *newNodeText(enum tokenIndex);
struct nodeComment       *newNodeComment(enum tokenIndex);
struct nodeError         *newNodeError(enum tokenIndex);
struct nodeLocation      *newNodeLocation();
struct nodeFile          *newNodeFile();
struct nodeIncludePath   *newNodeIncludePath();

void add(void *treeNode);
void push(void *treeNode);
union treeNode *pop();
union treeNode *getCurrent();
union treeNode *getParent();

#endif // _bb188d3a_e320_11dc_8b9d_00502c05c241_

