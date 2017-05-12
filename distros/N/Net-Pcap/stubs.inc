/*
 * stubs.inc - compatibility definitions to make this module compile in every cases
 *
 * Copyright (C) 2005, 2006 Sebastien Aperghis-Tramoni. All rights reserved.
 * 
 * This program is free software; you can redistribute it and/or modify 
 * it under the same terms as Perl itself.
 * 
 */

/* Macros and constants */
#ifndef PCAP_BUF_SIZE
#define PCAP_BUF_SIZE 1024
#endif

#ifndef MODE_CAPT
#define MODE_CAPT 0
#define MODE_STAT 1
#define MODE_MON  2
#endif

#ifndef PCAP_SRC_FILE
#define PCAP_SRC_FILE       2
#define PCAP_SRC_IFLOCAL    3
#define PCAP_SRC_IFREMOTE   4
#define PCAP_SRC_FILE_STRING    "file://"
#define PCAP_SRC_IF_STRING      "rpcap://"
#endif

#ifndef PCAP_OPENFLAG_PROMISCUOUS
#define PCAP_OPENFLAG_PROMISCUOUS       1
#define PCAP_OPENFLAG_DATATX_UDP        2
#define PCAP_OPENFLAG_NOCAPTURE_RPCAP   4
#endif
#define OPENFLAG_PROMISCUOUS       PCAP_OPENFLAG_PROMISCUOUS
#define OPENFLAG_DATATX_UDP        PCAP_OPENFLAG_DATATX_UDP
#define OPENFLAG_NOCAPTURE_RPCAP   PCAP_OPENFLAG_NOCAPTURE_RPCAP

#ifndef PCAP_SAMP_NOSAMP
#define PCAP_SAMP_NOSAMP            0
#define PCAP_SAMP_1_EVERY_N         1
#define PCAP_SAMP_FIRST_AFTER_N_MS  2
#endif

#ifndef HANDLE
#define HANDLE void *
#endif

#ifndef DWORD
#define DWORD unsigned long
#endif

#ifndef SOCKET
#ifdef WIN32
#define SOCKET unsigned int
#else
#define SOCKET int
#endif
#endif


/* Stubs for functions not available in libpcap */
#define FUNCTION_NOT_IMPLEMENTED_ERROR(func)  croak(\
        "The function " #func "() is not available in your release of the pcap library.");
#define FUNCTION_NOT_IMPLEMENTED_WARNING(func)  warn(\
        "The function " #func "() is not available in your release of the pcap library.");


#ifndef HAVE_PCAP_LIB_VERSION
#ifdef __GNUC__
#warning "the function pcap_lib_version() is not available, but will be emulated"
#endif
#ifdef _MSC_VER
#pragma message( "Warning: the function pcap_lib_version() is not available, but will be emulated" )
#endif
const char * pcap_lib_version(void);
const char * pcap_lib_version(void) {
    return "libpcap version unknown (pre 0.8)";
}
#endif


#ifndef HAVE_PCAP_FINDALLDEVS
#ifdef __GNUC__
#warning "the function pcap_findalldevs() is not available, but will be emulated"
#endif
#ifdef _MSC_VER
#pragma message( "Warning: the function pcap_findalldevs() is not available, but will be emulated" )
#endif
typedef struct pcap_if pcap_if_t;
struct pcap_if {
    struct pcap_if *next;
    char *name;     /* name to hand to "pcap_open_live()" */
    char *description;  /* textual description of interface, or NULL */
    struct pcap_addr *addresses;
    bpf_u_int32 flags;  /* PCAP_IF_ interface flags */
};

int pcap_findalldevs(pcap_if_t ** alldevsp, char * errbuf);
int pcap_findalldevs(pcap_if_t ** alldevsp, char * errbuf) {
    return 3;
}

void pcap_freealldevs(pcap_if_t * alldevsp);
void pcap_freealldevs(pcap_if_t * alldevsp) {
    return;
}
#endif


