#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"


#include "./mdns/mdnsd.h"
#include "./mdns/mdns_server.h"

#include "const-c.inc"



MODULE = Net::MDNS::Server		PACKAGE = Net::MDNS::Server		PREFIX = mdnss_

INCLUDE: const-xs.inc

void
mdnss_conflict_handler()

int
mdnss_process_network_events()

int
mdnss_start()

void
mdnss_stop()

void
mdnss_add_service(hostname, host_ip, service_port, service, protocol)
	char *	hostname
	char *	host_ip
	char *	service
	int	service_port
	char *	protocol

void
mdnss_add_hostname(hostname, host_ip)
	char *	hostname
	char *	host_ip

