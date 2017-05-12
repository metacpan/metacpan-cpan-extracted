/*
 * Routines for include paths.  These are the directories that will be 
 * searched for included files.
 *
 * UUID: fb361a64-ec52-11dc-846c-00502c05c241
 * Author: Brian M. Ames, bames@apk.net
 * Copyright: Copyright (C) 2008 by Brian M. Ames
 */

#include <stdio.h>
#include <stdlib.h>
#include "tree.h"
#include "include_path.h"

struct nodeIncludePath *first_incl_path = NULL;
struct nodeIncludePath *current_incl_path = NULL;

/*
 * Move to the first include path node.
 */
void goto_incl_first() {
  current_incl_path = first_incl_path;
}

/*
 * Return the path attribute of the current include path node.
 */
char *get_incl_path() {
  if (current_incl_path == NULL || current_incl_path->common.nodeType != NODE_TYPE_IPATH) {
    return NULL;
  } else {
    return current_incl_path->path;
  }
}

/*
 * Move to the next include path node.
 */
int goto_incl_next() {
  if (current_incl_path == NULL) {
    return 0;
  }
  for (current_incl_path = (struct nodeIncludePath *) current_incl_path->common.nextSibling;
     current_incl_path != NULL && current_incl_path->common.nodeType != NODE_TYPE_IPATH;
     current_incl_path = (struct nodeIncludePath *) current_incl_path->common.nextSibling);

  if (current_incl_path == NULL) {
    return 0;
  }
  return 1;
}

/*
 * Mark the current include path as used.
 */
void incl_path_used() {
  if (current_incl_path == NULL || current_incl_path->common.nodeType != NODE_TYPE_IPATH) {
  } else {
    current_incl_path->common.used_flag = 1;
  }
}

/*
 * Add an include path to the list.
 */
void add_incl_path(char *p) {
  struct nodeIncludePath *i_path;

  i_path = newNodeIncludePath(INCLUDE_DIRECTORY_INDEX);
  i_path->path = p;

  if (first_incl_path == NULL) {
    first_incl_path = i_path;
    current_incl_path = first_incl_path;
    add(i_path);
  } else {
    add(i_path);
  }
}


