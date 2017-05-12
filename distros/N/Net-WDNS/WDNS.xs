/*
**
** Copyright (C) 2010 by Carnegie Mellon University
**
** This program is free software; you can redistribute it and/or modify
** it under the terms of the GNU General Public License, as published by
** the Free Software Foundation, under the terms pursuant to Version 2,
** June 1991.
**
** This program is distributed in the hope that it will be useful, but
** WITHOUT ANY WARRANTY; without even the implied warranty of
** MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General
** Public License for more details.
**
*/

#ifdef __cplusplus
extern "C" {
#endif

#define PERL_NO_GET_CONTEXT

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#define NEED_PL_signals 1
#include "ppport.h"

#include "pthread.h"

#include "stdlib.h"

#include <wdns.h>

#ifdef _CYGWIN
#include <Win32-Extensions.h>
#endif

#include <signal.h>
#include <assert.h>

#ifdef __cplusplus
}
#endif

typedef wdns_message_t  *Net__WDNS__XS__msg;


MODULE = Net::WDNS  PACKAGE = Net::WDNS   PREFIX = wdns_

BOOT:
#define MC(cc) \
    newCONSTSUB(stash, #cc, newSViv( cc ))
// BOOT ends after first blank line outside of a block
{
    HV *stash;

    stash = gv_stashpv("Net::WDNS", TRUE);

    MC(WDNS_LEN_HEADER);
    MC(WDNS_MAXLEN_NAME);
    
    MC(WDNS_MSG_SEC_QUESTION);
    MC(WDNS_MSG_SEC_ANSWER);
    MC(WDNS_MSG_SEC_AUTHORITY);
    MC(WDNS_MSG_SEC_ADDITIONAL);
    MC(WDNS_MSG_SEC_MAX);
    
    MC(WDNS_PRESLEN_NAME);
    MC(WDNS_PRESLEN_TYPE_A);
    MC(WDNS_PRESLEN_TYPE_AAAA);
    
    MC(WDNS_OP_QUERY);
    MC(WDNS_OP_IQUERY);
    MC(WDNS_OP_STATUS);
    MC(WDNS_OP_NOTIFY);
    MC(WDNS_OP_UPDATE);
    
    MC(WDNS_R_NOERROR);
    MC(WDNS_R_FORMERR);
    MC(WDNS_R_SERVFAIL);
    MC(WDNS_R_NXDOMAIN);
    MC(WDNS_R_NOTIMP);
    MC(WDNS_R_REFUSED);
    MC(WDNS_R_YXDOMAIN);
    MC(WDNS_R_YXRRSET);
    MC(WDNS_R_NXRRSET);
    MC(WDNS_R_NOTAUTH);
    MC(WDNS_R_NOTZONE);
    MC(WDNS_R_BADVERS);
    
    MC(WDNS_CLASS_IN);
    MC(WDNS_CLASS_CH);
    MC(WDNS_CLASS_HS);
    MC(WDNS_CLASS_NONE);
    MC(WDNS_CLASS_ANY);
    
    MC(WDNS_TYPE_A);
    MC(WDNS_TYPE_NS);
    MC(WDNS_TYPE_MD);
    MC(WDNS_TYPE_MF);
    MC(WDNS_TYPE_CNAME);
    MC(WDNS_TYPE_SOA);
    MC(WDNS_TYPE_MB);
    MC(WDNS_TYPE_MG);
    MC(WDNS_TYPE_MR);
    MC(WDNS_TYPE_NULL);
    MC(WDNS_TYPE_WKS);
    MC(WDNS_TYPE_PTR);
    MC(WDNS_TYPE_HINFO);
    MC(WDNS_TYPE_MINFO);
    MC(WDNS_TYPE_MX);
    MC(WDNS_TYPE_TXT);
    MC(WDNS_TYPE_RP);
    MC(WDNS_TYPE_AFSDB);
    MC(WDNS_TYPE_X25);
    MC(WDNS_TYPE_ISDN);
    MC(WDNS_TYPE_RT);
    MC(WDNS_TYPE_NSAP);
    MC(WDNS_TYPE_NSAP_PTR);
    MC(WDNS_TYPE_SIG);
    MC(WDNS_TYPE_KEY);
    MC(WDNS_TYPE_PX);
    MC(WDNS_TYPE_GPOS);
    MC(WDNS_TYPE_AAAA);
    MC(WDNS_TYPE_LOC);
    MC(WDNS_TYPE_NXT);
    MC(WDNS_TYPE_EID);
    MC(WDNS_TYPE_NIMLOC);
    MC(WDNS_TYPE_SRV);
    MC(WDNS_TYPE_ATMA);
    MC(WDNS_TYPE_NAPTR);
    MC(WDNS_TYPE_KX);
    MC(WDNS_TYPE_CERT);
    MC(WDNS_TYPE_A6);
    MC(WDNS_TYPE_DNAME);
    MC(WDNS_TYPE_SINK);
    MC(WDNS_TYPE_OPT);
    MC(WDNS_TYPE_APL);
    MC(WDNS_TYPE_DS);
    MC(WDNS_TYPE_SSHFP);
    MC(WDNS_TYPE_IPSECKEY);
    MC(WDNS_TYPE_RRSIG);
    MC(WDNS_TYPE_NSEC);
    MC(WDNS_TYPE_DNSKEY);
    MC(WDNS_TYPE_DHCID);
    MC(WDNS_TYPE_NSEC3);
    MC(WDNS_TYPE_NSEC3PARAM);
    MC(WDNS_TYPE_TLSA);

    MC(WDNS_TYPE_HIP);
    MC(WDNS_TYPE_NINFO);
    MC(WDNS_TYPE_RKEY);
    MC(WDNS_TYPE_TALINK);
    MC(WDNS_TYPE_CDS);
    MC(WDNS_TYPE_CDNSKEY);
    MC(WDNS_TYPE_CSYNC);

    MC(WDNS_TYPE_SPF);
    MC(WDNS_TYPE_UINFO);
    MC(WDNS_TYPE_UID);
    MC(WDNS_TYPE_GID);
    MC(WDNS_TYPE_UNSPEC);
    MC(WDNS_TYPE_NID);
    MC(WDNS_TYPE_L32);
    MC(WDNS_TYPE_L64);
    MC(WDNS_TYPE_LP);
    MC(WDNS_TYPE_EUI48);
    MC(WDNS_TYPE_EUI64);

    MC(WDNS_TYPE_TKEY);
    MC(WDNS_TYPE_TSIG);
    MC(WDNS_TYPE_IXFR);
    MC(WDNS_TYPE_AXFR);
    MC(WDNS_TYPE_MAILB);
    MC(WDNS_TYPE_MAILA);
    MC(WDNS_TYPE_ANY);
    MC(WDNS_TYPE_URI);
    MC(WDNS_TYPE_CAA);
    MC(WDNS_TYPE_TA);
    MC(WDNS_TYPE_DLV);
}

size_t
len_name(sv_name)
    SV  *sv_name
    PREINIT:
    uint8_t    *name;
    STRLEN      name_len;
    wdns_res    res;
    const char *rstr;
    CODE:
    name = (void *)SvPV(sv_name, name_len);
    res = wdns_len_uname(name, name + name_len, &RETVAL);
    if (res != wdns_res_success) {
        rstr = wdns_res_to_str(res);
        croak("problem determining name length (err %d: %s)", (int)res, rstr);
    }
    OUTPUT:
    RETVAL

void
reverse_name(sv_name)
    SV  *sv_name
    PREINIT:
    uint8_t    *name;
    STRLEN      name_len;
    size_t      sz;
    wdns_res    res;
    const char *rstr;
    char        rev[WDNS_MAXLEN_NAME];
    PPCODE:
    name = (void *)SvPV(sv_name, name_len);
    res = wdns_len_uname(name, name + name_len, &sz);
    if (res != wdns_res_success) {
        rstr = wdns_res_to_str(res);
        croak("problem determining name length (err %d: %s)", (int)res, rstr);
    }
    res = wdns_reverse_name(name, sz, rev);
    if (res != wdns_res_success) {
        rstr = wdns_res_to_str(res);
        croak("problem reversing name (err %d: %s)", (int)res, rstr);
    }
    mXPUSHs(newSVpvn(rev, sz));

void
left_chop(sv_name)
    SV *sv_name
    PREINIT:
    STRLEN       name_len;
    wdns_name_t  chop;
    wdns_name_t  name;
    size_t       sz;
    wdns_res     res;
    const char  *rstr;
    PPCODE:
    name.data = (void *)SvPV(sv_name, name_len);
    name.len  = name_len;
    res = wdns_len_uname(name.data, name.data + name.len, &sz);
    if (res != wdns_res_success) {
        rstr = wdns_res_to_str(res);
        croak("problem determining name length (err %d: %s)", (int)res, rstr);
    }
    res = wdns_left_chop(&name, &chop);
    if (res != wdns_res_success) {
        rstr = wdns_res_to_str(res);
        croak("problem chopping name (err %d: %s)", (int)res, rstr);
    }
    mXPUSHs(newSVpvn(chop.data, chop.len));

size_t
count_labels(sv_name)
    SV *sv_name
    PREINIT:
    STRLEN       name_len;
    wdns_name_t  name;
    size_t       sz;
    wdns_res     res;
    const char  *rstr;
    CODE:
    name.data = (void *)SvPV(sv_name, name_len);
    name.len  = name_len;
    res = wdns_len_uname(name.data, name.data + name.len, &sz);
    if (res != wdns_res_success) {
        rstr = wdns_res_to_str(res);
        croak("problem determining name length (err %d: %s)", (int)res, rstr);
    }
    res = wdns_count_labels(&name, &RETVAL);
    if (res != wdns_res_success) {
        rstr = wdns_res_to_str(res);
        croak("problem counting name labels (err %d: %s)", (int)res, rstr);
    }
    OUTPUT:
    RETVAL

bool
is_subdomain(sv_name0, sv_name1)
    SV *sv_name0
    SV *sv_name1
    PREINIT:
    wdns_name_t  name0;
    wdns_name_t  name1;
    STRLEN       name_len;
    size_t       sz;
    wdns_res     res;
    const char  *rstr;
    CODE:
    name0.data = (void *)SvPV(sv_name0, name_len);
    name0.len  = name_len;
    name1.data = (void *)SvPV(sv_name1, name_len);
    name1.len  = name_len;
    res = wdns_len_uname(name0.data, name0.data + name0.len, &sz);
    if (res != wdns_res_success) {
        rstr = wdns_res_to_str(res);
        croak("problem determining name length (err %d: %s)", (int)res, rstr);
    }
    res = wdns_len_uname(name1.data, name1.data + name1.len, &sz);
    if (res != wdns_res_success) {
        rstr = wdns_res_to_str(res);
        croak("problem determining name length (err %d: %s)", (int)res, rstr);
    }
    res = wdns_is_subdomain(&name0, &name1, &RETVAL);
    if (res != wdns_res_success) {
        rstr = wdns_res_to_str(res);
        croak("problem determining if name is subdomain (err %d: %s)",
              (int)res, rstr);
    }
    OUTPUT:
    RETVAL

const char *
wdns_opcode_to_str(dns_opcode)
    uint16_t dns_opcode

const char *
wdns_rcode_to_str(dns_rcode)
    uint16_t  dns_rcode

const char *
wdns_rrclass_to_str(dns_rrclass)
    uint16_t  dns_rrclass

uint16_t
wdns_str_to_rrclass(str)
    const char *str

const char *
wdns_rrtype_to_str(dns_rrtype)
    uint16_t  dns_rrtype

uint16_t
str_to_rcode(str)
    const char *str
    PREINIT:
    wdns_res     res;
    const char  *rstr;
    CODE:
    res = wdns_str_to_rcode(str, &RETVAL);
    if (res != wdns_res_success) {
        rstr = wdns_res_to_str(res);
        croak("problem converting string to return code (err %d: %s)",
            (int)res, rstr);
    }
    OUTPUT:
    RETVAL

void
domain_to_str(src_sv)
    SV *src_sv
    PREINIT:
    const uint8_t  *src;
    STRLEN          src_len;
    char            tgt[WDNS_PRESLEN_NAME];
    STRLEN          tgt_len;
    PPCODE:
    src = (void *)SvPV(src_sv, src_len);
    tgt_len = wdns_domain_to_str(src, src_len, tgt);
    // tgt_len is number of bytes read from source, not length of result
    if (tgt_len != 0)
        mXPUSHs(newSVpv(tgt, 0));

void
wdns_rrset_array_to_str(a, sec)
    wdns_rrset_array_t *a
    unsigned            sec
    PREINIT:
    char *str;
    PPCODE:
    str = wdns_rrset_array_to_str(a, sec);
    mXPUSHs(newSVpv(str, 0));
    Safefree(str);

void
wdns_rrset_to_str(rrset, sec)
    wdns_rrset_t *rrset
    unsigned      sec
    PREINIT:
    char *str;
    PPCODE:
    str = wdns_rrset_to_str(rrset, sec);
    mXPUSHs(newSVpv(str, 0));
    Safefree(str);

void
rr_to_str(rr, sec)
    wdns_rr_t  *rr
    unsigned    sec
    PREINIT:
    char *str;
    PPCODE:
    str = wdns_rr_to_str(rr, sec);
    mXPUSHs(newSVpv(str, 0));
    Safefree(str);

void
rdata_to_str(sv_rdata, rrtype, rrclass)
    SV       *sv_rdata
    uint16_t  rrtype
    uint16_t  rrclass
    PREINIT:
    STRLEN  rdlen;
    char   *src_str;
    char   *tgt_str;
    PPCODE:
    src_str = SvPV(sv_rdata, rdlen);
    tgt_str = wdns_rdata_to_str(src_str, (uint16_t)rdlen, rrtype, rrclass);
    mXPUSHs(newSVpv(tgt_str, 0));
    Safefree(tgt_str);

void
str_to_rdata(str, rrtype, rrclass)
    const char *str
    uint16_t    rrtype
    uint16_t    rrclass
    PREINIT:
    uint8_t    *rd;
    size_t      rdlen;
    wdns_res    res;
    const char *rstr;
    PPCODE:
    res = wdns_str_to_rdata(str, rrtype, rrclass, &rd, &rdlen);
    if (res != wdns_res_success) {
        rstr = wdns_res_to_str(res);
        croak("problem converting str to rdata (err %d: %s)", (int)res, rstr);
    }
    mXPUSHs(newSVpvn(rd, rdlen));
    Safefree(rd);

uint16_t
str_to_rrtype(src)
    char  *src
    PREINIT:
    wdns_name_t  name;
    CODE:
    RETVAL = wdns_str_to_rrtype(src);
    if (RETVAL == 0)
        croak("wdns_str_to_rrtype() failed");
    OUTPUT:
    RETVAL

void
str_to_name(src)
    char  *src
    PREINIT:
    wdns_name_t  name;
    wdns_res     res;
    const char  *rstr;
    PPCODE:
    res = wdns_str_to_name(src, &name);
    if (res != wdns_res_success) {
        rstr = wdns_res_to_str(res);
        croak("problem converting str to name (err %d: %s)", (int)res, rstr);
    }
    mXPUSHs(newSVpvn(name.data, name.len));

void
str_to_name_case(src)
    char  *src
    PREINIT:
    wdns_name_t  name;
    wdns_res     res;
    const char  *rstr;
    PPCODE:
    res = wdns_str_to_name_case(src, &name);
    if (res != wdns_res_success) {
        rstr = wdns_res_to_str(res);
        croak("problem converting str to name case (err %d: %s)",
              (int)res, rstr);
    }
    mXPUSHs(newSVpvn(name.data, name.len));

void
message_to_str(m)
    wdns_message_t *m
    PREINIT:
    char *str;
    PPCODE:
    str = wdns_message_to_str(m);
    mXPUSHs(newSVpv(str, 0));
    Safefree(str);

void
wdns_clear_message(m)
    wdns_message_t *m

wdns_message_t *
parse_message_raw(pkt)
    SV *pkt
    PREINIT:
    uint8_t        *p;
    STRLEN          len;
    wdns_message_t  m;
    wdns_res        res;
    const char     *rstr;
    CODE:
    p = SvPV(pkt, len);
    res = wdns_parse_message(&m, p, len);
    if (res != wdns_res_success) {
        rstr = wdns_res_to_str(res);
        croak("problem parsing pkt (err %d: %s)", (int)res, rstr);
    }
    RETVAL = &m;
    OUTPUT:
    RETVAL

uint16_t
get_id(m)
    wdns_message_t *m
    CODE:
    RETVAL = m->id;
    OUTPUT:
    RETVAL

uint16_t
get_flags(m)
    wdns_message_t *m
    CODE:
    RETVAL = m->flags;
    OUTPUT:
    RETVAL

uint16_t
get_rcode(m)
    wdns_message_t *m
    CODE:
    RETVAL = m->rcode;
    OUTPUT:
    RETVAL

uint16_t
get_opcode(m)
    wdns_message_t *m
    CODE:
    RETVAL = WDNS_FLAGS_OPCODE(*m);
    OUTPUT:
    RETVAL

void
get_section(m, i)
    wdns_message_t *m
    uint8_t         i
    PREINIT:
    wdns_rrset_array_t *a;
    wdns_rrset_t       *dns_rrset;
    wdns_rdata_t       *dns_rdata;
    int                 j, k;
    AV                 *section;
    AV                 *rrset;
    AV                 *rdata;
    SV                 *rd;
    SV                 *rs;
    PPCODE:
    if (i >= 4)
        croak("section out of range (0-3)");
    a = &m->sections[i];
    section = newAV();
    mXPUSHs(newRV_noinc((SV *)section));
    av_extend(section, a->n_rrsets);
    for (j = 0; j < a->n_rrsets; ++j) {
        rrset = newAV();
        rs = newRV_noinc((SV *)rrset);
        av_push(section, rs);
        dns_rrset = &a->rrsets[j];
        av_extend(rrset, 4 + dns_rrset->n_rdatas);
        av_push(rrset, newSVpvn(dns_rrset->name.data,
                                dns_rrset->name.len));
        av_push(rrset, newSVuv(dns_rrset->rrclass));
        av_push(rrset, newSVuv(dns_rrset->rrtype));
        if (i == 0) {
            sv_bless(rs, gv_stashpv("Net::WDNS::Question", TRUE));
        } else {
            av_push(rrset, newSVuv(dns_rrset->rrttl));
            for (k = 0; k < dns_rrset->n_rdatas; ++k) {
                rdata = newAV();
                rd = newRV_noinc((SV *)rdata);
                av_push(rrset, rd);
                av_extend(rdata, dns_rrset->n_rdatas + 2);
                dns_rdata = dns_rrset->rdatas[k];
                av_push(rdata, newSVpvn(dns_rdata->data, dns_rdata->len));
                av_push(rdata, newSVuv(dns_rrset->rrclass));
                av_push(rdata, newSVuv(dns_rrset->rrtype));
                sv_bless(rd, gv_stashpv("Net::WDNS::RD", TRUE));
            }
            sv_bless(rs, gv_stashpv("Net::WDNS::RR", TRUE));
        }
    }
