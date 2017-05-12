/*
 * UUID: 10ca5ccc-f2fd-11dc-95c2-00502c05c241
 * Author: Brian M. Ames, bames@apk.net
 * Copyright: Copyright (C) 2008 by Brian M. Ames
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "toperl.h"
#include "lexer.h"
#include "Preprocessor.h"
#include "parser_routines.h"
#include "parser.tab.h"

FILE *infile, *depfile;

time_t max_st_atime;
time_t max_st_mtime;
int error_count;

int argx;
int argc=0;
char **argv = NULL;

extern union treeNode *tree_stack[TREE_STACK_SIZE];
extern FILE *yypp_in; //, *yypp_out;
extern int yypp_debug;
extern int tree_debug;

/*
 *
 */
int yypp_wrap() {
  // return 0;  more files;
  return 1; // no more
}

/*
 *
 */
void malloc_argv(int size) {
  argv = (char **) malloc(size * sizeof(char *));
  argx = 0;
  argc = size - 1;
}

/*
 *
 */
void add_argv(char *arg) {
  if(argx < argc) {
    argv[argx++] = strdup(arg);
  }
}

/*
 *
 */
void parse(char *path) {
  void parseArgv(int argc, char **argv);
  int result;
  int yypp_parse (void);
  extern union treeNode *tree_root;

  yypp_debug = 0;
  infile = fopen(path,"r");
  if (!infile) {
    fprintf(stderr,"could not open input file '%s'\n",path);
    exit(1);
  }
  initialize_lexer(path);
//  fprintf(stderr,"parser_routines_init()\n");
  parser_routines_init();
//  fprintf(stderr,"handle_token_open(translation_unit_index)\n");
  handle_token_open(translation_unit_index);
//  fprintf(stderr,"predefined_macro_init()\n");
  predefined_macro_init();
//  fprintf(stderr,"handle_token_open(COMMAND_LINE_INDEX)\n");
  handle_token_open(COMMAND_LINE_INDEX);
  if(argc > 0) {
    parseArgv(argc, argv);
  }
  handle_token_close(COMMAND_LINE_INDEX);
  yypp_in = infile;
  result = yypp_parse();
  handle_token_close(translation_unit_index);
  fclose(infile);
  if (depfile) {
    fclose(depfile);
  }
  dumpTree(tree_root);
}

/*
 *
 */
void dumpTree(union treeNode *tree_node) {
  if (tree_debug != 0) {
    fprintf(stderr,"%s();\n",__func__);
  }
  call_XMLDeclHandler("1.0", "UTF-8", "yes");
  call_CommentHandler("Created by Rinchi::CPlusPlus::Preprocessor");
  dumpTreeNode(tree_node);
}

/*
 *
 */
void dumpTreeNode(union treeNode *tree_node) {
  char buf[65];

  if (tree_node == NULL) {
    return;
  }

  if (tree_debug != 0) {
    fprintf(stderr,"%s(%d,%d);\n",__func__,tree_node->common.nodeType,tree_node->common.tokenIndex);
  }

  if ((tree_node->common.nodeType == NODE_TYPE_LOCATION && tree_node->common.tokenIndex != LOCATION_INDEX ) 
   || (tree_node->common.nodeType == NODE_TYPE_IPATH    && tree_node->common.tokenIndex != INCLUDE_DIRECTORY_INDEX )) {
   fprintf(stderr,"%s: Invalid tree node (%d,%d)\n",__func__,tree_node->common.nodeType,tree_node->common.tokenIndex);
   sprintf(buf,"%s: Invalid tree node (%d,%d)\n",__func__,tree_node->common.nodeType,tree_node->common.tokenIndex);
   call_CommentHandler(strdup(buf));
   return;
  }
  
  dumpTreeNodePreorder(tree_node);
  dumpTreeNode((union treeNode *) tree_node->common.firstChild);
  if(tree_node->common.nodeType == NODE_TYPE_MACRO) {
    dumpTreeNode((union treeNode *) ((struct nodeMacro *) tree_node)->replacement);
  }
  dumpTreeNodeInorder(tree_node);
  dumpTreeNode((union treeNode *) tree_node->common.nextSibling);
}

/*
 *
 */
