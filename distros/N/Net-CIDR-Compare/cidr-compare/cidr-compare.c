/*
 * CIDR block calculator.
 *
 * Takes a set of dotted-quad IP addresses, ranges, or CIDR blocks, on
 *  stdin; at EOF, prints a minimal set of CIDR ranges to stdout.
 *
 * Input consists of a stream of dotted-quads, pairs of dotted-quads
 *  separated by a dash, or dotted-quads with /number widths after
 *  them.  Dash-separated ranges refer to all addresses between the
 *  two, inclusive; an address with a /number after it refers to a
 *  CIDR-style block.  It is not an error for an address to be
 *  specified in the input more than once.  Whitespace may appear
 *  anywhere except within a dotted-quad or CIDR width.  Characters
 *  other than digits, dots, dashes, and whitespace are errors.  If a
 *  number in a dotted-quad is greater than 255, or a CIDR width is
 *  greater than 32, or other syntax errors occur (such as too many
 *  dots without whitespace, dash, or slash) a complaint is printed and
 *  the dotted-quad, range, or block in which it appears is skipped.
 *
 * Output consists of zero or more lines, each a dotted-quad/width CIDR
 *  net-with-mask, including all and only the addresses in the input.
 *  It will be a minimal set, in that no two blocks in the output can
 *  be collapsed without resorting to noncontiguous netmasks.
 *
 * This file is in the public domain.
 */

#include <stdio.h>
#include <stdlib.h>
#include "./cidr-compare.h"

/*
 * We store the input as a binary tree.  Conceptually, the tree is a
 *  fully-populated depth-32 binary tree, with each leaf marked as
 *  either present or absent in the input.  Of course, that's a totally
 *  impractical representation.  What we actually do is to store that
 *  tree, but whenever a subtree has all its leaves absent, the pointer
 *  that would normally point to it is replaced with a NONE pointer; if
 *  a subtree has all its leaves present, an ALL pointer.  (Leaf
 *  pointers are always either NONE or ALL, according as the leaf in
 *  question is absent or present.)
 *
 * This could probably be stored more efficiently by allowing a single
 *  C structure to represent multiple levels in the tree when there's
 *  only one non-NONE path down through those levels, but the
 *  additional code complexity isn't worth it.
 *
 * Since we don't have to store "up" pointers, we don't, and a node
 *  consists of nothing but two child pointers.  We use an array[2]
 *  rather than two separate struct elements because at one place it's
 *  convenient to use a computed index, which would otherwise need to
 *  be a ? : expression.
 *
 * The reason for choosing this data structure is that it makes
 *  extracting CIDR netblocks - our desired output - trivial.  All we
 *  have to do is collapse every node with two ALL children into an ALL
 *  node itself; when this process can go no farther, an optimal CIDR
 *  set consists of the address/mask values corresponding to the ALL
 *  nodes.  (We actually do the collapsing as we build the tree, rather
 *  than deferring it until everything's done.)
 *
 * We could use a nil pointer for NONE or ALL, but don't, if only for
 *  error checking.
 */

struct node {
  NODE *sub[2];
};

struct list {
  LIST *next;
  NODE *root;
};

struct iplist {
  IPLIST *next;
  char *cidr_range;
};

struct init {
  LIST *lists;
  LIST *first_list;
  int num_lists;
  IPLIST *iplist;
  IPLIST *first_iplist;
  IPLIST *current_iplist;
  char *last_cidr_range;
  int num_iplists;
};


/*
 * The NONE and ALL pointers.  I know of no portable way of generating
 *  distinctive NODE * values without actually allocating NODEs for
 *  them to point to, except for the nil pointer.  Fortunately, NODEs
 *  are small enough that statically allocating two isn't a big deal.
 */
NODE none;
#define NONE (&none)
NODE all;
#define ALL (&all)
LIST last;
#define LAST (&last)
IPLIST ipdone;
#define IPDONE (&ipdone)
char *LAST_CIDR_RANGE;
static char empty[0];

/*
 * Free a node and all nodes under it.  Useful when we're setting ALL
 *  at a point relatively far up in the tree (which happens if a range
 *  or block subsumes some already-entered individual addresses).
 */
void free_tree(NODE *n)
{
 if ((n == NONE) || (n == ALL)) return;
 free_tree(n->sub[0]);
 free_tree(n->sub[1]);
 free(n);
}

