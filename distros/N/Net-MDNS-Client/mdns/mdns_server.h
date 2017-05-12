int  mdnss_start();
void mdnss_stop();
void mdnss_conflict_handler();
/* Don't use this */
int mdnss_msock();
typedef struct
	{
		mdnsdr r,s,t,u;
	} mdnss_rset;
/* add_service
 * Add a dns entry on the fly.  May be done at any time.
 *
 * hostname 		-	The name of the system, what you would see returned from a hostname() call.
 * host_ip			-	The text form of the ip address (e.g. "10.0.0.1").  Does not have to be the IP address of this machine
 * service			-	The official name of the service being offered (e.g. ftp, http, smtp)
 * service_port	-	The port number for this service(e.g. 21, 80, 25).  Need not be the IETF port - allows dynamic ports.
 * protocol			-	"tcp" or "udp" please.
 */
void mdnss_add_service(char * hostname, char *host_ip, int service_port, char * service, char *protocol);
/*
 * Creates an entry for "hostname.local.".  If any other server has laid claim to this hostname, including other local servers, the call will fail
 *
 */
void mdnss_add_hostname(char * hostname, char *host_ip);
/*
 * Process network stuff and answer requests.  Call it often per second!
 */
int mdnss_process_network_events();

