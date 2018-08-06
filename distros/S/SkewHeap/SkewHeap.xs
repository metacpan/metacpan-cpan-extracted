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

/*
 * Thanks again, MLEHMANN:
 *   http://grokbase.com/t/perl/perl5-porters/097tr5nw6b/perl-67894-multicall-push-requires-perl-core
 */
#ifndef cxinc
#define cxinc() Perl_cxinc(aTHX)
#endif


typedef struct SkewNode {
  struct SkewNode *left;
  struct SkewNode *right;
  SV *value;
} skewnode_t;

typedef struct SkewHeap {
  skewnode_t *root;
  IV size;
  SV *cmp;
} skewheap_t;


static
skewnode_t* new_node(pTHX_ SV *value) {
  skewnode_t *node;
  Newx(node, 1, skewnode_t);
  node->left  = NULL;
  node->right = NULL;
  node->value = newSVsv(value);
  return node;
}

static
skewnode_t* clone_node(pTHX_ skewnode_t *node) {
  if (node == NULL) {
    return NULL;
  }

  skewnode_t *new_node;

  Newx(new_node, 1, skewnode_t);
  new_node->value = newSVsv(node->value);
  new_node->left  = clone_node(aTHX_ node->left);
  new_node->right = clone_node(aTHX_ node->right);

  return new_node;
}

static
void free_node(pTHX_ skewnode_t *node) {
  if (node->left  != NULL) free_node(aTHX_ node->left);
  if (node->right != NULL) free_node(aTHX_ node->right);
  SvREFCNT_dec(node->value);
  Safefree(node);
}


static
SV* new(pTHX_ const char *class, SV *cmp) {
  skewheap_t *heap;
  SV *obj;
  SV *ref;

  Newx(heap, 1, skewheap_t);
  heap->root = NULL;
  heap->size = 0;
  heap->cmp  = cmp;
  SvREFCNT_inc(heap->cmp);

  obj = newSViv((IV) heap);
  ref = newRV_noinc(obj);
  sv_bless(ref, gv_stashpv(class, GV_ADD));
  SvREADONLY_on(obj);

  return ref;
}

static
void DESTROY(pTHX_ SV *ref) {
  skewheap_t *heap = SKEW(ref);
  if (heap->root != NULL) free_node(aTHX_ heap->root);
  SvREFCNT_dec(heap->cmp);
  Safefree(heap);
}


static
size_t walk_tree(skewnode_t *node, skewnode_t *nodes[], size_t idx) {
  size_t inc = 0;
  nodes[ idx ] = node;
  ++inc;

  if (node->left != NULL) {
    inc += walk_tree(node->left, nodes, idx + inc);
  }

  if (node->right != NULL) {
    inc += walk_tree(node->right, nodes, idx + inc);
  }

  return inc;
}

static
SV* to_array(pTHX_ SV *ref) {
  skewheap_t *heap = SKEW(ref);
  skewnode_t *nodes[ heap->size ];
  AV *array = newAV();
  size_t i;

  walk_tree(heap->root, nodes, 0);

  for (i = 0; i < heap->size; ++i) {
    av_push(array, newSVsv( nodes[i]->value ));
  }

  return newRV_noinc( (SV*) array );
}