/*
 * Add an address to a node.  Conceptually, you pass a node to this
 *  routine.  But since it may want to replace the node with ALL, it
 *  needs to actually be passed an additional level of pointer, NODE **
 *  instead of NODE *.  This has the convenient property that this
 *  routine can also handle replacing NONE nodes with real nodes.  a is
 *  the address being added.  bit says how far down in the tree this
 *  node is, or more accurately how far up; 31 corresponds to the root,
 *  0 to the last level of internal nodes, and -1 to leaves.  end is a
 *  value which describes how large a block is being added; it is -1 to
 *  add a single leaf (a /32), 0 to add a pair of addresses (a /31),
 *  etc.
 *
 * Algorithm: Recursive.  If the node is already ALL, everything we
 *  want to add is already present, so do nothing.  Otherwise, if we've
 *  reached the level at which we want to operate (bit <= end), free
 *  the subtree if it's not NONE (it can't be ALL; we already checked)
 *  and replace it with ALL, and we're done.  Otherwise, we have to
 *  walk down either the 0 link or the 1 link.  If this node is
 *  presently NONE, we have to create a real node; then we recurse down
 *  whichever branch of the tree corresponds to the appropriate bit of
 *  a.  After adding, we check, and if both our subtrees are ALL, we
 *  collapse this node into an ALL.  (If further collapsing is possible
 *  at the next level up, our caller will take care of it.)
 */
void add_to_node(LIST *list, NODE **np, unsigned long int a, int bit, int end)
{
  NODE *n;

  n = *np;
  if (n == ALL) return;
  if (bit <= end)
  { 
    if (n != NONE) free_tree(n);
    *np = ALL;
    return;
  }
  if (n == NONE)
  { 
    n = malloc(sizeof(NODE));
    n->sub[0] = NONE;
    n->sub[1] = NONE;
    *np = n;
    if (list->root == NONE) {
      list->root = n;
    }
  }
  add_to_node(list,&n->sub[(a>>bit)&1],a,bit-1,end);
  if ((n->sub[0] == ALL) && (n->sub[1] == ALL))
  {
    free(n);
    *np = ALL;
  }
}

/*
 * Dump output.  This dumps out whatever output is appropriate for a
 *  given NODE.  If the node is NONE, there's nothing under it, so
 *  don't do anything.  If it's ALL, we've found a CIDR block; print it
 *  and return.  Otherwise, we recurse, first down the 0 branch, then
 *  the 1 branch.  v is the address-so-far, maintained as part of the
 *  recursive calls.
 *
 * The abort() is a can't-happen; it indicates that we have a node
 *  that's not NONE or ALL at the bottom level of the tree, which is
 *  supposed to hold only leaves.
 */
void dump_tree(NODE *n, unsigned long int v, int bit)
{
  if (n == NONE) return;
  if (n == ALL)
  { 
    printf("%lu.%lu.%lu.%lu/%d\n",v>>24,(v>>16)&0xff,(v>>8)&0xff,v&0xff,31-bit);
    return;
  }
  if (bit < 0) abort();
  dump_tree(n->sub[0],v,bit-1);
  dump_tree(n->sub[1],v|(1<<bit),bit-1);
}

