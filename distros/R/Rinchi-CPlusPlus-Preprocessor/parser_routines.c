/*
 * UUID: bb188d3b-e320-11dc-8b9d-00502c05c241
 * Author: Brian M. Ames, bames@apk.net
 * Copyright: Copyright (C) 2008 by Brian M. Ames
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <search.h>
#include <time.h>
#include "parser_routines.h"
#include "rinchi_string.h"
#include "lexer.h"
#include "tree.h"
#include "include_path.h"

char *comment_buf;
int cbp;

char char_buf[CHAR_BUF_SIZE];
int char_buf_ptr=0;

struct nodeIdentifier *current_identifier_node = NULL;
struct nodeIdentifier *macro_identifier_node = NULL;
struct nodeMacro *current_macro = NULL;
struct nodeLocation *current_location;

void *macro_root = NULL;
void *uoc_root = NULL;
void *dep_root = NULL;
void *inc_root = NULL;

int replacement = 0;
int uoc_def;
int uoc_try;
int uoc_match;

signed char condition[CONDITION_DEPTH];
int condition_ptr=0;

int invalid_macro_id = 0;

extern int yypp_debug;
extern int out_comments;
extern int out_location;
extern FILE *outfile;
extern FILE *depfile;

extern struct nodeFile *curfilenode;
extern char *repl_id[];
extern int repl_level;

char **macro_args;
int macro_arg_index;
int macro_arg_count = 0;

struct tm *trans_time;

/*
 * Initialize parser routines.
 */
int parser_routines_init() {
  condition[0] = 1;
  return 0;
}

/*
 * Define predefined macros as specified by ISO/IEC 14882-2003.
 */
int predefined_macro_init() {
  char buf[32];
  time_t tmt;

  handle_token_open(PREDEFINED_MACRO_INDEX);
  time(&tmt);
  trans_time = localtime(&tmt);
  handle_command_line_define(strdup("__LINE__"));
  handle_command_line_define(strdup("__FILE__"));
  strftime (buf, 31, "__DATE__:\"%F\"", trans_time);
  handle_command_line_define(strdup(buf));
  strftime (buf, 31, "__TIME__:\"%T\"", trans_time);
  handle_command_line_define(strdup(buf));
  handle_command_line_define(strdup("__STDC__:1"));
  handle_command_line_define(strdup("__cplusplus:1"));
  handle_token_close(PREDEFINED_MACRO_INDEX);
  return 0;
}

/*
 * Compare two nodeIdentifier structs.
 */
int idncmp(const void *idn1, const void *idn2) {
  char *cp1,*cp2;
  cp1 = ((struct nodeIdentifier *) idn1)->identifier;
  cp2 = ((struct nodeIdentifier *) idn2)->identifier;
  return strcmp(cp1,cp2);
}

/*
 * Compare two identifiers.
 */
int idcmp(const void *id1, const void *id2) {

  return strcmp((char *) id1,(char *) id2);
} 

/*
 * Compare two paths.
 */
int depcmp(const void *idn1, const void *idn2) {
  char *cp1,*cp2;
  cp1 = (char *) idn1;
  cp2 = (char *) idn2;
  if (*cp1 == '/' && *cp2 != '/') return 1;
  if (*cp1 != '/' && *cp2 == '/') return -1;
  return strcmp(cp1,cp2);
}

/*
 * Compare two nodeMacro structs.
 */
int mcrcmp(const void *mcr1, const void *mcr2) {
  char *cp1,*cp2;
  cp1 = ((struct nodeMacro *) mcr1)->identifier;
  cp2 = ((struct nodeMacro *) mcr2)->identifier;
  return strcmp(cp1,cp2);
}

/*
 * Add a path to the dependency list.
 */
int add_dependency(char *dep_path) {
  void **tsr;
  if (yypp_debug != 0) {
    fprintf(stderr,"%s(%s); start\n",__func__,dep_path);
  }
  tsr = tfind(dep_path, &dep_root, depcmp);
  if (tsr == NULL) {
    tsr = tsearch(dep_path, &dep_root, depcmp);
  } else {
    fprintf(stderr,"Warning, file %s has already been included.\n",dep_path);
//    return 1;
  }
  return 0;
}

/*
 * Add a character to the buffer.
 */
void add_char(int ch) {
  if (char_buf_ptr < (CHAR_BUF_SIZE-1)) {
    char_buf[char_buf_ptr++] = ch;
    char_buf[char_buf_ptr] = 0;
  }
}

/*
 * Copy a string to the buffer.
 */
void copy_string(char *chars) {
  char *cp=chars;
  while(*cp != 0) add_char(*cp++);
}

/*
 * Copy a string less first and last characters to the buffer. Used for 
 * include headers.
 */