#ifndef HAVE_PCAP_BREAKLOOP
#ifdef __GNUC__
#warning "the function pcap_breakloop() is not available"
#endif
#ifdef _MSC_VER
#pragma message( "Warning: the function pcap_breakloop() is not available" )
#endif
void pcap_breakloop(pcap_t * p);
void pcap_breakloop(pcap_t * p) {
    FUNCTION_NOT_IMPLEMENTED_WARNING(pcap_breakloop)
}
#endif


#ifndef HAVE_PCAP_SETNONBLOCK
#ifdef __GNUC__
#warning "the function pcap_setnonblock() is not available"
#endif
#ifdef _MSC_VER
#pragma message( "Warning: the function pcap_setnonblock() is not available" )
#endif
int pcap_setnonblock(pcap_t * p, int nonblock, char * errbuf);
int pcap_setnonblock(pcap_t * p, int nonblock, char * errbuf) {
    FUNCTION_NOT_IMPLEMENTED_WARNING(pcap_setnonblock)
    return -1;
}
#endif


#ifndef HAVE_PCAP_GETNONBLOCK
#ifdef __GNUC__
#warning "the function pcap_getnonblock() is not available"
#endif
#ifdef _MSC_VER
#pragma message( "Warning: the function pcap_getnonblock() is not available" )
#endif
int pcap_getnonblock(pcap_t * p, char * errbuf);
int pcap_getnonblock(pcap_t * p, char * errbuf) {
    FUNCTION_NOT_IMPLEMENTED_WARNING(pcap_getnonblock)
    return -1;
}
#endif


#ifndef HAVE_PCAP_DUMP_FILE
#ifdef __GNUC__
#warning "the function pcap_dump_file() is not available"
#endif
#ifdef _MSC_VER
#pragma message( "Warning: the function pcap_dump_file() is not available" )
#endif
FILE *pcap_dump_file(pcap_dumper_t *p);
FILE *pcap_dump_file(pcap_dumper_t *p) {
    FUNCTION_NOT_IMPLEMENTED_ERROR(pcap_dump_file)
    return NULL;
}
#endif


#ifndef HAVE_PCAP_DUMP_FLUSH
#ifdef __GNUC__
#warning "the function pcap_dump_flush() is not available"
#endif
#ifdef _MSC_VER
#pragma message( "Warning: the function pcap_dump_flush() is not available" )
#endif
int pcap_dump_flush(pcap_dumper_t *p);
int pcap_dump_flush(pcap_dumper_t *p) {
    FUNCTION_NOT_IMPLEMENTED_ERROR(pcap_dump_flush)
    return -1;
}
#endif


#ifndef HAVE_PCAP_LIST_DATALINKS
#ifdef __GNUC__
#warning "the function pcap_list_datalinks() is not available"
#endif
#ifdef _MSC_VER
#pragma message( "Warning: the function pcap_list_datalinks() is not available" )
#endif
int pcap_list_datalinks(pcap_t *p, int **dlt_buf);
int pcap_list_datalinks(pcap_t *p, int **dlt_buf) {
    FUNCTION_NOT_IMPLEMENTED_ERROR(pcap_list_datalinks)
    return -1;
}
#endif


#ifndef HAVE_PCAP_SET_DATALINK
#ifdef __GNUC__
#warning "the function pcap_set_datalink() is not available"
#endif
#ifdef _MSC_VER
#pragma message( "Warning: the function pcap_set_datalink() is not available" )
#endif
int pcap_set_datalink(pcap_t * p, int datalink);
int pcap_set_datalink(pcap_t * p, int datalink) {
    FUNCTION_NOT_IMPLEMENTED_ERROR(pcap_set_datalink)
    return -1;
}
#endif


#ifndef HAVE_PCAP_DATALINK_NAME_TO_VAL
#ifdef __GNUC__
#warning "the function pcap_datalink_name_to_val() is not available"
#endif
#ifdef _MSC_VER
#pragma message( "Warning: the function pcap_datalink_name_to_val() is not available" )
#endif
int pcap_datalink_name_to_val(const char * name);
int pcap_datalink_name_to_val(const char * name) {
    FUNCTION_NOT_IMPLEMENTED_ERROR(pcap_datalink_name_to_val)
    return -1;
}
#endif