void dump_intersection (INIT *init, LIST *ilists, unsigned long int v, int bit)
{
    int all_count = 0;

    LIST *s;
    int free_ilists = 0;
    for (s = ilists; s != LAST; s = s->next) {
      if (s->root == NONE) {
        free_ilists = 1;
        break;
      }

      if (s->root == ALL) {
        all_count++;
      }
    }
    if (free_ilists) {
      LIST *current = ilists;
      LIST *next = LAST;
      while (current != LAST) {
        next = current->next;
        current = next;
      }
      return;
    }

    if (all_count == init->num_lists) {
      IPLIST *new_iplist = malloc(sizeof(IPLIST));
      new_iplist->cidr_range = malloc(25);
      sprintf(new_iplist->cidr_range,"%lu.%lu.%lu.%lu/%d\0",v>>24,(v>>16)&0xff,(v>>8)&0xff,v&0xff,31-bit);
      if (init->first_iplist == IPDONE) {
        init->first_iplist = new_iplist;
        init->current_iplist = new_iplist;
      }
      if (init->iplist == IPDONE) {
        init->iplist = new_iplist;
      }
      else {
        init->iplist->next = new_iplist;
        init->iplist = new_iplist;
      }
      init->iplist->next = IPDONE;
      init->num_iplists++;

      LIST *current = ilists;
      LIST *next = LAST;
      while (current != LAST) {
        next = current->next;
        current = next;
      }
      return;
    }

    if (bit < 0) {
      LIST *current = ilists;
      LIST *next = LAST;
      while (current != LAST) {
        next = current->next;
        current = next;
      }
      abort();
    }

    LIST *next_left_ilists_start;
    LIST *next_right_ilists_start;
    LIST *prev_left_ilists;
    LIST *prev_right_ilists;

    for (s = ilists; s != LAST; s = s->next) {
      LIST *new_next_left_ilists = malloc(sizeof(LIST));
      LIST *new_next_right_ilists = malloc(sizeof(LIST));
      new_next_left_ilists->next = LAST;
      new_next_right_ilists->next = LAST;

      if (s->root == ALL) {
        new_next_left_ilists->root = ALL;
        new_next_right_ilists->root = ALL;
      }
      else {
        new_next_left_ilists->root = s->root->sub[0];
        new_next_right_ilists->root = s->root->sub[1];
      }

      if (s == ilists) { // first iteration
        next_left_ilists_start = new_next_left_ilists;
        next_right_ilists_start = new_next_right_ilists;
      }
      else {
        prev_left_ilists->next = new_next_left_ilists;
        prev_right_ilists->next = new_next_right_ilists;
      }
      prev_left_ilists = new_next_left_ilists;
      prev_right_ilists = new_next_right_ilists;
    }
   
    dump_intersection(init, next_left_ilists_start, v, bit-1);
    dump_intersection(init, next_right_ilists_start, v|(1<<bit), bit-1);
    LIST *current = next_left_ilists_start;
    LIST *next = LAST;
    while (current != LAST) {
      next = current->next;
      free(current);
      current = next;
    }
    current = next_right_ilists_start;
    while (current != LAST) {
      next = current->next;
      free(current);
      current = next;
    }
}

char * dump_next_intersection_output (INIT *init) {
  if (init->current_iplist != IPDONE) {
    char *cidr_range = init->current_iplist->cidr_range;
    IPLIST *next = init->current_iplist->next;
    free(init->current_iplist);
    init->current_iplist = next;
    free(init->last_cidr_range);
    init->last_cidr_range = cidr_range;
    return cidr_range;
  }
  if (init->current_iplist == IPDONE && init->last_cidr_range != LAST_CIDR_RANGE) {
    free(init->last_cidr_range);
    init->last_cidr_range = LAST_CIDR_RANGE;
  }
  return empty;
}

IPLIST * dump_intersection_output(INIT *init)
{
  LIST *first_list = malloc(sizeof(LIST));
  first_list->root = init->first_list->root;
  first_list->next = init->first_list->next;
  init->iplist = IPDONE;
  init->first_iplist = IPDONE;
  init->current_iplist = IPDONE;
  init->num_iplists = 0;
  init->last_cidr_range = LAST_CIDR_RANGE;
  dump_intersection(init, first_list, 0, 31);
  free(first_list);
  return init->first_iplist;
}

/*
 * Add one address.  Used when the input contains an unadorned
 *  dotted-quad.  All we need do is call add_to_node appropriately.
 */
void save_one_addr(LIST *list, unsigned long int a)
{
  add_to_node(list,&(list->root),a,31,-1);
}

/*
 * Add a range of addresses.  This is used for the
 *  "10.20.30.40 - 10.20.32.77" style of input.  All we do is start at
 *  the bottom of the range and loop, each time computing the largest
 *  block that doesn't go below the bottom, shrinking it as far as
 *  necessary to ensure it doesn't go above the top, adding it, and
 *  moving the `bottom' value to just above the block.  Lather, rinse,
 *  repeat...until the whole range is covered.
 */
void save_range(LIST *list, unsigned long int a1, unsigned long int a2)
{
 int bit;
 unsigned long int m;
 unsigned long int t;

 if (a1 > a2)
  { fprintf(stderr,"invalid range (ends reversed)\n");
    return;
  }
 while (a1 <= a2)
  { m = (a1 - 1) & ~a1;
    while (a1+m > a2) m >>= 1;
    for (bit=-1,t=m;t;bit++,t>>=1) ;
    add_to_node(list,&(list->root),a1,31,bit);
    a1 += m+1;
  }
}

