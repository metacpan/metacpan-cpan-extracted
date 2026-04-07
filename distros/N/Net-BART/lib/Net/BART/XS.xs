#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "bart.h"

/* Helpers: increment/decrement SV refcounts for values stored in the trie */

static void sv_val_dec(pTHX_ void *val) {
    if (val) SvREFCNT_dec((SV*)val);
}

/* Free all SV* values in a node tree (called before bart_table_free) */
static void free_node_svs(pTHX_ bart_node_t *node) {
    int i;
    if (!node) return;
    /* Free prefix SVs */
    for (i = 0; i < node->prefixes.len; i++) {
        sv_val_dec(aTHX_ node->prefixes.items[i]);
    }
    /* Free child SVs recursively */
    for (i = 0; i < node->children.len; i++) {
        void *tagged = node->children.items[i];
        int tag = ptr_tag(tagged);
        void *child = untag_ptr(tagged);
        switch (tag) {
            case NODE_BART:
                free_node_svs(aTHX_ (bart_node_t*)child);
                break;
            case NODE_LEAF:
                sv_val_dec(aTHX_ ((leaf_node_t*)child)->value);
                break;
            case NODE_FRINGE:
                sv_val_dec(aTHX_ ((fringe_node_t*)child)->value);
                break;
        }
    }
}

/* Parse "addr/len" or bare IP. Returns is_ipv6. */
static int parse_prefix_str(pTHX_ const char *str, uint8_t *addr, int *addr_len, int *prefix_len) {
    char buf[256];
    const char *slash;
    int is_ipv6;

    strncpy(buf, str, sizeof(buf) - 1);
    buf[sizeof(buf) - 1] = '\0';

    slash = strchr(buf, '/');
    if (slash) {
        buf[slash - buf] = '\0';
        *prefix_len = atoi(slash + 1);
    } else {
        *prefix_len = -1; /* will be set based on address type */
    }

    is_ipv6 = (strchr(buf, ':') != NULL);

    if (is_ipv6) {
        /* Parse IPv6 using inet_pton */
        struct in6_addr in6;
        if (inet_pton(AF_INET6, buf, &in6) != 1) {
            croak("Invalid IPv6 address: %s", buf);
        }
        memcpy(addr, &in6, 16);
        *addr_len = 16;
        if (*prefix_len < 0) *prefix_len = 128;
    } else {
        if (!parse_ipv4(buf, addr)) {
            croak("Invalid IPv4 address: %s", buf);
        }
        memset(addr + 4, 0, 12);
        *addr_len = 4;
        if (*prefix_len < 0) *prefix_len = 32;
    }

    mask_prefix(addr, *addr_len, *prefix_len);
    return is_ipv6;
}

/* Parse bare IP for lookup/contains. */
static int parse_ip_str(pTHX_ const char *str, uint8_t *addr) {
    int is_ipv6 = (strchr(str, ':') != NULL);
    if (is_ipv6) {
        struct in6_addr in6;
        if (inet_pton(AF_INET6, str, &in6) != 1) {
            croak("Invalid IPv6 address: %s", str);
        }
        memcpy(addr, &in6, 16);
    } else {
        if (!parse_ipv4(str, addr)) {
            croak("Invalid IPv4 address: %s", str);
        }
    }
    return is_ipv6;
}


MODULE = Net::BART::XS    PACKAGE = Net::BART::XS

PROTOTYPES: DISABLE

SV*
new(class)
    const char *class
  CODE:
    bart_table_t *t = bart_table_new();
    SV *obj = newSViv(PTR2IV(t));
    SV *objref = newRV_noinc(obj);
    sv_bless(objref, gv_stashpv(class, GV_ADD));
    RETVAL = objref;
  OUTPUT:
    RETVAL

void
DESTROY(self)
    SV *self
  CODE:
    bart_table_t *t = INT2PTR(bart_table_t*, SvIV(SvRV(self)));
    free_node_svs(aTHX_ t->root4);
    free_node_svs(aTHX_ t->root6);
    bart_table_free(t);

