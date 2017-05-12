/*
 * UUID: bb188d3a-e320-11dc-8b9d-00502c05c241
 * Author: Brian M. Ames, bames@apk.net
 * Copyright: Copyright (C) 2008 by Brian M. Ames
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "tree.h"
#include "parser.tab.h"
#include "lexer.h"

/*
 *
 */
#undef DEF_NODE_TYPE
#define DEF_NODE_TYPE(ENUM, NAME) NAME,
char *nodeString[] = {
#include "node.def"
};
#undef DEF_NODE_TYPE

/*
 *
 */
#define DEF_CHARACTER(tag,str,token,type) tag,
#define DEF_KEYWORD(str,token) str,
#define DEF_PP_DIRECTIVE(tag,str,token) tag,
#define DEF_OPERATOR(tag,str,token) tag,
#define DEF_DECLARATOR(tag,str,token) tag,
#define DEF_RULE(tag,token) tag,
#define DEF_MISC(str,token) str,

char *tokenString[] = {
#include "token.def"
};

#undef DEF_CHARACTER
#undef DEF_KEYWORD
#undef DEF_PP_DIRECTIVE
#undef DEF_OPERATOR
#undef DEF_DECLARATOR
#undef DEF_RULE
#undef DEF_MISC

union treeNode *tree_root = 0;

union treeNode *tree_stack[TREE_STACK_SIZE];

int tree_stack_ptr = -1;

extern int tree_debug;

/*
 *
 */
struct nodeCommon *newNodeCommon(enum tokenIndex tokenIndex) {
  struct nodeCommon *node;

  node = (struct nodeCommon *) malloc(sizeof(struct nodeCommon));
  memset(node, 0, sizeof(struct nodeCommon));

  node->nodeType = NODE_TYPE_COMMON;
  node->tokenIndex = tokenIndex;

  return node;
}

/*
 *
 */
struct nodeIdentifier *newNodeIdentifier(enum tokenIndex tokenIndex) {
  struct nodeIdentifier *node;

  node = (struct nodeIdentifier *) malloc(sizeof(struct nodeIdentifier));
  memset(node, 0, sizeof(struct nodeIdentifier));

  node->common.nodeType = NODE_TYPE_IDENTIFIER;
  node->common.tokenIndex = tokenIndex;
  node->common.replaceable_flag = 1;

  return node;
}

/*
 *
 */
struct nodeMacro *newNodeMacro(enum tokenIndex tokenIndex) {
  struct nodeMacro *node;

  node = (struct nodeMacro *) malloc(sizeof(struct nodeMacro));
  memset(node, 0, sizeof(struct nodeMacro));

  node->common.nodeType = NODE_TYPE_MACRO;
  node->common.tokenIndex = tokenIndex;

  return node;
}

/*
 *
 */
struct nodeText *newNodeText(enum tokenIndex tokenIndex) {
  struct nodeText *node;

  node = (struct nodeText *) malloc(sizeof(struct nodeText));
  memset(node, 0, sizeof(struct nodeText));

  node->common.nodeType = NODE_TYPE_TEXT;
  node->common.tokenIndex = tokenIndex;

  return node;
}

/*
 *
 */
struct nodeComment *newNodeComment(enum tokenIndex tokenIndex) {
  struct nodeComment *node;

  node = (struct nodeComment *) malloc(sizeof(struct nodeComment));
  memset(node, 0, sizeof(struct nodeComment));

  node->common.nodeType = NODE_TYPE_COMMENT;
  node->common.tokenIndex = tokenIndex;

  return node;
}

/*
 *
 */
struct nodeError *newNodeError(enum tokenIndex tokenIndex) {
  struct nodeError *node;

  node = (struct nodeError *) malloc(sizeof(struct nodeError));
  memset(node, 0, sizeof(struct nodeError));

  node->common.nodeType = NODE_TYPE_ERROR;
  node->common.tokenIndex = tokenIndex;

  return node;
}

/*
 *
 */
struct nodeLocation *newNodeLocation() {
  struct nodeLocation *node;

  node = (struct nodeLocation *) malloc(sizeof(struct nodeLocation));
  memset(node, 0, sizeof(struct nodeLocation));

  node->common.nodeType = NODE_TYPE_LOCATION;
  node->common.tokenIndex = LOCATION_INDEX;

  return node;
}

/*
 *
 */
struct nodeFile *newNodeFile(enum tokenIndex tokenIndex) {
  struct nodeFile *node;