static
void sort_nodes(pTHX_ skewnode_t *nodes[], int length, SV *cmp) {
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

  // code value from sv code ref
  CV *cv = sv_2cv(cmp, &stash, &gv, 0);

  if (cv == Nullcv) {
    croak("Not a subroutine reference");
  }

  agv = gv_fetchpv("main::a", GV_ADD, SVt_PV);
  bgv = gv_fetchpv("main::b", GV_ADD, SVt_PV);
  SAVESPTR(GvSV(agv));
  SAVESPTR(GvSV(bgv));

  dMULTICALL;
  I8 gimme = G_SCALAR;

  PUSH_MULTICALL(cv);
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

static
void _merge(pTHX_ SV *heap_ref, SV *heap_ref_a, SV *heap_ref_b) {
  skewheap_t *heap = SKEW(heap_ref);

  skewheap_t *heap_a = SKEW(heap_ref_a);
  skewheap_t *heap_b = SKEW(heap_ref_b);
  skewnode_t *a = heap_a->root;
  skewnode_t *b = heap_b->root;

  size_t size = heap_a->size + heap_b->size;

  skewnode_t *todo[size];
  skewnode_t *nodes[size];
  skewnode_t *node, *prev, *tmp_node;

  int tidx = 0;
  int nidx = 0;
  int i;

  // Set the new heap's size
  heap->size = size;

  // Cut the right subtree from each path
  if (a != NULL) todo[tidx++] = a;
  if (b != NULL) todo[tidx++] = b;

  while (tidx > 0) {
    node = todo[--tidx];

    tmp_node = new_node(aTHX_ node->value);
    tmp_node->left = clone_node(aTHX_ node->left);

    if (node->right != NULL) {
      todo[tidx] = node->right;
      ++tidx;
    }

    nodes[nidx] = tmp_node;
    ++nidx;
  }

  if (nidx > 0) {
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

  return;
}

static
void _merge_destructive(pTHX_ skewheap_t *heap, skewnode_t *a, skewnode_t *b) {
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

static
IV put_one(pTHX_ SV *ref, SV *value) {
  skewheap_t *heap = SKEW(ref);
  skewnode_t *node;

  node = new_node(aTHX_ value);
  ++heap->size;

  if (heap->root == NULL) {
    heap->root = node;
  } else {
    _merge_destructive(aTHX_ heap, heap->root, node);
  }

  return heap->size;
}

static
SV* take(pTHX_ SV *ref) {
  skewheap_t *heap = SKEW(ref);
  skewnode_t *root = heap->root;
  SV *item;

  if (root != NULL) {
    item = newSVsv(root->value);
    --heap->size;
    _merge_destructive(aTHX_ heap, root->left, root->right);
    root->left  = NULL;
    root->right = NULL;
    free_node(aTHX_ root);
  }
  else {
    item = &PL_sv_undef;
  }

  return item;
}

static
SV* top(pTHX_ SV *ref) {
  skewheap_t *heap = SKEW(ref);
  return heap->root == NULL
      ? &PL_sv_undef
      : newSVsv(heap->root->value);
}

static
IV size(pTHX_ SV *ref) {
  skewheap_t *heap = SKEW(ref);
  return heap->size;
}

static
SV* merge(pTHX_ SV *heap_a, SV *heap_b) {
  SV *new_heap = new(aTHX_ "SkewHeap", SKEW(heap_a)->cmp);
  _merge(aTHX_ new_heap, heap_a, heap_b);
  return new_heap;
}

static
void _explain(pTHX_ SV *out, skewnode_t *node, int depth) {
  int i;

  for (i = 0; i < depth; ++i) sv_catpvn(out, "--", 2);
  sv_catpvf(out, "NODE<%p>\n", (void*)node);
  ++depth;

  for (i = 0; i < depth; ++i) sv_catpvn(out, "--", 2);
  sv_catpvf(out, "VALUE<%p>: ", (void*)node->value);
  sv_catsv(out, sv_mortalcopy(node->value));
  sv_catpvn(out, "\n", 1);

  if (node->left != NULL) {
    for (i = 0; i < depth; ++i) sv_catpvn(out, "--", 2);
    sv_catpvn(out, "LEFT:\n", 6);
    _explain(aTHX_ out, node->left, depth + 1);
  }

  if (node->right != NULL) {
    for (i = 0; i < depth; ++i) sv_catpvn(out, "--", 2);
    sv_catpvn(out, "RIGHT:\n", 7);
    _explain(aTHX_ out, node->right, depth + 1);
  }
}

static
SV* explain(pTHX_ SV *ref) {
  skewheap_t *heap = SKEW(ref);
  SV *out = newSVpvn("", 0);

  sv_catpvn(out, "SKEWHEAP:\n", 10);

  if (heap->root != NULL) {
    _explain(aTHX_ out, heap->root, 2);
  }

  return out;
}


MODULE = SkewHeap  PACKAGE = SkewHeap

PROTOTYPES: ENABLE

VERSIONCHECK: ENABLE

SV* new(const char *class, SV *cmp)
  PROTOTYPE: $&
  CODE:
    RETVAL = new(aTHX_ class, cmp);
  OUTPUT:
    RETVAL

SV* skewheap(SV *cmp)
  PROTOTYPE: &
  CODE:
    RETVAL = new(aTHX_ "SkewHeap", cmp);
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

IV put(SV *heap, ...)
  CODE:
    size_t i;
    for (i = 1; i < items; ++i) {
      RETVAL = put_one(aTHX_ heap, ST(i));
    }
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

SV* merge(SV *heap_a, SV *heap_b)
  CODE:
    RETVAL = merge(aTHX_ heap_a, heap_b);
  OUTPUT:
    RETVAL

SV* top(SV *heap)
  CODE:
    RETVAL = top(aTHX_ heap);
  OUTPUT:
    RETVAL

SV* to_array(SV *heap)
  CODE:
    RETVAL = to_array(aTHX_ heap);
  OUTPUT:
    RETVAL

SV* explain(SV *heap)
  CODE:
    RETVAL = explain(aTHX_ heap);
  OUTPUT:
    RETVAL