#ifndef HAVE_PCAP_DATALINK_VAL_TO_NAME
#ifdef __GNUC__
#warning "the function pcap_datalink_val_to_name() is not available"
#endif
#ifdef _MSC_VER
#pragma message( "Warning: the function pcap_datalink_val_to_name() is not available" )
#endif
const char * pcap_datalink_val_to_name(int datalink);
const char * pcap_datalink_val_to_name(int datalink) {
    FUNCTION_NOT_IMPLEMENTED_ERROR(pcap_datalink_val_to_name)
    return "";
}
#endif


#ifndef HAVE_PCAP_DATALINK_VAL_TO_DESCRIPTION
#ifdef __GNUC__
#warning "the function pcap_datalink_val_to_description() is not available"
#endif
#ifdef _MSC_VER
#pragma message( "Warning: the function pcap_datalink_val_to_description() is not available" )
#endif
const char * pcap_datalink_val_to_description(int datalink);
const char * pcap_datalink_val_to_description(int datalink) {
    FUNCTION_NOT_IMPLEMENTED_ERROR(pcap_datalink_val_to_description)
    return "";
}
#endif


#ifndef HAVE_PCAP_COMPILE_NOPCAP
#ifdef __GNUC__
#warning "the function pcap_compile_nopcap() is not available"
#endif
#ifdef _MSC_VER
#pragma message( "Warning: the function pcap_compile_nopcap() is not available" )
#endif
int pcap_compile_nopcap(int snaplen, int linktype, struct bpf_program *fp, char *str, int optimize, bpf_u_int32 netmask);
int pcap_compile_nopcap(int snaplen, int linktype, struct bpf_program *fp, char *str, int optimize, bpf_u_int32 netmask) {
    FUNCTION_NOT_IMPLEMENTED_ERROR(pcap_compile_nopcap)
    return -1;
}
#endif


#ifndef HAVE_PCAP_GET_SELECTABLE_FD
#ifdef __GNUC__
#warning "the function pcap_get_selectable_fd() is not available"
#endif
#ifdef _MSC_VER
#pragma message( "Warning: the function pcap_get_selectable_fd() is not available" )
#endif
int pcap_get_selectable_fd(pcap_t *p);
int pcap_get_selectable_fd(pcap_t *p) {
    FUNCTION_NOT_IMPLEMENTED_ERROR(pcap_get_selectable_fd)
    return -1;
}
#endif


#ifndef HAVE_PCAP_NEXT_EX
#ifdef __GNUC__
#warning "the function pcap_next_ex() is not available"
#endif
#ifdef _MSC_VER
#pragma message( "Warning: the function pcap_next_ex() is not available" )
#endif
int pcap_next_ex(pcap_t *p, struct pcap_pkthdr **pkt_header, const u_char **pkt_data);
int pcap_next_ex(pcap_t *p, struct pcap_pkthdr **pkt_header, const u_char **pkt_data) {
    FUNCTION_NOT_IMPLEMENTED_ERROR(pcap_next_ex)
    return -1;
}
#endif


#ifndef HAVE_PCAP_SENDPACKET
#ifdef __GNUC__
#warning "the function pcap_sendpacket() is not available"
#endif
#ifdef _MSC_VER
#pragma message( "Warning: the function pcap_sendpacket() is not available" )
#endif
int pcap_sendpacket(pcap_t *p, const u_char *buf, int size);
int pcap_sendpacket(pcap_t *p, const u_char *buf, int size) {
    FUNCTION_NOT_IMPLEMENTED_ERROR(pcap_sendpacket)
    return -1;
}
#endif


#ifndef HAVE_PCAP_CREATESRCSTR
#ifdef __GNUC__
#warning "the function pcap_createsrcstr() is not available"
#endif
#ifdef _MSC_VER
#pragma message( "Warning: the function pcap_createsrcstr() is not available" )
#endif
int pcap_createsrcstr(char *source, int type, const char *host, const char *port, const char *name, char *err);
int pcap_createsrcstr(char *source, int type, const char *host, const char *port, const char *name, char *err) {
    FUNCTION_NOT_IMPLEMENTED_ERROR(pcap_createsrcstr)
    return -1;
}
#endif