  node = (struct nodeFile *) malloc(sizeof(struct nodeFile));
  memset(node, 0, sizeof(struct nodeFile));

  node->common.nodeType = NODE_TYPE_FILE;
  node->common.tokenIndex = tokenIndex;

  return node;
}

/*
 *
 */
struct nodeIncludePath *newNodeIncludePath(enum tokenIndex tokenIndex) {
  struct nodeIncludePath *node;

  node = (struct nodeIncludePath *) malloc(sizeof(struct nodeIncludePath));
  memset(node, 0, sizeof(struct nodeIncludePath));

  node->common.nodeType = NODE_TYPE_IPATH;
  node->common.tokenIndex = INCLUDE_DIRECTORY_INDEX;

  return node;
}

/*
 *
 */
void add(void *treeNode) {
  struct nodeCommon *tree_node;

  struct nodeCommon *parent;
  if (tree_debug != 0) {
    fprintf(stderr,"%s %d\n",__func__,tree_stack_ptr);
  }

  tree_node = (struct nodeCommon *) treeNode;
  if ((tree_node->nodeType == NODE_TYPE_LOCATION && tree_node->tokenIndex != LOCATION_INDEX ) 
   || (tree_node->nodeType == NODE_TYPE_IPATH    && tree_node->tokenIndex != INCLUDE_DIRECTORY_INDEX )) {
   fprintf(stderr,"%s: Invalid tree node (%d,%d)\n",__func__,tree_node->nodeType,tree_node->tokenIndex);
   return;
  }

  if(tree_stack_ptr == 0) {
    parent = (struct nodeCommon *) tree_root;
  } else {
    parent = (struct nodeCommon *) tree_stack[tree_stack_ptr-1];
  }
  if (parent->firstChild == 0) {
    parent->firstChild = treeNode;
  } else {
    tree_stack[tree_stack_ptr]->common.nextSibling = treeNode;
  }
  tree_stack[tree_stack_ptr] = treeNode;

}

/*
 *
 */
void push(void *treeNode) {
  struct nodeCommon *tree_node;

  if (tree_debug != 0) {
    printf("%s %d\n",__func__,tree_stack_ptr);
  }
  
  tree_node = (struct nodeCommon *) treeNode;
  if ((tree_node->nodeType == NODE_TYPE_LOCATION && tree_node->tokenIndex != LOCATION_INDEX ) 
   || (tree_node->nodeType == NODE_TYPE_IPATH    && tree_node->tokenIndex != INCLUDE_DIRECTORY_INDEX )) {
   fprintf(stderr,"%s: Invalid tree node (%d,%d)\n",__func__,tree_node->nodeType,tree_node->tokenIndex);
   return;
  }

  if (tree_stack_ptr < 0 ) {
    tree_root = treeNode;
  } else {
    add(treeNode);
  }
  tree_stack[++tree_stack_ptr] = NULL;
}

/*
 *
 */
union treeNode *pop() {
  union treeNode *node;
  if (tree_debug != 0) {
    printf("%s %d\n",__func__,tree_stack_ptr);
  }
  if(tree_stack_ptr <= 0) {
    node =  tree_root;
    tree_stack_ptr = -1;
  } else {
    node = tree_stack[--tree_stack_ptr];
  }
//    printf("%s %d\n",__func__,tree_stack_ptr);
  return node;
}

/*
 *
 */
union treeNode *getCurrent() {
  union treeNode *node;
  if (tree_debug != 0) {
    printf("%s %d\n",__func__,tree_stack_ptr);
  }
  if(tree_stack_ptr < 0) {
    node =  tree_root;
  } else {
/*    if(tree_stack[tree_stack_ptr] == NULL) {
      if(tree_stack_ptr == 0) {
        node =  tree_root;
      } else {
        node = tree_stack[tree_stack_ptr-1];
      }
    } else { */
      node = tree_stack[tree_stack_ptr];
//    }
  }
  return node;
}

/*
 *
 */
union treeNode *getParent() {
  union treeNode *node;
  int pptr;

  if (tree_debug != 0) {
    printf("%s %d\n",__func__,tree_stack_ptr);
  }
  pptr = tree_stack_ptr - 1;
  node = NULL;
  if(pptr == -1) {
    node = tree_root;
  } else {
/*
    if(tree_stack[pptr] == NULL) {
      if(pptr == 0) {
        node =  tree_root;
      } else {
        node = tree_stack[pptr-1];
      }
    } else { */
      node = tree_stack[pptr];
//    }
  }
  return node;
}

