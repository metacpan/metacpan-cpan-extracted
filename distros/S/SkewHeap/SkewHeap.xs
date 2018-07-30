#define PERL_NO_GET_CONTEXT

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"

/*
 * Allocate memory with Newx if it's
 * available - if it's an older perl
 * that doesn't have Newx then we
 * resort to using New.
 */
#ifndef Newx
#define Newx(v, n, t) New(0, v, n, t)
#endif

/*
 * perl object ref to skewheap_t*
 */
#ifndef SKEW
#define SKEW(obj) ((skewheap_t*) SvIV(SvRV(obj)))
#endif

typedef struct SkewNode {
  struct SkewNode *left;
  struct SkewNode *right;
  SV *value;
} skewnode_t;

typedef struct SkewHeap {
  skewnode_t *root;
  IV size;
  CV *cmp;
} skewheap_t;

skewnode_t* new_node(pTHX_ SV *value) {
  skewnode_t *node;
  Newx(node, 1, skewnode_t);
  node->left  = NULL;
  node->right = NULL;
  node->value = value;
  SvREFCNT_inc(value);
  return node;
}

void free_node(pTHX_ skewnode_t *node) {
  if (node->left != NULL)  free_node(aTHX_ node->left);
  if (node->right != NULL) free_node(aTHX_ node->right);
  Safefree(node);
}

SV* new(pTHX_ const char *class, CV *cmp) {
  skewheap_t *heap;
  SV *obj;
  SV *ref;

  Newx(heap, 1, skewheap_t);
  heap->root = NULL;
  heap->size = 0;
  heap->cmp  = cmp;

  obj = newSViv((IV) heap);
  ref = newRV_noinc(obj);
  sv_bless(ref, gv_stashpv(class, GV_ADD));
  SvREADONLY_on(obj);

  return ref;
}

void DESTROY(pTHX_ SV *ref) {
  skewheap_t *heap = SKEW(ref);
  if (heap->root != NULL) free_node(aTHX_ heap->root);
  Safefree(heap);
}

void sort_nodes(pTHX_ skewnode_t *nodes[], int length, CV *cmp) {
  skewnode_t *tmp, *x;
  int p, j;
  int start = 0;
  int end = length - 1;
  int top = 1;
  int stack[end - start + 1];

  stack[0] = start;
  stack[1] = end;

  // set up multicall
  dSP;
  GV *agv, *bgv, *gv;
  HV *stash;

  agv = gv_fetchpv("main::a", GV_ADD, SVt_PV);
  bgv = gv_fetchpv("main::b", GV_ADD, SVt_PV);
  SAVESPTR(GvSV(agv));
  SAVESPTR(GvSV(bgv));

  dMULTICALL;
  I8 gimme = G_SCALAR;

  PUSH_MULTICALL(cmp);
  // multicall ready

  while (top >= 0) {
    end   = stack[top--];
    start = stack[top--];

    x = nodes[end];
    p = start - 1;

    for (j = start; j <= end - 1; ++j) {
      GvSV(agv) = nodes[j]->value;
      GvSV(bgv) = x->value;
      MULTICALL;

      int test = SvIV(*PL_stack_sp);

      if (test < 1) {
        p++;
        tmp = nodes[p];
        nodes[p] = nodes[j];
        nodes[j] = tmp;
      }
    }

    tmp = nodes[++p];
    nodes[p] = nodes[end];
    nodes[end] = tmp;

    if (p - 1 > start) {
      stack[++top] = start;
      stack[++top] = p - 1;
    }

    if (p + 1 < end) {
      stack[++top] = p + 1;
      stack[++top] = end;
    }
  }

  POP_MULTICALL;
}