/*
 * Add a CIDR-style block.  This matches our storage method so well
 *  it's just a single call to add_to_node.  The reason for the ?:
 *  operator is that C doesn't promise that << by 32 actually shifts;
 *  32-bit machines often use only the low five bits of the shift
 *  count.
 */
void save_cidr(LIST *list, unsigned long int a, int n)
{
 add_to_node(list,&(list->root),n?a&0xffffffff&(0xffffffff<<(32-n)):0,31,31-n);
}

/*
* Read input.  Implementation is a simple state machine.
*
* State values for the various input syntaxes (a=10, b=11, etc):
*
* input     1 2 3 . 4 5 . 6 7 . 8 9       1 2 3 . 4 5 ...
* state  1 1 2 2 2 3 4 4 5 6 6 7 8 8 9 9 9 2 2 2 3 4 4 ...
*
* input     1 2 3 . 4 5 . 6 7 . 8 9   -   1 1 . 2 2 . 3 3 . 4 4     ...
* state  1 1 2 2 2 3 4 4 5 6 6 7 8 8 9 a a b b c d d e f f g h h 1 1 ...
*
* input     1 2 3 . 4 5 . 6 7 . 8 9   /   1 5     ...
* state  1 1 2 2 2 3 4 4 5 6 6 7 8 8 9 i i j j 1 1 ...
*
* a holds the address being constructed (or, for states 9, i, j, the
*  address just constructed); n holds the number being accumulated.
*  a1 is used to hold the first address when a range is being read
*  (the second address is accumulated into a).
*
* If an error occurs, n is set to -1, and further errors are
*  suppressed; we stay this way until we begin a new dotted-quad, by
*  entering state 2 from state 9 or by entering state 1 upon seeing
*  whitespace in most other states.
*
* The "default: abort();" cases are can't-happen firewalls.
*/

void read_input(LIST *list, FILE *read_fh)
{
 unsigned long int a1;
 unsigned long int a;
 int line;
 int n;
 int c;
 int state;

 state = 1;
 line = 1;
 n = 0;
 while (1)
  { c = fgetc(read_fh);
    if (c == EOF) break;
    switch (c)
     { case '0': case '1': case '2': case '3': case '4':
       case '5': case '6': case '7': case '8': case '9':
          switch (state)
           { default:
                abort();
                break;
             case 1:
                n = c - '0';
                state = 2;
                break;
             case 3:
             case 5:
             case 7:
             case 12:
             case 14:
             case 16:
                state ++;
             case 2:
             case 4:
             case 6:
             case 8:
             case 11:
             case 13:
             case 15:
             case 17:
                if (n < 0) break;
                n = (n * 10) + (c - '0');
                if (n > 255)
                 { fprintf(stderr,"line %d: out-of-range number in input\n",line);
                   n = -1;
                 }
                break;
             case 9:
                if (n >= 0)
                 { save_one_addr(list, a);
                   n = c - '0';
                 }
                state = 2;
                break;
             case 10:
             case 18:
                if (n >= 0) n = c - '0';
                state ++;
                break;
             case 19:
                if (n < 0) break;
                n = (n * 10) + (c - '0');
                if (n > 32)
                 { fprintf(stderr,"line %d: out-of-range width in input\n",line);
                   n = -1;
                 }
                break;
           }
          break;
       case '.':
          switch (state)
           { default:
                abort();
                break;
             case 1:
             case 3:
             case 5:
             case 7 ... 8:
             case 10:
             case 12:
             case 14:
             case 16 ... 19:
                if (n >= 0) fprintf(stderr,"line %d: . at an inappropriate place\n",line);
                n = -1;
                break;
             case 2:
             case 11:
                a = 0;
             case 4:
             case 6:
             case 13:
             case 15:
                if (n >= 0)
                 { a = (a << 8) | n;
                   n = 0;
                 }
                state ++;
                break;
             case 9:
                if (n >= 0)
                 { save_one_addr(list, a);
                   fprintf(stderr,"line %d: . at an inappropriate place\n",line);
                 }
                n = -1;
                break;
           }
          break;
       case '-':
          switch (state)
           { default:
                abort();
                break;
             case 1 ... 7:
             case 10 ... 19:
                fprintf(stderr,"line %d: - at an inappropriate place\n",line);
                n = -1;
                break;
             case 8:
                if (n >= 0) a1 = (a << 8) | n;
                state = 10;
                break;
             case 9:
                a1 = a;
                state = 10;
                break;
           }
          break;
       case '/':
          switch (state)
           { default:
                abort();
                break;
             case 1 ... 7:
             case 10 ... 19:
                fprintf(stderr,"line %d: / at an inappropriate place\n",line);
                n = -1;
                break;
             case 8:
                if (n >= 0) a = (a << 8) | n;
                state = 18;
                break;
             case 9:
                state = 18;
                break;
           }
          break;
       case '\n':
          line ++;
       case ' ': case '\t': case '\r':
          switch (state)
           { default:
                abort();
                break;
             case 1:
             case 9 ... 10:
             case 18:
                break;
             case 2 ... 7:
             case 11 ... 16:
                if (n >= 0) fprintf(stderr,"line %d: whitespace at an inappropriate place\n",line);
                state = 1;
                break;
             case 8:
                if (n >= 0) a = (a << 8) | n;
                state = 9;
                break;
             case 17:
                if (n >= 0) save_range(list, a1, (a<<8)|n);
                state = 1;
                break;
             case 19:
                if (n >= 0) save_cidr(list, a, n);
                state = 1;
                break;
           }
          break;
       default:
          fprintf(stderr,"invalid character 0x%02x in input\n",c);
          n = -1;
          state = 2;
          break;
     }
  }
 switch (state)
  { default:
       abort();
       break;
    case 1:
       break;
    case 2 ... 7:
    case 10 ... 16:
       if (n >= 0) fprintf(stderr,"line %d: EOF at an inappropriate place\n",line);
       break;
    case 8:
       if (n >= 0) save_one_addr(list, (a<<8)|n);
       break;
    case 9:
       if (n >= 0) save_one_addr(list, a);
       break;
    case 17:
       if (n >= 0) save_range(list, a1, (a<<8)|n);
       break;
  }
}