void copy_string_less(char *chars) {
  char *cp;
  size_t sz;

  cp = chars+1;
  sz=strlen(cp)-1;
  cp[sz]=0;
  while(*cp != 0) add_char(*cp++);
}

/*
 * Return char_buf as a string;
 */
char *get_str() {
  char *cp = strdup(char_buf);
  char_buf_ptr=0;
  char_buf[0] = 0;
  return cp;
}

//char *strndup(const char *S, size_t SIZE);

/*
 * Copy UTF-8 characters to the buffer using Universal Character Names.
 */
void copy_utf8(unsigned char *chars) {
  char buf[11];
  unsigned int ch;

  ch = chars[0];
  if ((ch & 0x80) == 0x00) {
    add_char(chars[0]);
    return;
  } else
  if ((ch & 0xE0) == 0xC0) {
    ch = ((chars[0] & 0x1F) << 6) | (chars[1] & 0x3F);
  } else
  if ((ch & 0xF0) == 0xE0) {
    ch = ((chars[0] & 0x0F) << 6) | (chars[1] & 0x3F);
    ch <<= 6;
    ch |= (chars[2] & 0x3F);
  } else
  if ((ch & 0xF8) == 0xF0) {
    ch = ((chars[0] & 0x07) << 6) | (chars[1] & 0x3F);
    ch <<= 6;
    ch |= (chars[2] & 0x3F);
    ch <<= 6;
    ch |= (chars[3] & 0x3F);
  }
  if (ch <= 0xFFFF) {
    sprintf(buf,"\\u%04X",ch);
  } else {
    sprintf(buf,"\\U%08X",ch);
  }
  copy_string(buf);
}

/*
 * Return char_buf interpreted as an octal value.
 */
long get_value_octal() {
  char *tail;
  long res;

  res = strtol(char_buf, &tail, 8);
  char_buf_ptr = 0;
//  char_buf[0] = 0;
  return res;
}

/*
 * Return char_buf interpreted as an decimal value.
 */
long get_value_decimal() {
  char *tail;
  long res;

  res = strtol(char_buf, &tail, 10);
  char_buf_ptr = 0;
//  char_buf[0] = 0;
  return res;
}

/*
 * Return char_buf interpreted as an hexadecimal value.
 */
long get_value_hexadecimal() {
  char *tail;
  long res;

  res = strtol(char_buf, &tail, 16);
  char_buf_ptr = 0;
//  char_buf[0] = 0;
  return res;
}

/*
 *
 */
void handle_comment(char *tokenString) {
  struct nodeComment *node;
  if (yypp_debug != 0) {
    fprintf(stderr,"%s\n",__func__);
  }
  if(out_comments != 0) {
    node = newNodeComment(COMMENT_INDEX);
    node->comment = strdup(tokenString);
    add(node);
  }
}

/*
 *
 */
void handle_begin_comment() {
  comment_buf = (char *) malloc(COMMENT_BUFFER_SIZE);
  cbp = 0;
}

/*
 *
 */
void handle_comment_char(int ch) {
  if((cbp > 0 || ch != ' ') && (cbp < MAX_COMMENT_STRING)) {
    comment_buf[cbp++] = ch;
  }
}

/*
 *
 */
void handle_end_comment() {
  struct nodeComment *node;
  comment_buf[cbp] = 0;
  cbp--;
  while( cbp >=0 && comment_buf[cbp] == ' ') {
    comment_buf[cbp--] = 0;
  }
  if(out_comments != 0) {
    node = newNodeComment(BLOCK_COMMENT_INDEX);
    node->comment = strdup(comment_buf);
    add(node);
  }
  free(comment_buf);
  comment_buf = NULL;
}

/*
 *
 */
void handle_file_begin(enum tokenIndex ti) {
  if (yypp_debug != 0) {
    fprintf(stderr,"%s\n",__func__);
  }
  if (condition[condition_ptr] == 1) {
    push(curfilenode);
  }
}

/*
 *
 */
void handle_file_end(enum tokenIndex token) {
  union treeNode *node;
  if (yypp_debug != 0) {
    fprintf(stderr,"%s\n",__func__);
  }
  if (condition[condition_ptr] == 1) {
    node = pop();
  }
}

/*
 *
 */
void handle_location() {
  if (yypp_debug != 0) {
    fprintf(stderr,"%s();\n",__func__);
    fprintf(stderr,"condition[%d] == %d\n",condition_ptr,condition[condition_ptr]);
  }
  if (condition[condition_ptr] == 1) {
    if(out_location == 0) {
      current_location = newNodeLocation();
      current_location->common.nodeType = NODE_TYPE_LOCATION;
      current_location->file =  getCurrentFilename();
      current_location->line =  getCurrentLineNumber();
      current_location->common.tokenIndex = LOCATION_INDEX;
      add(current_location);
    }
  }
  if (yypp_debug != 0) {
    fprintf(stderr,"%s(); end\n",__func__);
  }
}

