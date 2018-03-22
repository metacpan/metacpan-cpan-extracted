package SkewHeap;
# ABSTRACT: A fast heap structure for Perl
$SkewHeap::VERSION = '0.02';
use strict;
use warnings;
use Inline C => 'DATA', optimize => '-O2';

1;

=pod

=encoding UTF-8

=head1 NAME

SkewHeap - A fast heap structure for Perl

=head1 VERSION

version 0.02

=head1 SYNOPSIS

  use SkewHeap;

  my $heap = SkewHeap->new(sub{ $a <=> $b });
  $heap->put(42);
  $heap->put(35);
  $heap->put(200, 62);

  $heap->top;  # 35
  $heap->size; # 4

  $heap->take; # 35
  $heap->take; # 42
  $heap->take; # 62
  $heap->take; # 200

  $heap->merge($other_skewheap);

=head1 DESCRIPTION

A skew heap is a memory efficient, self-adjusting heap (or priority queue) with
an amortized performance of O(log n) (or better). C<SkewHeap> is implemented in
C (using L<Inline::C>).

The key feature of a skew heap is the ability to quickly and efficiently merge
two heaps together.

=head1 METHODS

=head2 new

Creates a new C<SkewHeap> which will be sorted in ascending order using the
comparison subroutine passed in. This sub has the same semantics as Perl's
C<sort>, returning -1 if C<$a < $b>, 1 if C<$a > $b>, or 0 if C<$a == $b>.

=head2 size

Returns the number of elements in the heap.

=head2 top

Returns the next element which would be returned by L</take> without removing
it from the heap.

=head2 put

Inserts one or more new elements into the heap.

=head2 take

Removes and returns the next element from the heap.

=head2 merge

Destructively merges another heap into itself. After calling merge, the second
heap is empty and the first holds all elements from both heaps.

=head1 AUTHOR

Jeff Ober <sysread@fastmail.fm>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Jeff Ober.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__DATA__

__C__

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
  SV *cmp;
} skewheap_t;

skewnode_t* new_node(SV *value) {
  skewnode_t *node;
  Newx(node, 1, skewnode_t);
  node->left  = NULL;
  node->right = NULL;
  node->value = newSVsv(value);
  return node;
}

void free_node(skewnode_t *node) {
  if (node->left != NULL)  free_node(node->left);
  if (node->right != NULL) free_node(node->right);
  if (node->value != NULL) SvREFCNT_dec(node->value);
  Safefree(node);
}

SV* new(const char *class, SV *cmp) {
  skewheap_t *heap;
  SV *obj;
  SV *ref;

  Newx(heap, 1, skewheap_t);
  heap->root = NULL;
  heap->size = 0;
  heap->cmp  = newSVsv(cmp);

  obj = newSViv((IV) heap);
  ref = newRV_noinc(obj);
  sv_bless(ref, gv_stashpv(class, GV_ADD));
  SvREADONLY_on(obj);

  return ref;
}

void DESTROY(SV *ref) {
  skewheap_t *heap = SKEW(ref);
  if (heap->root != NULL) free_node(heap->root);
  SvREFCNT_dec(heap->cmp);
  Safefree(heap);
}

void _explain(skewnode_t *node, int depth) {
  int i;

  for (i = 0; i < depth; ++i) printf("--");
  printf("VALUE: %ld\n", SvIV(node->value));

  if (node->left != NULL) {
    for (i = 0; i < depth; ++i) printf("--");
    printf("LEFT:\n");
    _explain(node->left, depth + 1);
  }

  if (node->right != NULL) {
    for (i = 0; i < depth; ++i) printf("--");
    printf("RIGHT:\n");
    _explain(node->right, depth + 1);
  }
}

void explain(SV *ref) {
  skewheap_t *heap = SKEW(ref);
  printf("SKEWHEAP:\n");
  if (heap->root != NULL) {
    _explain(heap->root, 2);
  }
}

void sort_nodes(skewnode_t *nodes[], int length, SV* cmp) {
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
  CV *cv = sv_2cv(cmp, &stash, &gv, 0);

  if (cv == Nullcv) {
    croak("Not a subroutine reference");
  }

  agv = gv_fetchpv("a", GV_ADD, SVt_PV);
  bgv = gv_fetchpv("b", GV_ADD, SVt_PV);
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

void _merge(skewheap_t *heap, skewnode_t *a, skewnode_t *b) {
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
      sort_nodes(nodes, nidx, heap->cmp);
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

void put(SV *ref, ...) {
  Inline_Stack_Vars;
  Inline_Stack_Reset;

  skewheap_t *heap = SKEW(ref);
  skewnode_t *node;
  int i;
 
  for (i = 1; i < Inline_Stack_Items; ++i) {
    node = new_node(Inline_Stack_Item(i));
    ++heap->size;

    if (heap->root == NULL) {
      heap->root = node;
    } else {
      _merge(heap, heap->root, node);
    }
  }

  Inline_Stack_Push(sv_2mortal(newSViv(heap->size)));
  Inline_Stack_Done;
}

void take(SV *ref) {
  skewheap_t *heap = SKEW(ref);
  skewnode_t *root = heap->root;

  Inline_Stack_Vars;
  Inline_Stack_Reset;

  if (root != NULL) {
    Inline_Stack_Push(sv_mortalcopy(root->value));
    --heap->size;
    _merge(heap, root->left, root->right);
    root->left  = NULL;
    root->right = NULL;
    free_node(root);
  }
  else {
    Inline_Stack_Push(&PL_sv_undef);
  }

  Inline_Stack_Done;
}

void top(SV *ref) {
  skewheap_t *heap = SKEW(ref);

  Inline_Stack_Vars;
  Inline_Stack_Reset;

  Inline_Stack_Push(
    heap->root == NULL
      ? &PL_sv_undef
      : sv_mortalcopy(heap->root->value)
  );

  Inline_Stack_Done;
}

int size(SV *ref) {
  skewheap_t *heap = SKEW(ref);
  return heap->size;
}

int merge(SV *heap_a, SV *heap_b) {
  skewheap_t *a = SKEW(heap_a);
  skewheap_t *b = SKEW(heap_b);

  if (a->root == NULL) {
    a->root = b->root;
  } else if (b->root != NULL) {
    _merge(a, a->root, b->root);
  }

  a->size += b->size;
  b->size = 0;
  b->root = NULL;

  return a->size;
}

__EOC__