#ifndef HAVE_PCAP_PARSESRCSTR
#ifdef __GNUC__
#warning "the function pcap_parsesrcstr() is not available"
#endif
#ifdef _MSC_VER
#pragma message( "Warning: the function pcap_parsesrcstr() is not available" )
#endif
int pcap_parsesrcstr(const char *source, int *type, char *host, char *port, char *name, char *err);
int pcap_parsesrcstr(const char *source, int *type, char *host, char *port, char *name, char *err) {
    FUNCTION_NOT_IMPLEMENTED_ERROR(pcap_parsesrcstr)
    return -1;
}
#endif


#ifndef HAVE_PCAP_OPEN
#ifdef __GNUC__
#warning "the function pcap_open() is not available"
#endif
#ifdef _MSC_VER
#pragma message( "Warning: the function pcap_open() is not available" )
#endif
struct pcap_rmtauth {
    int type;
    char *username;
    char *password;
};

pcap_t * pcap_open(const char *source, int snaplen, int flags, int read_timeout, struct pcap_rmtauth *auth, char *err);
pcap_t * pcap_open(const char *source, int snaplen, int flags, int read_timeout, struct pcap_rmtauth *auth, char *err) {
    FUNCTION_NOT_IMPLEMENTED_ERROR(pcap_open)
    return NULL;
}
#endif


#ifndef HAVE_PCAP_SETBUFF
#ifdef __GNUC__
#warning "the function pcap_setbuff() is not available"
#endif
#ifdef _MSC_VER
#pragma message( "Warning: the function pcap_setbuff() is not available" )
#endif
int pcap_setbuff(pcap_t *p, int dim);
int pcap_setbuff(pcap_t *p, int dim) {
    FUNCTION_NOT_IMPLEMENTED_ERROR(pcap_setbuff)
    return -1;
}
#endif


#ifndef HAVE_PCAP_SETUSERBUFFER
#ifdef __GNUC__
#warning "the function pcap_setuserbuffer() is not available"
#endif
#ifdef _MSC_VER
#pragma message( "Warning: the function pcap_setuserbuffer() is not available" )
#endif
int pcap_setuserbuffer(pcap_t *p, int size);
int pcap_setuserbuffer(pcap_t *p, int size) {
    FUNCTION_NOT_IMPLEMENTED_ERROR(pcap_setuserbuffer)
    return -1;
}
#endif


#ifndef HAVE_PCAP_SETMODE
#ifdef __GNUC__
#warning "the function pcap_setmode() is not available"
#endif
#ifdef _MSC_VER
#pragma message( "Warning: the function pcap_setmode() is not available" )
#endif
int pcap_setmode(pcap_t *p, int mode);
int pcap_setmode(pcap_t *p, int mode) {
    FUNCTION_NOT_IMPLEMENTED_ERROR(pcap_setmode)
    return -1;
}
#endif


#ifndef HAVE_PCAP_SETMINTOCOPY
#ifdef __GNUC__
#warning "the function pcap_setmintocopy() is not available"
#endif
#ifdef _MSC_VER
#pragma message( "Warning: the function pcap_setmintocopy() is not available" )
#endif
int pcap_setmintocopy(pcap_t *p, int size);
int pcap_setmintocopy(pcap_t *p, int size) {
    FUNCTION_NOT_IMPLEMENTED_ERROR(pcap_setmintocopy)
    return -1;
}
#endif


#ifndef HAVE_PCAP_SENDQUEUE_ALLOC
#ifdef __GNUC__
#warning "the function pcap_sendqueue_alloc() is not available"
#endif
#ifdef _MSC_VER
#pragma message( "Warning: the function pcap_sendqueue_alloc() is not available" )
#endif
struct pcap_send_queue{
    u_int maxlen;
    u_int len;
    char *buffer;
};

typedef struct pcap_send_queue pcap_send_queue;