/*
 *
 */
void handle_token(enum tokenIndex ti) {
  struct nodeCommon *node;
  if (yypp_debug != 0) {
    fprintf(stderr,"%s %s\n",__func__,tokenString[ti]);
  }
  if (condition[condition_ptr] == 1) {
    node = newNodeCommon(ti);
    add(node);
  }
}

/*
 *
 */
void handle_string_token(enum tokenIndex ti) {
  struct nodeText *node;
  if (yypp_debug != 0) {
    fprintf(stderr,"%s(%d,\"%s\");\n",__func__,ti,char_buf);
  }
  if (condition[condition_ptr] == 1) {
    node = newNodeText(ti);
    node->text = strdup(char_buf);
    add(node);
  }
  char_buf_ptr = 0;
  char_buf[0] = 0;
}

/*
 *
 */
void handle_token_open(enum tokenIndex ti) {
  struct nodeCommon *node;
  if (yypp_debug != 0) {
    fprintf(stderr,"%s\n",__func__);
  }
  if (condition[condition_ptr] == 1) {
    node = newNodeCommon(ti);
    push(node);
  }
}

/*
 *
 */
void handle_token_close(enum tokenIndex token) {
  union treeNode *node;
  if (yypp_debug != 0) {
    fprintf(stderr,"%s\n",__func__);
  }
  if (condition[condition_ptr] == 1) {
    node = pop();
  }
}

/*
 * Processes the identifier currently stored in char_buf
 */
int test_identifier() {
  struct nodeMacro *node;
  struct nodeMacro **tsr;
//  char **tsr2;
  struct nodeCommon *argnode;
  char *identifier;
  int result = 0;
  int i;
  int scr;

  if (yypp_debug != 0) {
    fprintf(stderr,"%s(\"%s\")\n",__func__,char_buf);
  }
  identifier = strdup(char_buf);
  char_buf_ptr = 0;
  node = newNodeMacro(IDENTIFIER_INDEX);
  node->identifier = identifier;
  tsr = (struct nodeMacro**) tfind(node, &macro_root, mcrcmp);
  if (tsr == NULL) {
    current_macro = NULL;
  } else {
    current_macro = (struct nodeMacro *) *tsr;
    repl_id[repl_level+1] = identifier;
    if (repl_level >= 20) return 0;  // probably an infinite loop
    switch(current_macro->common.tokenIndex) {
    case object_macro_index:
      for (i=1; i<=repl_level; i++) {
        if(repl_id[repl_level] != NULL) {
          scr = strcmp(identifier, repl_id[i]);
          if(scr == 0) {
            if (yypp_debug != 0) {
              fprintf(stderr,"%s(\"%s\") = 0;\n",__func__,current_macro->identifier);
            }
            return 0;
          }
        }
      }
      if(repl_id[repl_level] == NULL || strcmp(identifier, repl_id[repl_level]) != 0) {
        if (current_macro->replacement == NULL) {
          result = 1;
        } else {
          result = 2;
        }
      }
      break;
    case function_macro_index:
      macro_arg_count = 0;
      for (argnode = current_macro->common.firstChild; 
          argnode != NULL;
          argnode = argnode->nextSibling) macro_arg_count++;
      if (macro_arg_count == 0) {
        result = 3;
      } else {
        result = 4;
        macro_args = (char **) malloc(macro_arg_count * sizeof(char *));
        macro_arg_index = 0;
      }
      break;
    default:
      fprintf(stderr,"%s(?);\n",__func__);
      result = 1;
      break;
    }
  }
  if (yypp_debug != 0) {
    if (current_macro == NULL) {
      fprintf(stderr,"%s(\"%s\") = %d;\n",__func__,identifier,result);
    } else {
      fprintf(stderr,"%s(\"%s\") = %d;\n",__func__,current_macro->identifier,result);
    }
  }
  return result;
}

/*
 *
 */