/*
 * After accumulating all input, dump out the resulting CIDR blocks.
 *  Because we collapse when possible during tree construction, there
 *  is nothing to do here but call dump_tree to walk the tree and print
 *  a line when it finds an ALL node.
 */
void dump_output(LIST *list)
{
  dump_tree(list->root,0,31);
}

void dump_all_lists (INIT *init)
{
  if (init->first_list != NULL)
  {
    LIST *a = init->first_list;
    while (1)
    {
      dump_output(a);
      if (a->next == LAST) {
        break;
      }
      a = a->next;
    }
  }
}

void free_list (LIST *list) {
  if (list != LAST && list != NULL) {
    free_tree(list->root);
    free(list);
  }
}

void delete_list (INIT *init, LIST *list)
{
  if (init->first_list != NULL)
  {
    if (list == init->first_list) {
      if (init->first_list->next != LAST) {
        init->first_list = init->first_list->next;
      }
      else {
        init->first_list = NULL;
      }
      init->num_lists--;
      free_list(list);
      return;
    }
    LIST *a = init->first_list;
    while (1)
    {
      LIST *prev = a;
      a = a->next;
      if (a == list) {
        init->num_lists--;
        if (a->next == LAST) {
          prev->next = LAST;
        }
        else {
          prev->next = a->next;
        }
        init->lists = prev;
        free_list(list);
        return;
      }
      if (a->next == LAST) {
        return;
      }
    }
  }
}

INIT * start_new (void)
{
  INIT *x = malloc(sizeof(INIT));
  x->num_lists = 0;
  x->first_list = NULL;
  x->iplist = IPDONE;
  x->first_iplist = IPDONE;
  x->current_iplist = IPDONE;
  x->num_iplists = 0;
  x->last_cidr_range = LAST_CIDR_RANGE;
  return x;
}

LIST * setup_new_list (INIT *init)
{
  if (init->num_lists >= 1) {
    LIST *a = malloc(sizeof(LIST));
    a->root = NONE;
    init->lists->next = a;
    init->lists = a;
    init->num_lists++;
  }
  else {
    init->num_lists = 1;
    init->lists = malloc(sizeof(LIST));
    init->lists->root = NONE;
    init->first_list = init->lists;
  }
  init->lists->next = LAST;
  return init->lists;
}