void dumpTreeNodePreorder(union treeNode *tree_node) {
  char *tag;
  char *buf;
  char *atime,*mtime;
  int hasChild;
  struct tm *tr_time;

  if (tree_node == NULL) {
    return;
  }

  if ((tree_node->common.nodeType == NODE_TYPE_LOCATION && tree_node->common.tokenIndex != LOCATION_INDEX ) 
   || (tree_node->common.nodeType == NODE_TYPE_IPATH    && tree_node->common.tokenIndex != INCLUDE_DIRECTORY_INDEX )) {
   fprintf(stderr,"%s: Invalid tree node (%d,%d)\n",__func__,tree_node->common.nodeType,tree_node->common.tokenIndex);
   return;
  }
  
  tag = tokenString[tree_node->common.tokenIndex];
  if (tree_debug != 0) {
    fprintf(stderr,"%s(%d,%s,%d,%s);\n",__func__,tree_node->common.nodeType,nodeString[tree_node->common.nodeType],tree_node->common.tokenIndex,tag);
  }

  hasChild = tree_node->common.firstChild == NULL ? 0 : 1;
  switch(tree_node->common.nodeType) {
  case NODE_TYPE_COMMON:
    call_StartElementHandlerCommon(tag, hasChild);
    break;
  case NODE_TYPE_IDENTIFIER:
    call_StartElementHandlerIdentifier(tag, hasChild, tree_node->identifier.identifier, 
       (tree_node->common.replaceable_flag) ? "yes" : "no");
    break;
  case NODE_TYPE_MACRO:
    hasChild = tree_node->macro.replacement == NULL ? hasChild : 1;
    call_StartElementHandlerMacro(tag, hasChild, tree_node->macro.identifier);
    break;
  case NODE_TYPE_TEXT:
    call_StartElementHandlerText(tag, hasChild, tree_node->text.text);
    break;
  case NODE_TYPE_COMMENT:
    hasChild = tree_node->comment.comment == NULL ? hasChild : 1;
    call_StartElementHandlerCommon(tag, hasChild);
    call_StartCdataHandler();
    call_CharacterDataHandler(tree_node->comment.comment);
    call_EndCdataHandler();
    break;
  case NODE_TYPE_ERROR:
    call_ProcessingInstructionHandler(tag,tree_node->error.format);
    break;
  case NODE_TYPE_LOCATION:
    buf = (char *) malloc(strlen(tree_node->location.file) + 12);
    sprintf(buf,"\"%s\" %d",tree_node->location.file,tree_node->location.line);
    call_ProcessingInstructionHandler(tag,buf);
    break;
  case NODE_TYPE_FILE:
    atime = (char *) malloc(20);
    tr_time = localtime(&(tree_node->file.atime));
    strftime (atime, 20, "%F %T", tr_time);

    mtime = (char *) malloc(20);
    tr_time = localtime(&(tree_node->file.mtime));
    strftime (mtime, 20, "%F %T", tr_time);

    call_StartElementHandlerFile(tag, hasChild, tree_node->file.path, 
        tree_node->file.lines, tree_node->file.guarded, 
        tree_node->file.guardId, atime, mtime);
    break;
  case NODE_TYPE_IPATH:
    if (tree_node->common.tokenIndex == INCLUDE_DIRECTORY_INDEX) {
      call_StartElementHandlerIncludePath(tag, hasChild, tree_node->ipath.path, tree_node->common.used_flag);
    } else {
    }
    break;
  default:
    break;
  }
}

/*
 *
 */
void dumpTreeNodeInorder(union treeNode *tree_node) {
  char *tag;

  if (tree_node == 0) {
    return;
  }
  tag = tokenString[tree_node->common.tokenIndex];
  if (tree_debug != 0) {
    fprintf(stderr,"%s(%d,%d,%s);\n",__func__,tree_node->common.nodeType,tree_node->common.tokenIndex,tag);
  }
  switch(tree_node->common.nodeType) {
  case NODE_TYPE_COMMON:
  case NODE_TYPE_IDENTIFIER:
  case NODE_TYPE_MACRO:
  case NODE_TYPE_TEXT:
  case NODE_TYPE_COMMENT:
  case NODE_TYPE_FILE:
    call_EndElementHandler(tag);
    break;
  case NODE_TYPE_ERROR:
  case NODE_TYPE_LOCATION:
    break;
  default:
    break;
  }
}