char *get_replacement_string() {
  union treeNode *node;
//  struct nodeText *text;
  int sz = 2;
  int stringize = 0;
  int index;
  int i;
  char *repl = NULL;
  char *cp;
  char *buf;

  if(strcmp(current_macro->identifier,"__LINE__") == 0) {
    buf = (char *) malloc(20);
    sprintf(buf,"%d",getCurrentLineNumber()-1);
    repl = strdup(buf);
    free(buf);
    return repl;
  } else
  if(strcmp(current_macro->identifier,"__FILE__") == 0) {
    buf = getCurrentFilename();
    repl = (char *) malloc(strlen(buf)+3);
    sprintf(repl,"\"%s\"",buf);
    return repl;
  }


// macro_identifier_node
  for(node = (union treeNode *) current_macro->replacement->common.firstChild; node != NULL; node = (union treeNode *) node->common.nextSibling) {
    switch(node->common.nodeType) {
    case NODE_TYPE_COMMON:
      switch(node->common.tokenIndex) {
      case OP_TOKEN_SPLICE_INDEX:
        break;
      case OP_STRINGIZE_INDEX:
        sz += 2;
        break;
      default:
        break;
      }
      break;
    case NODE_TYPE_IDENTIFIER:
      if (node->common.replaceable_flag == 0) {
          sz += strlen(node->identifier.identifier)+1;
      } else {
        index = get_param_index(node->identifier.identifier);
        if (index >=0 && index < macro_arg_count) {
          if (stringize == 1) {
            sz += strlen(node->identifier.identifier)+2;
          } else {
            sz += strlen(macro_args[index]);
            if(strcmp(macro_args[index],current_macro->identifier) == 0) {
              sz++;
            }
          }
        }
      }
      break;
    case NODE_TYPE_TEXT:
      sz += strlen(node->text.text);
      break;
    default:
      break;
    }
    
  }
  repl = (char *) malloc(sz);
  memset(repl, 0, sz);
  for(node = (union treeNode *) current_macro->replacement->common.firstChild; node != NULL; node = (union treeNode *) node->common.nextSibling) {
    switch(node->common.nodeType) {
    case NODE_TYPE_COMMON:
      switch(node->common.tokenIndex) {
      case OP_TOKEN_SPLICE_INDEX:
        break;
      case OP_STRINGIZE_INDEX:
        stringize=1;
        break;
      default:
        break;
      }
      break;
    case NODE_TYPE_IDENTIFIER:
      if (node->common.replaceable_flag == 0) {
        strcat(repl,node->identifier.identifier);
//        strcat(repl,"\033");
//        strcat(repl,"_");
        strcat(repl,"\x9b");
      } else {
        index = get_param_index(node->identifier.identifier);
        if (index >=0 && index < macro_arg_count) {
          if (stringize == 1) {
            strcat(repl,"\"");
            i = strlen(repl);
            for(cp = macro_args[index]; *cp == ' ' || *cp == '\t'; cp++);
            while(*cp != 0) {
              if(*cp == ' ' || *cp == '\t') {
                cp++;
                if (*cp == ' ' || *cp == '\t' || *cp == 0) {
                } else {
                  repl[i++] = ' ';
                }
              } else {
                repl[i++] = *cp++;
              }
            }

            strcat(repl,"\"");
          } else {
            strcat(repl,macro_args[index]);
            if(strcmp(macro_args[index],current_macro->identifier) == 0) {
              strcat(repl,"\x9b");
            }
          }
        }
      }
      stringize=0;
      break;
    case NODE_TYPE_TEXT:
      strcat(repl,node->text.text);
      break;
    default:
      if (yypp_debug != 0) {
        fprintf(stderr,"token=\"%s\"\n", tokenString[node->common.tokenIndex]);
      }
      break;
    }
    
  }
  if (yypp_debug != 0) {
    fprintf(stderr,"%s() repl=\"%s\"\n",__func__, repl);
  }
  if(current_macro->common.tokenIndex == function_macro_index) {
    strcat(repl,"\033");
  }
  return repl;
}

/*
 *
 */
void handle_identifier(enum tokenIndex ti) {
  struct nodeIdentifier *node;
  if (condition[condition_ptr] == 1) {
    if(current_identifier_node == NULL) {
      node = newNodeIdentifier(ti);
      node->identifier = strdup(char_buf);
    } else {
      node = current_identifier_node;
      current_identifier_node = NULL;
    }
    add(node);
    if (replacement) {
      if(strcmp(node->identifier,current_macro->identifier) == 0) {
        node->common.replaceable_flag = 0;
      } else {
        node->common.replaceable_flag = 1;
      }
    }
    if (yypp_debug != 0) {
      fprintf(stderr,"%s(\"%s\",%d)\n",__func__,node->identifier,node->common.replaceable_flag);
    }
  } else {
    if (yypp_debug != 0) {
      fprintf(stderr,"%s\n",__func__);
    }
  }
  char_buf_ptr = 0;
  char_buf[0] = 0;
}

/*
 *
 */
