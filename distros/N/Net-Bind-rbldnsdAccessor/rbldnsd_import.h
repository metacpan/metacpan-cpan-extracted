/*	rbldnsd_import.h	*/

#ifndef RBLDNSD_IMPORT_H
#define RBLDNSD_IMPORT_H 1

/*	from rbldnsd.c		*/
int rblf_do_reload(void);
struct zone **fetchzonelist(void);

/*	from rbldnsd_packet.c	*/
int rblf_addrr_soa(struct dnspacket *pkt, const struct zone *zone, int auth);
int rblf_addrr_ns(struct dnspacket *pkt, const struct zone *zone, int auth);


#endif