void _merge(pTHX_ skewheap_t *heap, skewnode_t *a, skewnode_t *b) {
  skewnode_t* todo[heap->size];
  skewnode_t* nodes[heap->size];
  skewnode_t* node;
  skewnode_t* prev;
  int tidx = 0;
  int nidx = 0;
  int i;

  if (a == NULL) {
    heap->root = b;
    return;
  }
  else if (b == NULL) {
    heap->root = a;
    return;
  }

  // Cut the right subtree from each path
  todo[tidx++] = a;
  todo[tidx++] = b;

  while (tidx > 0) {
    node = todo[--tidx];

    if (node->right != NULL) {
      todo[tidx++] = node->right;
      node->right = NULL;
    }

    nodes[nidx++] = node;
  }

  if (nidx == 0) {
    heap->root = NULL;
  }
  else {
    // Sort the subtrees
    if (nidx > 1) {
      sort_nodes(aTHX_ nodes, nidx, heap->cmp);
    }

    // Recombine subtrees
    for (i = nidx; i > 1; --i) {
      node = nodes[i - 1]; // last node
      prev = nodes[i - 2]; // second to last node

      // Set penultimate node's right child to its left (and only) subtree
      if (prev->left != NULL) {
        prev->right = prev->left;
      }

      // Set its left child to the ultimate node
      prev->left = node;
    }

    heap->root = nodes[0];
  }
}

IV put_one(pTHX_ SV *ref, SV *value) {
  skewheap_t *heap = SKEW(ref);
  skewnode_t *node;

  node = new_node(aTHX_ value);
  ++heap->size;

  if (heap->root == NULL) {
    heap->root = node;
  } else {
    _merge(aTHX_ heap, heap->root, node);
  }

  return heap->size;
}

SV* take(pTHX_ SV *ref) {
  skewheap_t *heap = SKEW(ref);
  skewnode_t *root = heap->root;
  SV *item;

  if (root != NULL) {
    item = root->value;
    --heap->size;
    _merge(aTHX_ heap, root->left, root->right);
    root->left  = NULL;
    root->right = NULL;
    free_node(aTHX_ root);
  }
  else {
    item = &PL_sv_undef;
  }

  return item;
}

SV* top(pTHX_ SV *ref) {
  skewheap_t *heap = SKEW(ref);
  return heap->root == NULL
      ? &PL_sv_undef
      : newSVsv(heap->root->value);
}

IV size(pTHX_ SV *ref) {
  skewheap_t *heap = SKEW(ref);
  return heap->size;
}

IV merge(pTHX_ SV *heap_a, SV *heap_b) {
  skewheap_t *a = SKEW(heap_a);
  skewheap_t *b = SKEW(heap_b);

  if (a->root == NULL) {
    a->root = b->root;
  } else if (b->root != NULL) {
    _merge(aTHX_ a, a->root, b->root);
  }

  a->size += b->size;
  b->size = 0;
  b->root = NULL;

  return a->size;
}


MODULE = SkewHeap  PACKAGE = SkewHeap

PROTOTYPES: DISABLE

VERSIONCHECK: ENABLE

SV* new(const char *class, CV *cmp)
  CODE:
    RETVAL = new(aTHX_ class, cmp);
  OUTPUT:
    RETVAL

void DESTROY(SV *heap)
  CODE:
    DESTROY(aTHX_ heap);

IV put_one(SV *heap, SV *value)
  CODE:
    RETVAL = put_one(aTHX_ heap, value);
  OUTPUT:
    RETVAL

SV* take(SV *heap)
  CODE:
    RETVAL = take(aTHX_ heap);
  OUTPUT:
    RETVAL

IV size(SV *heap)
  CODE:
    RETVAL = size(aTHX_ heap);
  OUTPUT:
    RETVAL

IV merge(SV *heap_a, SV *heap_b)
  CODE:
    RETVAL = merge(aTHX_ heap_a, heap_b);
  OUTPUT:
    RETVAL

SV* top(SV *heap)
  CODE:
    RETVAL = top(aTHX_ heap);
  OUTPUT:
    RETVAL