void handle_nonrepl_identifier(enum tokenIndex ti) {
  struct nodeIdentifier *node;
//  if (yypp_debug != 0) {
//    fprintf(stderr,"%s\n",__func__);
//  }
  if (condition[condition_ptr] == 1) {
    if(current_identifier_node == NULL) {
      node = newNodeIdentifier(ti);
      node->identifier = strdup(char_buf);
      node->common.replaceable_flag = 0;
    } else {
      node = current_identifier_node;
      current_identifier_node = NULL;
    }
    add(node);
    if (yypp_debug != 0) {
      fprintf(stderr,"%s(\"%s\",%d)\n",__func__,node->identifier,node->common.replaceable_flag);
    }
  } else {
    if (yypp_debug != 0) {
      fprintf(stderr,"%s\n",__func__);
    }
  }
  char_buf_ptr = 0;
  char_buf[0] = 0;
}

/*
 *
 */
void handle_identifier_open(enum tokenIndex ti) {
  struct nodeIdentifier *node;
  if (yypp_debug != 0) {
    fprintf(stderr,"%s\n",__func__);
  }
  if (condition[condition_ptr] == 1) {
    node = newNodeIdentifier(ti);
    node->identifier = strdup(char_buf);
    push(node);
  }
  char_buf_ptr = 0;
  char_buf[0] = 0;
}

/*
 *
 */
void handle_include(enum tokenIndex ti) {
  if (condition[condition_ptr] == 1) {
    handle_include_file();
  }
}

/*
 *
 */
void handle_command_line_define(char *arg) {
  char *cp;
  if (yypp_debug != 0) {
    fprintf(stderr,"%s(\"%s\");\n",__func__,arg);
  }
  for(cp = arg; *cp != '=' && *cp != ':' && *cp != 0; cp++);
  if (*cp == 0) {
    copy_string(arg);
    handle_macro_open(object_macro_index); 
  } else {
    *cp++ = 0;
    copy_string(arg);
    handle_macro_open(object_macro_index); 
    copy_string(cp);
    handle_string_token(STRING_LITERAL_INDEX);
  }
  handle_macro_close (object_macro_index);
}

/*
 *
 */
void handle_define(const char *identifier) {
  void **tsr;
  fprintf(stderr,"1 %s(\"%s\");\n",__func__,identifier);
  if (condition[condition_ptr] == 1) {
    if((curfilenode->guarded == 1) && (0 == strcmp(identifier, curfilenode->guardId))) {
      curfilenode->guarded = 2;
    } else {
      curfilenode->guarded = -1;
    }
    tsr = tfind(identifier, &macro_root, idcmp);
    if (tsr == NULL) {
      tsr = tsearch(identifier, &macro_root, idcmp);
    } else {
      fprintf(stderr,"Error, macro %s is already defined.\n",identifier);
    }
  }
  if (yypp_debug != 0) {
    fprintf(stderr,"%s(\"%s\");\n",__func__,identifier);
    fprintf(stderr,"condition[%d]=%d\n",condition_ptr,condition[condition_ptr]);
    fprintf(stderr,"guarded=%d\n",curfilenode->guarded);
  }
}

/*
 *
 */
void handle_replacement_open(enum tokenIndex ti) {
  struct nodeCommon *node;
  struct nodeCommon *current;
  if (yypp_debug != 0) {
    fprintf(stderr,"%s\n",__func__);
  }
  if (condition[condition_ptr] == 1) {
    current = (struct nodeCommon *) getCurrent();
//    current_macro = (struct nodeMacro *) getParent();
    node = newNodeCommon(ti);
    push(node);
    if(current != NULL) {
      current->nextSibling = NULL;
    }
    current_macro->replacement = (union treeNode*) node;
    replacement = 1;
  }
}

/*
 *
 */
void handle_replacement_close(enum tokenIndex token) {
  union treeNode *node;
  if (yypp_debug != 0) {
    fprintf(stderr,"%s\n",__func__);
  }
  if (condition[condition_ptr] == 1) {
    node = pop();
    if(current_macro->common.tokenIndex == object_macro_index) {
      current_macro->common.firstChild = 0;
    }
    replacement = 0;
  }
}

/*
 *
 */
int skip_line() {
  int result = 1;
  if (condition[condition_ptr] > 0) {
    result = 0;
  }
  if (yypp_debug != 0) {
    fprintf(stderr,"%s() = %d;\n",__func__, result);
    fprintf(stderr,"condition[%d] = %d\n",condition_ptr,condition[condition_ptr]);
  }
  return result;
}

/*
 *
 */
int dont_care() {
  int result = 1;
  if (condition[condition_ptr] >= 0) {
    result = 0;
  }
  if (yypp_debug != 0) {
    fprintf(stderr,"%s() = %d;\n",__func__, result);
    fprintf(stderr,"condition[%d] = %d\n",condition_ptr,condition[condition_ptr]);
  }
  return result;
}

