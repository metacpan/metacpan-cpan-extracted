#ifdef __cplusplus
extern "C" {
#endif
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#ifdef __cplusplus
}
#endif

#include <sys/types.h>
#include <stdint.h>
#include <netinet/in.h>
#include "libpatricia/patricia.h"

/* frozen stuff is frozen in network byte order */
struct frozen_node
{
	int32_t l_index;
	int32_t r_index;
	int32_t d_index;
	uint16_t bitlen; /* bit 0x8000 indicates presence of prefix */
	uint16_t family;
	uint8_t  address[16];
} __attribute__((__packed__));

struct frozen_header
{
	uint32_t magic;
#define FROZEN_MAGIC 0x4E655061  /* NePa */
	uint8_t major;
#define FROZEN_MAJOR 0
	uint8_t minor;
#define FROZEN_MINOR 0
	uint16_t maxbits;
	int32_t num_total_node;
	int32_t num_active_node;
} __attribute__((__packed__));

struct frozen_patricia
{
	struct frozen_header header;
	struct frozen_node node[1];
} __attribute__((__packed__));

static int
not_here(s)
char *s;
{
    croak("%s not implemented on this architecture", s);
    return -1;
}

static double
constant(name, arg)
char *name;
int arg;
{
    errno = 0;
    switch (*name) {
    case 'A':
	break;
    case 'B':
	break;
    case 'C':
	break;
    case 'D':
	break;
    case 'E':
	break;
    case 'F':
	break;
    case 'G':
	break;
    case 'H':
	break;
    case 'I':
	break;
    case 'J':
	break;
    case 'K':
	break;
    case 'L':
	break;
    case 'M':
	break;
    case 'N':
	break;
    case 'O':
	break;
    case 'P':
	break;
    case 'Q':
	break;
    case 'R':
	break;
    case 'S':
	break;
    case 'T':
	break;
    case 'U':
	break;
    case 'V':
	break;
    case 'W':
	break;
    case 'X':
	break;
    case 'Y':
	break;
    case 'Z':
	break;
    case 'a':
	break;
    case 'b':
	break;
    case 'c':
	break;
    case 'd':
	break;
    case 'e':
	break;
    case 'f':
	break;
    case 'g':
	break;
    case 'h':
	break;
    case 'i':
	break;
    case 'j':
	break;
    case 'k':
	break;
    case 'l':
	break;
    case 'm':
	break;
    case 'n':
	break;
    case 'o':
	break;
    case 'p':
	break;
    case 'q':
	break;
    case 'r':
	break;
    case 's':
	break;
    case 't':
	break;
    case 'u':
	break;
    case 'v':
	break;
    case 'w':
	break;
    case 'x':
	break;
    case 'y':
	break;
    case 'z':
	break;
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

#define Fill_Prefix(p,f,a,b,mb) \
	do { \
		if (b < 0 || b > mb) \
		  croak("invalid key"); \
		memcpy(&p.add.sin, a, (mb+7)/8); \
		p.family = f; \
		p.bitlen = b; \
		p.ref_count = 0; \
	} while (0)

static void deref_data(SV *data) {
   SvREFCNT_dec(data);
   data = NULL;
}

static size_t
patricia_walk_inorder_perl(patricia_node_t *node, SV *coderef) {
    dSP;
    size_t n = 0;

    if (node->l) {
         n += patricia_walk_inorder_perl(node->l, coderef);
    }

    if (node->prefix) {
        if (NULL != coderef) {
            PUSHMARK(SP);
            XPUSHs(sv_mortalcopy((SV *)node->data));
            PUTBACK;
            perl_call_sv(coderef, G_VOID|G_DISCARD);
            SPAGAIN;
        }
	n++;
    }
	
    if (node->r) {
         n += patricia_walk_inorder_perl(node->r, coderef);
    }

    return n;
}

typedef patricia_tree_t *Net__Patricia;
typedef patricia_node_t *Net__PatriciaNode;

MODULE = Net::Patricia		PACKAGE = Net::Patricia

PROTOTYPES: ENABLE

double
constant(name,arg)
	char *		name
	int		arg

Net::Patricia
_new(size)
	int				size
	CODE:
		RETVAL = New_Patricia(size);
	OUTPUT:	
		RETVAL

void
_add(tree, family, addr, bits, data)
	Net::Patricia			tree
	int				family
	char *				addr
	int				bits
	SV *				data
	PROTOTYPE: $$$$$
	PREINIT:
	   	prefix_t prefix;
	   	Net__PatriciaNode node;
	PPCODE:
		Fill_Prefix(prefix, family, addr, bits, tree->maxbits);
	   	node = patricia_lookup(tree, &prefix);
		if (NULL != node) {
		   /* { */
		   if (node->data) {
		      deref_data(node->data);
		   }
		   node->data = newSVsv(data);
		   /* } */
		   PUSHs(data);
		} else {
		   XSRETURN_UNDEF;
		}

void
_match(tree, family, addr, bits)
	Net::Patricia			tree
	int				family
	char *				addr
	int				bits
	PROTOTYPE: $$$$
	PREINIT:
	   	prefix_t prefix;
	   	Net__PatriciaNode node;
	PPCODE:
		Fill_Prefix(prefix, family, addr, bits, tree->maxbits);
		node = patricia_search_best(tree, &prefix);
		if (NULL != node) {
		   XPUSHs((SV *)node->data);
		} else {
		   XSRETURN_UNDEF;
		}

void
_exact(tree, family, addr, bits)
	Net::Patricia			tree
	int				family
	char *				addr
	int				bits
	PROTOTYPE: $$$$
	PREINIT:
	   	prefix_t prefix;
	   	Net__PatriciaNode node;
	PPCODE:
		Fill_Prefix(prefix, family, addr, bits, tree->maxbits);
		node = patricia_search_exact(tree, &prefix);
		if (NULL != node) {
		   XPUSHs((SV *)node->data);
		} else {
		   XSRETURN_UNDEF;
		}


void
_remove(tree, family, addr, bits)
	Net::Patricia			tree
	int				family
	char *				addr
	int				bits
	PROTOTYPE: $$$$
	PREINIT:
	   	prefix_t prefix;
	   	Net__PatriciaNode node;
	PPCODE:
		Fill_Prefix(prefix, family, addr, bits, tree->maxbits);
	   	node = patricia_search_exact(tree, &prefix);
		if (NULL != node) {
		   XPUSHs(sv_mortalcopy((SV *)node->data));
		   deref_data(node->data);
		   patricia_remove(tree, node);
		} else {
		   XSRETURN_UNDEF;
		}

size_t
climb(tree, ...)
	Net::Patricia			tree
	PREINIT:
		patricia_node_t *node = NULL;
		size_t n = 0;
		SV *func = NULL;
	CODE:
		if (2 == items) {
		   func = ST(1);
		} else if (2 < items) {
	           croak("Usage: Net::Patricia::climb(tree[,CODEREF])");
		}
		PATRICIA_WALK (tree->head, node) {
		   if (NULL != func) {
		      PUSHMARK(SP);
		      XPUSHs(sv_mortalcopy((SV *)node->data));
		      PUTBACK;
		      perl_call_sv(func, G_VOID|G_DISCARD);
		      SPAGAIN;
		   }
		   n++;
		} PATRICIA_WALK_END;
		RETVAL = n;
	OUTPUT:	
		RETVAL

size_t
climb_inorder(tree, ...)
	Net::Patricia			tree
	PREINIT:
		size_t n = 0;
		SV *func = NULL;
	CODE:
		func = NULL;
		if (2 == items) {
		   func = ST(1);
		} else if (2 < items) {
	           croak("Usage: Net::Patricia::climb_inorder(tree[,CODEREF])");
		}
                n = patricia_walk_inorder_perl(tree->head, func);
		RETVAL = n;
	OUTPUT:	
		RETVAL

void
STORABLE_freeze(tree, cloning)
	Net::Patricia			tree
	SV *				cloning
	PREINIT:
		patricia_node_t *node = NULL;
		struct frozen_header frozen_header;
		struct frozen_node *frozen_nodes, *frozen_node;
		size_t n = 0, i = 0, nd = 0;
		SV *frozen_patricia;
	PPCODE:
		if (SvTRUE(cloning))
		  XSRETURN_UNDEF;

		/* I do not know enough of patricia.c to
		 * decide whether inactive nodes can
		 * be present in a tree, and whether such
		 * nodes can be skipped while copying,
		 * so we copy everything and do not use
		 * num_active_node here. */
		PATRICIA_WALK_ALL (tree->head, node) {
			n++;
		} PATRICIA_WALK_END;

		if (n > 2147483646)
			croak("Net::Patricia::STORABLE_freeze: too many nodes");

		frozen_header.magic           = htonl(FROZEN_MAGIC);
		frozen_header.major           = FROZEN_MAJOR;
		frozen_header.minor           = FROZEN_MINOR;
		frozen_header.maxbits         = htons((uint16_t)tree->maxbits);
		frozen_header.num_total_node  = htonl(n);
		frozen_header.num_active_node = htonl(tree->num_active_node);

		frozen_patricia = newSVpv((char *)&frozen_header, sizeof(frozen_header));
		XPUSHs(frozen_patricia);

		frozen_nodes = calloc(n, sizeof(struct frozen_node));

		/* We use user1 field to store the index of each node
		 * in the frozen_node array;  it is okay since Net::Patricia
		 * is not using it for anything anywhere else */
		PATRICIA_WALK_ALL (tree->head, node) {
		    node->user1 = (void *)(IV)i;

		    frozen_node = &frozen_nodes[i];
		    frozen_node->l_index = htonl(-1);
		    frozen_node->r_index = htonl(-1);
		    frozen_node->bitlen = node->bit;
		    if (node->prefix) {
			frozen_node->bitlen |= 0x8000;
			frozen_node->family = htons(node->prefix->family);
			if (tree->maxbits == 32)
			    memcpy(&frozen_node->address, &node->prefix->add, 4);
			else
			    memcpy(&frozen_node->address, &node->prefix->add, 16);
		    }
		    frozen_node->bitlen = htons(frozen_node->bitlen);

		    if (node->data) {
			frozen_node->d_index = htonl(nd);
			nd++;
			XPUSHs(sv_2mortal(newRV_inc((SV *)node->data)));
		    } else {
			frozen_node->d_index = htonl(-1);
		    }
		    if (node->parent && node->parent->l == node) {
			frozen_nodes[(IV)node->parent->user1].l_index = htonl(i);
		    } else if (node->parent && node->parent->r == node) {
			frozen_nodes[(IV)node->parent->user1].r_index = htonl(i);
		    }
		    i++;
		} PATRICIA_WALK_END;

		sv_catpvn(frozen_patricia, (char*)frozen_nodes, n*sizeof(struct frozen_node));
		free(frozen_nodes);

void
STORABLE_thaw(tobj, cloning, serialized, ...)
	SV *				tobj
	SV *				cloning
	SV *				serialized;
	PREINIT:
		struct frozen_patricia *frozen_patricia;
		struct frozen_node *frozen_node;
		struct _patricia_tree_t *tree;
		patricia_node_t *node = NULL, *child, **fixup;
		int n, n_calculated, i, d_index, l_index, r_index;
		STRLEN len;
	PPCODE:
		if (SvTRUE(cloning))
		    XSRETURN_UNDEF;

		tree = calloc(1, sizeof(*tree));
		frozen_patricia = (struct frozen_patricia*)SvPV(serialized, len);

		if (ntohl(frozen_patricia->header.magic) != FROZEN_MAGIC)
		    croak("Net::Patricia::STORABLE_thaw: magic mismatch");
		if (frozen_patricia->header.major != FROZEN_MAJOR)
		    croak("Net::Patricia::STORABLE_thaw: major mismatch");
		if (frozen_patricia->header.minor != FROZEN_MINOR)
		    croak("Net::Patricia::STORABLE_thaw: minor mismatch");

		tree->maxbits          = ntohs(frozen_patricia->header.maxbits);
		tree->num_active_node  = ntohl(frozen_patricia->header.num_active_node);
		tree->head             = NULL;

		n            = ntohl(frozen_patricia->header.num_total_node);
		n_calculated = (len - sizeof(frozen_patricia->header)) / sizeof(struct frozen_node);
		if (n_calculated < n)
		    croak("Net::Patricia::STORABLE_thaw: size mismatch");
		fixup = calloc(n, sizeof(patricia_node_t *));

		for (i = 0; i < n; i++) {
		    node = calloc(1, sizeof(*node));
		    memset(node, 0, sizeof(*node));
		    frozen_node = &frozen_patricia->node[i];

		    node->bit = ntohs(frozen_node->bitlen) & ~0x8000;
		    d_index = ntohl(frozen_node->d_index);
		    if (d_index >= 0)
			node->data = newSVsv(SvRV(ST(3+d_index)));

		    if (ntohs(frozen_node->bitlen) & 0x8000) {
			node->prefix = calloc(1, sizeof(*node->prefix));
			node->prefix->bitlen = node->bit;
			node->prefix->family = ntohs(frozen_node->family);
#ifndef HAVE_IPV6
			if (tree->maxbits > 32)
			    croak("Net::Patricia::STORABLE_thaw: IPv6 is not supported by Net::Patricia on this machine");
#endif
			if (tree->maxbits == 32) {
			    memcpy(&node->prefix->add, &frozen_node->address, 4);
			} else
			    memcpy(&node->prefix->add, &frozen_node->address, 16);
			node->prefix->ref_count = 1;
		    }
		    fixup[i] = node;
		}

		/* Fix pointers up. */
		if (n)
		    tree->head = fixup[0];
		for (i = 0; i < n; i++) {
		    frozen_node = &frozen_patricia->node[i];
		    node = fixup[i];

		    l_index = ntohl(frozen_node->l_index);
		    if (l_index >= 0) {
			child = fixup[l_index];
			child->parent = node;
			node->l = child;
		    }

		    r_index = ntohl(frozen_node->r_index);
		    if (r_index >= 0) {
			child = fixup[r_index];
			child->parent = node;
			node->r = child;
		    }
		}

		free(fixup);
		sv_setiv((SV*)SvRV(tobj), PTR2IV(tree));
		XSRETURN_EMPTY;

void
DESTROY(tree)
	Net::Patricia			tree
	CODE:
	Destroy_Patricia(tree, deref_data);