pcap_send_queue * pcap_sendqueue_alloc(u_int memsize);
pcap_send_queue * pcap_sendqueue_alloc(u_int memsize) {
    FUNCTION_NOT_IMPLEMENTED_ERROR(pcap_sendqueue_alloc)
}
#endif


#ifndef HAVE_PCAP_SENDQUEUE_DESTROY
#ifdef __GNUC__
#warning "the function pcap_sendqueue_destroy() is not available"
#endif
#ifdef _MSC_VER
#pragma message( "Warning: the function pcap_sendqueue_destroy() is not available" )
#endif
void pcap_sendqueue_destroy(pcap_send_queue *queue);
void pcap_sendqueue_destroy(pcap_send_queue *queue) {
    FUNCTION_NOT_IMPLEMENTED_ERROR(pcap_sendqueue_destroy)
}
#endif


#ifndef HAVE_PCAP_SENDQUEUE_QUEUE
#ifdef __GNUC__
#warning "the function pcap_sendqueue_queue() is not available"
#endif
#ifdef _MSC_VER
#pragma message( "Warning: the function pcap_sendqueue_queue() is not available" )
#endif
int pcap_sendqueue_queue(pcap_send_queue *queue, const struct pcap_pkthdr *pkt_header, const u_char *pkt_data);
int pcap_sendqueue_queue(pcap_send_queue *queue, const struct pcap_pkthdr *pkt_header, const u_char *pkt_data) {
    FUNCTION_NOT_IMPLEMENTED_ERROR(pcap_sendqueue_queue)
    return -1;
}
#endif


#ifndef HAVE_PCAP_SENDQUEUE_TRANSMIT
#ifdef __GNUC__
#warning "the function pcap_sendqueue_transmit() is not available"
#endif
#ifdef _MSC_VER
#pragma message( "Warning: the function pcap_sendqueue_transmit() is not available" )
#endif
u_int pcap_sendqueue_transmit(pcap_t *p, pcap_send_queue *queue, int sync);
u_int pcap_sendqueue_transmit(pcap_t *p, pcap_send_queue *queue, int sync) {
    FUNCTION_NOT_IMPLEMENTED_ERROR(pcap_sendqueue_transmit)
    return 0;
}
#endif


#ifndef HAVE_PCAP_GETEVENT
#ifdef __GNUC__
#warning "the function pcap_event() is not available"
#endif
#ifdef _MSC_VER
#pragma message( "Warning: the function pcap_event() is not available" )
#endif
HANDLE pcap_getevent(pcap_t *p);
HANDLE pcap_getevent(pcap_t *p) {
    FUNCTION_NOT_IMPLEMENTED_ERROR(pcap_event)
    return 0;
}
#endif


#ifndef HAVE_PCAP_SETSAMPLING
#ifdef __GNUC__
#warning "the function pcap_setsampling() is not available"
#endif
#ifdef _MSC_VER
#pragma message( "Warning: the function pcap_setsampling() is not available" )
#endif
struct pcap_samp {
    int method;
    int value;
};

struct pcap_samp *pcap_setsampling(pcap_t *p);
struct pcap_samp *pcap_setsampling(pcap_t *p) {
    FUNCTION_NOT_IMPLEMENTED_ERROR(pcap_setsampling)
    return NULL;
}
#endif


/*

int pcap_live_dump(pcap_t *p, char *filename, int maxsize, int maxpacks);
int pcap_live_dump_ended(pcap_t *p, int sync);
int pcap_offline_filter(struct bpf_program *prog, const struct pcap_pkthdr *header, const u_char *pkt_data);

struct pcap_rmtauth {
    int type;
    char *username;
    char *password;
};
SOCKET pcap_remoteact_accept(const char *address, const char *port, const char *hostlist, char *connectinghost, struct pcap_rmtauth *auth, char *errbuf);
int pcap_remoteact_list(char *hostlist, char sep, int size, char *errbuf);
int pcap_remoteact_close(const char *host, char *errbuf);
void pcap_remoteact_cleanup();


*/