/*
 * Return the index of the macro parameter with the given name or -1 if
 * it is not found.
 */
int get_param_index(char *identifier) {
  struct nodeIdentifier *node;
  int index = -1;
  int i;

  if (yypp_debug != 0) {
    fprintf(stderr,"%s(\"%s\");\n",__func__,identifier);
  }
  i = 0;
  if (current_macro != NULL && current_macro->common.firstChild != NULL) {
    for (node = (struct nodeIdentifier *) current_macro->common.firstChild; 
        node != NULL; 
        node = (struct nodeIdentifier *) node->common.nextSibling) {
      if (node != NULL && node->common.tokenIndex == IDENTIFIER_INDEX) {
        if (node->identifier != NULL) {
          if (strcmp(identifier,node->identifier) == 0) {
            index=i;
            break;
          }
        }
      }
      i++;
    }
  }
  if (yypp_debug != 0) {
    fprintf(stderr,"%s(\"%s\")=%d;\n",__func__,identifier,index);
  }
  return index;
}

/*
 * Tests the identifier in char_buf to see if it matches a macro parameter name.
 * Returns 1 if it matches, 0 otherwise.
 */
int is_param_id() {
  int index;

  if (yypp_debug != 0) {
    fprintf(stderr,"%s(\"%s\");\n",__func__,char_buf);
  }
  if (current_macro == NULL || current_macro->common.tokenIndex == object_macro_index) {
    index = -1;
  } else {
    index = get_param_index(char_buf);
  }
  return (index < 0) ? 0 : 1;
}

/*
 *
 */
int is_macro_id() {
  int index;

  if (yypp_debug != 0) {
    fprintf(stderr,"%s(\"%s\");\n",__func__,char_buf);
  }
  index = strcmp(char_buf,current_macro->identifier);
  return (index == 0) ? 1 : 0;
}

/*
 *
 */
void handle_macro_arg() {
  if (yypp_debug != 0) {
    fprintf(stderr,"%s(%s);\n",__func__,char_buf);
  }
  if (macro_arg_index < macro_arg_count) {
    macro_args[macro_arg_index++] = strdup(char_buf);
  } else {
    fprintf(stderr,"Too many arguments for macro.\n");
  }
  char_buf_ptr = 0;
  char_buf[0] = 0;
}

/*
 *
 */
void handle_macro_open(enum tokenIndex ti) {
  current_macro = newNodeMacro(ti);
  current_macro->identifier = strdup(char_buf);
  if (condition[condition_ptr] == 1) {
    push(current_macro);
    if((curfilenode->guarded == 1) && (0 == strcmp(current_macro->identifier, curfilenode->guardId))) {
      curfilenode->guarded = 2;
    } else {
      curfilenode->guarded = -1;
    }
  }
  if (yypp_debug != 0) {
    fprintf(stderr,"%s(\"%s\");\n",__func__,char_buf);
    fprintf(stderr,"condition[%d]=%d\n",condition_ptr,condition[condition_ptr]);
    fprintf(stderr,"guarded=%d\n",curfilenode->guarded);
  }
  char_buf_ptr = 0;
  char_buf[0] = 0;
}

/*
 *
 */
void handle_macro_close(enum tokenIndex ti) {
  struct nodeMacro *node;
  void *tsr;
  if (yypp_debug != 0) {
    fprintf(stderr,"%s\n",__func__);
  }
  if (condition[condition_ptr] == 1) {
    node = (struct nodeMacro *) pop();
    tsr = tfind(node, &macro_root, idncmp);
    if (invalid_macro_id == 0) {
      if (tsr == NULL) {
        tsr = tsearch(node, &macro_root, idncmp);
      } else {
        fprintf(stderr,"Warning, macro %s is already defined.\n",node->identifier);
      }
    }
  }
  invalid_macro_id = 0;
}

/*
 *
 */
void handle_macro_undef(enum tokenIndex ti) {
  struct nodeMacro *node;
  void *tsr;
  if (yypp_debug != 0) {
    fprintf(stderr,"%s(\"%s\")\n",__func__,char_buf);
  }
  if (condition[condition_ptr] == 1) {
    node = newNodeMacro(ti);
    node->identifier = strdup(char_buf);
    node->common.replaceable_flag = 0;
    add(node);
    tsr = tfind(node, &macro_root, idncmp);
    if (tsr == NULL) {
    } else {
      tsr = tdelete(node, &macro_root, idncmp);
    }
  }
  char_buf_ptr = 0;
  char_buf[0] = 0;
}

/*
 *
 */
