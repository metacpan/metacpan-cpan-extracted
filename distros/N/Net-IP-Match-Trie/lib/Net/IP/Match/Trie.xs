#ifdef __cplusplus
extern "C" {
#endif
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"

#include <unistd.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>

#ifdef __cplusplus
}
#endif

// for debug fixme
//#define DEBUG 1

#ifdef DEBUG
#  define DIAG(fmt, ...) PerlIO_printf(PerlIO_stderr(), fmt, __VA_ARGS__);
#  define DUMPTREE(pt) { CIDR_TRIE *xt = pt; xt = xt->child[10]; xt = xt->child[0]; xt = xt->child[0]; xt = xt->child[1]; DIAG("    DUMPTREE %s\n", xt->name); }
#else
#  define DIAG(fmt, ...)
#  define DUMPTREE(pt, ...)
#endif

#define CIDR_TABLE_BITS 8
#define CIDR_TABLE_SIZE (1 << CIDR_TABLE_BITS)

typedef struct CIDR_TRIE {
  const char       *name;
  uint32_t          bits;
  struct CIDR_TRIE *child[CIDR_TABLE_SIZE];
} CIDR_TRIE;

static int itonetmask(int n, uint32_t *netmask)
{
  uint32_t m;

  if (n < 0 || 32 < n) return 0;

  m = 1UL << (32 - n);
  --m;
  *netmask = ~m;
  return 1;
}

static int is_leaf(const CIDR_TRIE *pt) {
  return pt->child[0] == pt;
}

static CIDR_TRIE *new_trie_node() {
  int i;
  CIDR_TRIE *pt;

  Newxz(pt, 1, CIDR_TRIE);

  pt->name = 0;
  pt->bits = 0;
  for (i = 0; i < CIDR_TABLE_SIZE; ++i)
    pt->child[i] = pt;
  return pt;
}

static void init_root(CIDR_TRIE *trie_root)
{
  int i;
  CIDR_TRIE *nullnode;

  nullnode = new_trie_node();
  for (i = 0; i < CIDR_TABLE_SIZE; ++i)
    trie_root->child[i] = nullnode;
}

static CIDR_TRIE* digg_trie(CIDR_TRIE *child) {
  int i;
  CIDR_TRIE *parent = new_trie_node();

  for (i = 0; i < CIDR_TABLE_SIZE; ++i)
    parent->child[i] = child;
  return parent;
}

static int update_leaf(CIDR_TRIE *pt, CIDR_TRIE *leaf)
{
  int used = 0;
  int i;

  for (i = 0; i < CIDR_TABLE_SIZE; ++i) {
    CIDR_TRIE *next = pt->child[i];
    if (is_leaf(next)) {
      if (next->bits < leaf->bits) {
        pt->child[i] = leaf;
        used = 1;
      }
    }
    else {
      used |= update_leaf(next, leaf);
    }
  }
  return used;
}


MODULE = Net::IP::Match::Trie     PACKAGE = Net::IP::Match::Trie

SV *
_initialize(self)
    SV *self;
  PREINIT:
    CIDR_TRIE *root, *nullnode;
    int i;
  CODE:
    root     = new_trie_node();
    nullnode = new_trie_node();
    for (i = 0; i < CIDR_TABLE_SIZE; ++i)
      root->child[i] = nullnode;
    sv_magic(SvRV(self), NULL, PERL_MAGIC_ext, NULL, 0);
    mg_find(SvRV(self), PERL_MAGIC_ext)->mg_obj = (void *)root;

void
_add(self, name, network, netmask)
    SV *self;
    SV *name;
    SV *network;
    SV *netmask;
  PREINIT:
    CIDR_TRIE *pt, *p_leaf;
    size_t    len;
    in_addr_t addr;
    uint32_t  nm;
  CODE:
    DIAG(">>%s %s %s/%d\n", "add", SvPV_nolen(name), SvPV_nolen(network), SvIV(netmask));
    DUMPTREE((CIDR_TRIE *)mg_find(SvRV(self), PERL_MAGIC_ext)->mg_obj);
    if (!inet_aton(SvPV_nolen(network), (struct in_addr *)&addr)) {
      warn("inet_aton: failed");
    }
    len = SvIV(netmask);
    if (!itonetmask(len,&nm)) {
      warn("itonetmask: failed");
    }
    DIAG("  nm  :%08X\n", nm);
    addr = ntohl(addr);
    DIAG("  addr:%08X\n", addr);
    addr &= nm;
    DIAG("  addr&nm:%08X\n", addr);

    pt     = (CIDR_TRIE *)mg_find(SvRV(self), PERL_MAGIC_ext)->mg_obj;

    p_leaf = new_trie_node();
    p_leaf->name = SvPV_nolen(newSVsv(name));
    p_leaf->bits = len;

    while (len > CIDR_TABLE_BITS) {
      int b = addr >> (32 - CIDR_TABLE_BITS);
      CIDR_TRIE *next = pt->child[b];
      if (is_leaf(next)) {
        pt->child[b] = next = digg_trie(next);
      }
      pt = next;
      addr <<= CIDR_TABLE_BITS;
      len -= CIDR_TABLE_BITS;
    }
    {
      int i;
      const int bmin = addr >> (32 - CIDR_TABLE_BITS);
      const int bmax = bmin + (1 << (CIDR_TABLE_BITS - len));
      int used = 0; // delete p_leaf if it is not used.
      for (i = bmin; i < bmax; ++i) {
        CIDR_TRIE *target = pt->child[i];
        if (is_leaf(target)) {
          if (target->bits < p_leaf->bits) {
            pt->child[i] = p_leaf;
            used = 1;
          }
        }
        else {
          int j;
          for (j = 0; j < CIDR_TABLE_SIZE; ++j) {
            used |= update_leaf(target, p_leaf);
          }
        }
      }
    }
    DUMPTREE((CIDR_TRIE *)mg_find(SvRV(self), PERL_MAGIC_ext)->mg_obj);

SV *
match_ip(self, ip)
    SV *self;
    SV *ip;
  PREINIT:
    CIDR_TRIE *pt;
    in_addr_t addr;
    uint8_t   *octed;
  CODE:
    DIAG(">>%s %s\n", "match_ip", SvPV_nolen(ip));
    pt = (CIDR_TRIE *)mg_find(SvRV(self), PERL_MAGIC_ext)->mg_obj;
    if (!inet_aton(SvPV_nolen(ip), (struct in_addr *)&addr)) {
      warn("inet_aton: failed");
      XSRETURN_EMPTY;
    }

    DIAG("  addr:%08X\n", addr);
    octed = (uint8_t *)&addr;
#if CIDR_TABLE_BITS == 8
    pt = pt->child[*octed++];
    pt = pt->child[*octed++];
    pt = pt->child[*octed++];
    pt = pt->child[*octed++];
#elif CIDR_TABLE_BITS == 16
    pt = pt->child[octed[0] * 256 + octed[1]];
    pt = pt->child[octed[2] * 256 + octed[3]];
#else
#error CIDR_TABLE_BITS must be 8 or 16.
#endif
    DIAG("    name:%s\n", pt->name);
    RETVAL = newSVpv(pt->name != NULL ? pt->name : "", 0);
  OUTPUT:
    RETVAL

void
DESTROY(self)
    SV *self;
  PREINIT:
    CIDR_TRIE *root;
  CODE:
    DIAG(">>%s\n", "DESTROY");
    root = (CIDR_TRIE *)mg_find(SvRV(self), PERL_MAGIC_ext)->mg_obj;
    /* todo: free all node of tree */
    Safefree(root);