int
insert(self, prefix_str, value)
    SV *self
    const char *prefix_str
    SV *value
  CODE:
    bart_table_t *t = INT2PTR(bart_table_t*, SvIV(SvRV(self)));
    uint8_t addr[16];
    int addr_len, prefix_len;
    int is_ipv6 = parse_prefix_str(aTHX_ prefix_str, addr, &addr_len, &prefix_len);
    bart_node_t *root = is_ipv6 ? t->root6 : t->root4;

    SV *sv_copy = newSVsv(value);
    void *old_val = NULL;
    int is_new = bart_insert(root, addr, addr_len, prefix_len, 0, (void*)sv_copy, &old_val);

    if (!is_new && old_val) {
        SvREFCNT_dec((SV*)old_val);
    }
    if (is_new) {
        if (is_ipv6) t->size6++; else t->size4++;
    }
    RETVAL = is_new;
  OUTPUT:
    RETVAL

void
lookup(self, ip_str)
    SV *self
    const char *ip_str
  PPCODE:
    bart_table_t *t = INT2PTR(bart_table_t*, SvIV(SvRV(self)));
    uint8_t addr[16];
    int is_ipv6 = parse_ip_str(aTHX_ ip_str, addr);
    int found = 0;
    void *val = bart_lookup(t, addr, is_ipv6, &found);
    if (found && val) {
        XPUSHs(sv_2mortal(newSVsv((SV*)val)));
        XPUSHs(sv_2mortal(newSViv(1)));
    } else {
        XPUSHs(&PL_sv_undef);
        XPUSHs(sv_2mortal(newSViv(0)));
    }

int
contains(self, ip_str)
    SV *self
    const char *ip_str
  CODE:
    bart_table_t *t = INT2PTR(bart_table_t*, SvIV(SvRV(self)));
    uint8_t addr[16];
    int is_ipv6 = parse_ip_str(aTHX_ ip_str, addr);
    RETVAL = bart_contains(t, addr, is_ipv6);
  OUTPUT:
    RETVAL

void
get(self, prefix_str)
    SV *self
    const char *prefix_str
  PPCODE:
    bart_table_t *t = INT2PTR(bart_table_t*, SvIV(SvRV(self)));
    uint8_t addr[16];
    int addr_len, prefix_len;
    int is_ipv6 = parse_prefix_str(aTHX_ prefix_str, addr, &addr_len, &prefix_len);
    int found = 0;
    void *val = bart_get(t, addr, prefix_len, is_ipv6, &found);
    if (found && val) {
        XPUSHs(sv_2mortal(newSVsv((SV*)val)));
        XPUSHs(sv_2mortal(newSViv(1)));
    } else {
        XPUSHs(&PL_sv_undef);
        XPUSHs(sv_2mortal(newSViv(0)));
    }

void
delete(self, prefix_str)
    SV *self
    const char *prefix_str
  PPCODE:
    bart_table_t *t = INT2PTR(bart_table_t*, SvIV(SvRV(self)));
    uint8_t addr[16];
    int addr_len, prefix_len;
    int is_ipv6 = parse_prefix_str(aTHX_ prefix_str, addr, &addr_len, &prefix_len);
    bart_node_t *root = is_ipv6 ? t->root6 : t->root4;
    int found = 0;
    void *val = bart_delete(root, addr, prefix_len, 0, &found);
    if (found) {
        if (is_ipv6) t->size6--; else t->size4--;
        if (val) {
            XPUSHs(sv_2mortal(newSVsv((SV*)val)));
            SvREFCNT_dec((SV*)val);
        } else {
            XPUSHs(&PL_sv_undef);
        }
        XPUSHs(sv_2mortal(newSViv(1)));
    } else {
        XPUSHs(&PL_sv_undef);
        XPUSHs(sv_2mortal(newSViv(0)));
    }

int
size(self)
    SV *self
  CODE:
    bart_table_t *t = INT2PTR(bart_table_t*, SvIV(SvRV(self)));
    RETVAL = t->size4 + t->size6;
  OUTPUT:
    RETVAL

int
size4(self)
    SV *self
  CODE:
    bart_table_t *t = INT2PTR(bart_table_t*, SvIV(SvRV(self)));
    RETVAL = t->size4;
  OUTPUT:
    RETVAL

int
size6(self)
    SV *self
  CODE:
    bart_table_t *t = INT2PTR(bart_table_t*, SvIV(SvRV(self)));
    RETVAL = t->size6;
  OUTPUT:
    RETVAL