void handle_if_open(enum tokenIndex ti, int value) {
  if (yypp_debug != 0) {
    fprintf(stderr,"%s(%d,%d)\n",__func__,ti,value);
    fprintf(stderr,"condition[%d]=%d\n",condition_ptr,condition[condition_ptr]);
  }
  if (condition[condition_ptr] != 1) {
    condition[++condition_ptr] = -1;
  } else {
    condition_ptr++;
    char_buf_ptr = 0;
    char_buf[0] = 0;
    if (value == 0) {
      condition[condition_ptr] = 0;
      enter_cond_state();
    } else {
      condition[condition_ptr] = 1;
      exit_cond_state();
    }
  }
  if (yypp_debug != 0) {
    fprintf(stderr,"condition[%d]=%d\n",condition_ptr,condition[condition_ptr]);
  }
}

/*
 *
 */
void handle_ifdef_open(enum tokenIndex ti) {
  struct nodeIdentifier *node;
  void *tsr;
  if (yypp_debug != 0) {
    fprintf(stderr,"%s\n",__func__);
    fprintf(stderr,"condition[%d]=%d\n",condition_ptr,condition[condition_ptr]);
  }
  if (condition[condition_ptr] != 1) {
    condition[++condition_ptr] = -1;
  } else {
    condition_ptr++;
    node = newNodeIdentifier(ti);
    node->identifier = strdup(char_buf);
    char_buf_ptr = 0;
    char_buf[0] = 0;
    tsr = tfind(node, &macro_root, idncmp);
    if (tsr == NULL) {
      condition[condition_ptr] = 0;
      enter_cond_state();
    } else {
      condition[condition_ptr] = 1;
      exit_cond_state();
    }
    free(node);
  }
  if (yypp_debug != 0) {
    fprintf(stderr,"condition[%d]=%d\n",condition_ptr,condition[condition_ptr]);
  }
}

/*
 *
 */
void handle_ifndef_open(enum tokenIndex ti) {
  char *identifier;
  struct nodeIdentifier *node;
  void *tsr;
  if (yypp_debug != 0) {
    fprintf(stderr,"%s\n",__func__);
    fprintf(stderr,"condition[%d]=%d\n",condition_ptr,condition[condition_ptr]);
    fprintf(stderr,"guarded=%d\n",curfilenode->guarded);
  }
  identifier = strdup(char_buf);
  if(curfilenode->guarded == 0) {
    if (condition[condition_ptr] == 1) {
      curfilenode->guarded = 1;
      curfilenode->guardId = identifier;
    } else {
      curfilenode->guarded = -1;
    }
  }
  if (condition[condition_ptr++] != 1) {
    condition[condition_ptr] = -1;
  } else {
    node = newNodeIdentifier(ti);
    node->identifier = strdup(char_buf);
    char_buf_ptr = 0;
    char_buf[0] = 0;
    tsr = tfind(node, &macro_root, idncmp);
    if (tsr == NULL) {
      condition[condition_ptr] = 1;
      exit_cond_state();
    } else {
      condition[condition_ptr] = 0;
      enter_cond_state();
    }
    free(node);
  }
  if (yypp_debug != 0) {
    fprintf(stderr,"condition[%d]=%d\n",condition_ptr,condition[condition_ptr]);
  }
}

/*
 *
 */
void handle_else_open(enum tokenIndex ti) {
  if (yypp_debug != 0) {
    fprintf(stderr,"%s\n",__func__);
    fprintf(stderr,"condition[%d]=%d\n",condition_ptr-1,condition[condition_ptr-1]);
    fprintf(stderr,"condition[%d]=%d\n",condition_ptr,condition[condition_ptr]);
  }
  if (condition[condition_ptr-1] == -1) {
  } else {
    if (condition[condition_ptr] == 0) {
      condition[condition_ptr] = 1;
      exit_cond_state();
    } else {
      condition[condition_ptr] = 0;
      enter_cond_state();
    }
  }
  if (yypp_debug != 0) {
    fprintf(stderr,"condition[%d]=%d\n",condition_ptr,condition[condition_ptr]);
  }
}

/*
 *
 */
void handle_elif_open(enum tokenIndex ti, int value) {
  if (yypp_debug != 0) {
    fprintf(stderr,"%s(%d,%d)\n",__func__,ti,value);
    fprintf(stderr,"condition[%d]=%d\n",condition_ptr,condition[condition_ptr]);
  }
  if (condition[condition_ptr-1] == -1) {
  } else {
    if (condition[condition_ptr++] == 0) {
      if (value == 0) {
        condition[condition_ptr] = 0;
      } else {
        condition[condition_ptr] = 1;
        condition[condition_ptr-1] = 1;
      }
    } else {
      condition[condition_ptr] = -1;
    }
  }
  if (yypp_debug != 0) {
    fprintf(stderr,"condition[%d]=%d\n",condition_ptr,condition[condition_ptr]);
  }
}

