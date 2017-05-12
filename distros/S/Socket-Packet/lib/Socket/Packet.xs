/*  You may distribute under the terms of either the GNU General Public License
 *  or the Artistic License (the same terms as Perl itself)
 *
 *  (C) Paul Evans, 2009,2010 -- leonerd@leonerd.org.uk
 */

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <sys/mman.h>
#include <sys/socket.h>
#include <net/ethernet.h>
#include <linux/if.h>
#include <linux/if_packet.h>

/* Borrowed from IO/Sockatmark.xs */

#ifdef PerlIO
typedef PerlIO * InputStream;
#else
#define PERLIO_IS_STDIO 1
typedef FILE * InputStream;
#define PerlIO_fileno(f) fileno(f)
#endif

/* Lower and upper bounds of a valid struct sockaddr_ll */
static int sll_max;
static int sll_min;
/* Maximum number of address bytes in a struct sockaddr_ll */
static int sll_maxaddr;

#ifndef PUSHmortal
# define PUSHmortal PUSHs(sv_newmortal())
#endif

#ifndef mPUSHi
# define mPUSHi(iv) sv_setiv(PUSHmortal, iv)
#endif

#ifndef mPUSHn
# define mPUSHn(nv) sv_setnv(PUSHmortal, nv)
#endif

#ifndef mPUSHp
# define mPUSHp(p,l) sv_setpvn(PUSHmortal, p, l)
#endif

#define HVSTOREi(hv,name,iv)     sv_setiv(*hv_fetch(hv, ""name"", sizeof(""name"")-1, 1), iv)
#define HVSTOREp(hv,name,pv,len) sv_setpvn(*hv_fetch(hv, ""name"", sizeof(""name"")-1, 1), pv, len)

#if defined(HAVE_TPACKET) || defined(HAVE_TPACKET2)
# define HAVE_RX_RING
static int free_rxring_state(pTHX_ SV *, MAGIC *);

static MGVTBL vtbl = {
  NULL, /* get */
  NULL, /* set */
  NULL, /* len */
  NULL, /* clear */
  &free_rxring_state, /* free */
};

struct packet_rxring_state
{
  char *buffer;
  unsigned int frame_size;
  unsigned int frame_nr;
  unsigned int frame_idx;
};

static int free_rxring_state(pTHX_ SV *sv, MAGIC *mg)
{
  free(mg->mg_ptr);
  return 0;
}

static struct packet_rxring_state *get_rxring_state(SV *sv)
{
  MAGIC *magic;

  for(magic = mg_find(sv, PERL_MAGIC_ext); magic; magic = magic->mg_moremagic) {
    if(magic->mg_type == PERL_MAGIC_ext && magic->mg_virtual == &vtbl) {
      return (struct packet_rxring_state *)magic->mg_ptr;
    }
  }

  croak("Cannot find rxring state - call setup_rx_ring() first");
}

static void *frame_ptr(struct packet_rxring_state *state)
{
  return state->buffer + (state->frame_size * state->frame_idx);
}
#endif