/*
 * check if we need this
 */
void handle_elif_close(enum tokenIndex ti) {
  if (yypp_debug != 0) {
    fprintf(stderr,"%s(%d)\n",__func__,ti);
    fprintf(stderr,"condition[%d]=%d\n",condition_ptr,condition[condition_ptr]);
  }
  condition_ptr--;
}

/*
 *
 */
void handle_endif(enum tokenIndex ti) {
  condition_ptr--;
  if (condition[condition_ptr] == 0) {
    enter_cond_state();
  } else {
    exit_cond_state();
  }
  if (yypp_debug != 0) {
    fprintf(stderr,"%s\n",__func__);
    fprintf(stderr,"condition[%d]=%d\n",condition_ptr,condition[condition_ptr]);
  }
}

/*
 *
 */
void handle_header_name(enum tokenIndex ti) {
  extern char *include_file_name;
  struct nodeText *node;
  if (yypp_debug != 0) {
    fprintf(stderr,"%s\n",__func__);
  }
  if (condition[condition_ptr] == 1) {
    node = newNodeText(ti);
    node->text = strdup(char_buf);
    add(node);
    include_file_name=node->text;
  }
  char_buf_ptr = 0;
  char_buf[0] = 0;
}

/*
 * Handle preprocessing number.
 */
void handle_pp_number() {
  struct nodeText *node;

  if (yypp_debug != 0) {
    fprintf(stderr,"%s\n",__func__);
  }
  if (condition[condition_ptr] == 1) {
    node = newNodeText(PP_NUMBER_INDEX);
    node->text = strdup(char_buf);
    add(node);
  }
  char_buf_ptr = 0;
  char_buf[0] = 0;
}

/*
 * Handle an invalid macro identifier.
 */
void handle_invalid_macro_id(enum tokenIndex ti) {
  struct nodeError *node;

  if (yypp_debug != 0) {
    fprintf(stderr,"%s\n",__func__);
  }
  if (condition[condition_ptr] == 1) {
    node = newNodeError(ti);
    node->format = " error=\"&quot;%s&quot; cannot be used as a macro name as it is an operator in C++\"";
    push(node);
    invalid_macro_id = 1;
  }
}

/*
 * Add the given use on code to those to be selected.
 */
void define_use_on_code(const char *use_on_code) {
  struct nodeText *node;
  void **tsr;
  if (yypp_debug != 0) {
    fprintf(stderr,"%s(\"%s\");\n",__func__,use_on_code);
  }
  uoc_def++;
  tsr = tfind(use_on_code, &uoc_root, idcmp);
  if (tsr == NULL) {
    tsr = tsearch(use_on_code, &uoc_root, idcmp);
    node = newNodeText(USE_ON_CODE_INDEX);
    node->text = strdup(use_on_code);
    add(node);
  } else {
    fprintf(stderr, "Warning, use on code %s is already defined.\n",use_on_code);
  }
}

/*
 * Try the use on code against those selected, if any.
 */
void handle_use_on_code(const char *use_on_code) {
  void **tsr;

  if(uoc_def > 0) {
    tsr = tfind(use_on_code, &uoc_root, idcmp);
    uoc_try++;
    if (tsr == NULL) {
    } else {
      uoc_match = 1;
    }
  }
  if (yypp_debug != 0) {
    fprintf(stderr,"%s(\"%s\") = %d;\n",__func__,use_on_code, uoc_match);
  }
}

/*
 * Test to see if a use on code has been matched or no tries have occurred.
 */
int use_on_code_matched() {
  int result = 0;
  if (uoc_try == 0 || uoc_match == 1) {
    result = 1;
  }  
  uoc_try = 0;
  uoc_match = 0;
  if (yypp_debug != 0) {
    fprintf(stderr,"%s(uoc_try=%d,uoc_match=%d) = %d;\n",__func__,uoc_try,uoc_match, result);
  }
  return result;
}

/*
 * Add a directory to the list of those to be searched for included files.
 */
void define_include_directory(char *directory) {
  void **tsr;
  if (yypp_debug != 0) {
    fprintf(stderr,"%s(\"%s\");\n",__func__,directory);
  }
  tsr = tfind(directory, &inc_root, depcmp);
  if (tsr == NULL) {
    tsr = tsearch(directory, &inc_root, depcmp);
    add_incl_path(directory);
    if (yypp_debug != 0) {
      fprintf(stderr,"Include directory %s added.\n",directory);
    }
  } else {
    fprintf(stderr, "Warning, include directory %s is already defined.\n",directory);
  }
}