static void setup_constants(void)
{
  sll_max = sizeof(struct sockaddr_ll);
  sll_maxaddr = sizeof(((struct sockaddr_ll*)NULL)->sll_addr);
  sll_min = sll_max - sll_maxaddr;

  HV *stash;
  AV *export;

  stash = gv_stashpvn("Socket::Packet", 14, TRUE);
  export = get_av("Socket::Packet::EXPORT", TRUE);

#define DO_CONSTANT(c) \
  newCONSTSUB(stash, #c, newSViv(c)); \
  av_push(export, newSVpv(#c, 0));


  DO_CONSTANT(PF_PACKET)
  DO_CONSTANT(AF_PACKET)

  DO_CONSTANT(PACKET_HOST)
  DO_CONSTANT(PACKET_BROADCAST)
  DO_CONSTANT(PACKET_MULTICAST)
  DO_CONSTANT(PACKET_OTHERHOST)
  DO_CONSTANT(PACKET_OUTGOING)

  DO_CONSTANT(ETH_P_ALL)

  DO_CONSTANT(SOL_PACKET)

  DO_CONSTANT(PACKET_ADD_MEMBERSHIP)
  DO_CONSTANT(PACKET_DROP_MEMBERSHIP)
  DO_CONSTANT(PACKET_STATISTICS)
#ifdef HAVE_ORIGDEV
  DO_CONSTANT(PACKET_ORIGDEV)
#endif

  DO_CONSTANT(PACKET_MR_MULTICAST)
  DO_CONSTANT(PACKET_MR_PROMISC)
  DO_CONSTANT(PACKET_MR_ALLMULTI)

#ifdef HAVE_RX_RING
  DO_CONSTANT(TP_STATUS_KERNEL)
  DO_CONSTANT(TP_STATUS_USER)
  DO_CONSTANT(TP_STATUS_COPY)
  DO_CONSTANT(TP_STATUS_LOSING)
  DO_CONSTANT(TP_STATUS_CSUMNOTREADY)
#endif
}

MODULE = Socket::Packet    PACKAGE = Socket::Packet

BOOT:
  setup_constants();

void
pack_sockaddr_ll(protocol, ifindex, hatype, pkttype, addr)
    unsigned short  protocol
             int    ifindex
    unsigned short  hatype
    unsigned char   pkttype
    SV             *addr

  PREINIT:
    struct sockaddr_ll sll;
    char *addrbytes;
    STRLEN addrlen;

  PPCODE:
    if (DO_UTF8(addr) && !sv_utf8_downgrade(addr, 1))
      croak("Wide character in Socket::Packet::pack_sockaddr_ll");

    addrbytes = SvPVbyte(addr, addrlen);

    if(addrlen > sll_maxaddr)
      croak("addr too long; should be no more than %d bytes, found %d", sll_maxaddr, addrlen);

    sll.sll_family   = AF_PACKET;
    sll.sll_protocol = htons(protocol);
    sll.sll_ifindex  = ifindex;
    sll.sll_hatype   = hatype;
    sll.sll_pkttype  = pkttype;

    sll.sll_halen    = addrlen;
    Zero(&sll.sll_addr, sll_maxaddr, char);
    Copy(addrbytes, &sll.sll_addr, addrlen, char);

    EXTEND(SP, 1);
    mPUSHp((char *)&sll, sizeof sll);

void
unpack_sockaddr_ll(sa)
    SV * sa

  PREINIT:
    STRLEN sa_len;
    char *sa_bytes;
    struct sockaddr_ll sll;

  PPCODE:
    /* variable size of structure, because of variable length of addr bytes */
    sa_bytes = SvPVbyte(sa, sa_len);
    if(sa_len < sll_min)
      croak("Socket address too small; found %d bytes, expected at least %d", sa_len, sll_min);
    if(sa_len > sll_max)
      croak("Socket address too big; found %d bytes, expected at most %d", sa_len, sll_max);

    Copy(sa_bytes, &sll, sizeof sll, char);

    if(sa_len < sll_min + sll.sll_halen)
      croak("Socket address too small; it did not provide enough bytes for sll_halen of %d", sll.sll_halen);

    if(sll.sll_family != AF_PACKET)
      croak("Bad address family for unpack_sockaddr_ll: got %d, expected %d", sll.sll_family, AF_PACKET);

    EXTEND(SP, 5);
    mPUSHi(ntohs(sll.sll_protocol));
    mPUSHi(sll.sll_ifindex);
    mPUSHi(sll.sll_hatype);
    mPUSHi(sll.sll_pkttype);
    mPUSHp((char *)sll.sll_addr, sll.sll_halen);

void
pack_packet_mreq(ifindex, type, addr)
    int            ifindex
    unsigned short type
    SV *           addr

  PREINIT:
    struct packet_mreq mreq;
    char  *addr_bytes;
    STRLEN addr_len;

  PPCODE:
    if (DO_UTF8(addr) && !sv_utf8_downgrade(addr, 1))
      croak("Wide character in Socket::Packet::pack_sockaddr_ll");

    addr_bytes = SvPVbyte(addr, addr_len);

    if(addr_len > sizeof(mreq.mr_address))
      croak("addr too long; should be no more than %d bytes, found %d", sizeof(mreq.mr_address), addr_len);

    mreq.mr_ifindex = ifindex;
    mreq.mr_type    = type;

    mreq.mr_alen = addr_len;
    Zero(&mreq.mr_address, sizeof(mreq.mr_address), char);
    Copy(addr_bytes, &mreq.mr_address, addr_len, char);

    EXTEND(SP, 1);
    mPUSHp((char *)&mreq, sizeof mreq);

void
unpack_packet_mreq(data)
    SV * data

  PREINIT:
    STRLEN data_len;
    char *data_bytes;
    struct packet_mreq mreq;

  PPCODE:
    data_bytes = SvPVbyte(data, data_len);
    if(data_len != sizeof(mreq))
      croak("packet_mreq buffer incorrect size; found %d bytes, expected %d", data_len, sizeof(mreq));

    Copy(data_bytes, &mreq, data_len, char);

    if(mreq.mr_alen > sizeof(mreq.mr_address))
      croak("packet_mreq claims to have a larger address than it has space for");

    EXTEND(SP, 3);
    mPUSHi(mreq.mr_ifindex);
    mPUSHi(mreq.mr_type);
    mPUSHp(mreq.mr_address, mreq.mr_alen);

void
unpack_tpacket_stats(stats)
    SV * stats

  PREINIT:
    STRLEN stats_len;
    char *stats_bytes;
    struct tpacket_stats statsbuf;

  PPCODE:
    stats_bytes = SvPVbyte(stats, stats_len);
    if(stats_len != sizeof(statsbuf))
      croak("tpacket_stats buffer incorrect size; found %d bytes, expected %d", stats_len, sizeof(statsbuf));

    Copy(stats_bytes, &statsbuf, stats_len, char);

    EXTEND(SP, 5);
    mPUSHi(statsbuf.tp_packets);
    mPUSHi(statsbuf.tp_drops);

void
siocgstamp(sock)
  InputStream sock
  PROTOTYPE: $

  PREINIT:
    int fd;
    int result;
    struct timeval tv;

  PPCODE:
    fd = PerlIO_fileno(sock);
    if(ioctl(fd, SIOCGSTAMP, &tv) == -1) {
      if(GIMME_V == G_ARRAY)
        return;
      else
        XSRETURN_UNDEF;
    }

    if(GIMME_V == G_ARRAY) {
      EXTEND(SP, 2);
      mPUSHi(tv.tv_sec);
      mPUSHi(tv.tv_usec);
    }
    else {
      mPUSHn((double)tv.tv_sec + (tv.tv_usec / 1000000.0));
    }

void
siocgstampns(sock)
  InputStream sock
  PROTOTYPE: $

  PREINIT:
    int fd;
    int result;
    struct timespec ts;

  PPCODE:
#ifdef SIOCGSTAMPNS
    fd = PerlIO_fileno(sock);
    if(ioctl(fd, SIOCGSTAMPNS, &ts) == -1) {
      if(GIMME_V == G_ARRAY)
        return;
      else
        XSRETURN_UNDEF;
    }

    if(GIMME_V == G_ARRAY) {
      EXTEND(SP, 2);
      mPUSHi(ts.tv_sec);
      mPUSHi(ts.tv_nsec);
    }
    else {
      mPUSHn((double)ts.tv_sec + (ts.tv_nsec / 1000000000.0));
    }
#else
    croak("SIOCGSTAMPNS not implemented");
#endif

void
siocgifindex(sock, ifname)
  InputStream sock
  char *ifname
  PROTOTYPE: $$

  PREINIT:
    int fd;
    struct ifreq req;

  PPCODE:
#ifdef SIOCGIFINDEX
    fd = PerlIO_fileno(sock);
    strncpy(req.ifr_name, ifname, IFNAMSIZ);
    if(ioctl(fd, SIOCGIFINDEX, &req) == -1)
      XSRETURN_UNDEF;
    mPUSHi(req.ifr_ifindex);
#else
    croak("SIOCGIFINDEX not implemented");
#endif

void
siocgifname(sock, ifindex)
  InputStream sock
  int ifindex
  PROTOTYPE: $$

  PREINIT:
    int fd;
    struct ifreq req;

  PPCODE:
#ifdef SIOCGIFNAME
    fd = PerlIO_fileno(sock);
    req.ifr_ifindex = ifindex;
    if(ioctl(fd, SIOCGIFNAME, &req) == -1)
      XSRETURN_UNDEF;
    PUSHs(sv_2mortal(newSVpv(req.ifr_name, 0)));
#else
    croak("SIOCGIFNAME not implemented");
#endif

void
recv_len(sock, buffer, maxlen, flags)
    InputStream sock
    SV *buffer
    int maxlen
    int flags

  PREINIT:
    int fd;
    char *bufferp;
    struct sockaddr_storage addr;
    socklen_t addrlen;
    int len;

  PPCODE:
    fd = PerlIO_fileno(sock);

    if(!SvOK(buffer))
      sv_setpvn(buffer, "", 0);

    bufferp = SvGROW(buffer, (STRLEN)(maxlen+1));

    addrlen = sizeof(addr);

    len = recvfrom(fd, bufferp, maxlen, flags, (struct sockaddr *)&addr, &addrlen);

    if(len < 0)
      XSRETURN(0);

    if(len > maxlen)
      SvCUR_set(buffer, maxlen);
    else
      SvCUR_set(buffer, len);

    *SvEND(buffer) = '\0';
    SvPOK_only(buffer);

    mPUSHp((char *)&addr, addrlen);
    mPUSHi(len);

void
setup_rx_ring(sock, frame_size, frame_nr, block_size)
    InputStream sock
    unsigned int frame_size
    unsigned int frame_nr
    unsigned int block_size

  PREINIT:
    int fd;
    int version;
    struct tpacket_req req;
    size_t size;
    char *addr;

  PPCODE:
#ifdef HAVE_RX_RING
    fd = PerlIO_fileno(sock);
#ifdef HAVE_TPACKET2
    version = TPACKET_V2;
    if(setsockopt(fd, SOL_PACKET, PACKET_VERSION, &version, sizeof version) != 0)
      XSRETURN_UNDEF;
#endif

    {
      struct tpacket_req req;
      req.tp_frame_size = frame_size;
      req.tp_frame_nr   = frame_nr;
      req.tp_block_size = block_size;
      req.tp_block_nr   = (frame_size * frame_nr) / block_size;
      if(setsockopt(fd, SOL_PACKET, PACKET_RX_RING, &req, sizeof req) != 0)
        XSRETURN_UNDEF;

      size = req.tp_block_size * req.tp_block_nr;
    }

    addr = mmap(0, size, PROT_READ|PROT_WRITE, MAP_SHARED, fd, 0);
    if(addr == MAP_FAILED)
      XSRETURN_UNDEF;

    {
      struct packet_rxring_state *state = malloc(sizeof *state);

      state->buffer     = addr;
      state->frame_size = frame_size;
      state->frame_nr   = frame_nr;
      state->frame_idx  = 0;

      sv_magicext((SV*)sv_2io(ST(0)), NULL, PERL_MAGIC_ext, &vtbl, (char *)state, 0);
    }

    ST(0) = sv_2mortal(newSViv(size));
    XSRETURN(1);
#else
    croak("setup_rx_ring() not supported on this platform");
#endif

void
get_ring_frame_status(sock)
    InputStream sock
  PPCODE:
#ifdef HAVE_RX_RING
    {
      struct packet_rxring_state *state = get_rxring_state((SV*)sv_2io(ST(0)));
      char *addr = frame_ptr(state);
#if defined(HAVE_TPACKET2)
      struct tpacket2_hdr *hdr = (struct tpacket2_hdr *)addr;
#elif defined(HAVE_TPACKET)
      struct tpacket_hdr *hdr = (struct tpacket_hdr *)addr;
#endif
      ST(0) = sv_2mortal(newSViv(hdr->tp_status));
    }

    XSRETURN(1);
#else
    croak("get_ring_frame_status() not supported on this platform");
#endif

void
get_ring_frame(sock, buffer, info)
    InputStream sock
    SV *buffer
    HV *info

  PREINIT:

  PPCODE:
#ifdef HAVE_RX_RING
    {
      struct packet_rxring_state *state = get_rxring_state((SV*)sv_2io(ST(0)));
      char *addr = frame_ptr(state);
      unsigned int len;
      unsigned int snaplen;
      int mac;
      struct sockaddr_ll  *sll;
#if defined(HAVE_TPACKET2)
      struct tpacket2_hdr *hdr = (struct tpacket2_hdr *)addr;
      if((hdr->tp_status & 1) != 1)
        XSRETURN(0);

      len     = hdr->tp_len;
      snaplen = hdr->tp_snaplen;
      mac     = hdr->tp_mac;

      HVSTOREi(info, "tp_status",   hdr->tp_status);
      HVSTOREi(info, "tp_len",      hdr->tp_len);
      HVSTOREi(info, "tp_snaplen",  hdr->tp_snaplen);
      HVSTOREi(info, "tp_sec",      hdr->tp_sec);
      HVSTOREi(info, "tp_nsec",     hdr->tp_nsec);
      HVSTOREi(info, "tp_vlan_tci", hdr->tp_vlan_tci);

      sll = (struct sockaddr_ll *)(addr + TPACKET_ALIGN(sizeof(struct tpacket2_hdr)));
#elif defined(HAVE_TPACKET)
      struct tpacket_hdr *hdr = (struct tpacket_hdr *)addr;
      if((hdr->tp_status & 1) != 1)
        XSRETURN(0);

      len     = hdr->tp_len;
      snaplen = hdr->tp_snaplen;
      mac     = hdr->tp_mac;

      HVSTOREi(info, "tp_status",   hdr->tp_status);
      HVSTOREi(info, "tp_len",      hdr->tp_len);
      HVSTOREi(info, "tp_snaplen",  hdr->tp_snaplen);
      HVSTOREi(info, "tp_sec",      hdr->tp_sec);
      HVSTOREi(info, "tp_nsec",     hdr->tp_usec * 1000);

      sll = (struct sockaddr_ll *)(addr + TPACKET_ALIGN(sizeof(struct tpacket_hdr)));
#endif
      HVSTOREi(info, "sll_protocol", ntohs(sll->sll_protocol));
      HVSTOREi(info, "sll_ifindex",  sll->sll_ifindex);
      HVSTOREi(info, "sll_hatype",   sll->sll_hatype);
      HVSTOREi(info, "sll_pkttype",  sll->sll_pkttype);
      HVSTOREp(info, "sll_addr",     sll->sll_addr, sll->sll_halen);

      /* Alias, don't copy data - we like zero-copy */
      SvUPGRADE(buffer, SVt_PV);
      SvPVX(buffer) = addr + mac;
      SvCUR_set(buffer, snaplen);
      SvLEN_set(buffer, 0);
      SvPOK_only(buffer);

      sv_setiv(ST(0), len);
      XSRETURN(1);
    }
#else
    croak("get_ring_frame() not supported on this platform");
#endif

void
done_ring_frame(sock)
    InputStream sock
  PPCODE:
#ifdef HAVE_RX_RING
    {
      struct packet_rxring_state *state = get_rxring_state((SV*)sv_2io(ST(0)));
      char *addr = frame_ptr(state);
#if defined(HAVE_TPACKET2)
      struct tpacket2_hdr *hdr = (struct tpacket2_hdr *)addr;
#elif defined(HAVE_TPACKET)
      struct tpacket_hdr *hdr = (struct tpacket_hdr *)addr;
#endif
      hdr->tp_status = TP_STATUS_KERNEL;

      state->frame_idx = (state->frame_idx + 1) % state->frame_nr;
    }

    XSRETURN(0);
#else
    croak("done_ring_frame() not supported on this platform");
#endif
