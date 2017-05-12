#include <stdio.h>

#include "mdnsd.h"
#include "mdns_client.h"

int
main(int argc, char *argv[])
	{
		mdnsda rec;
		char * temp;
		mdnsc_start();
		temp = mdnsc_make_query(&"host by service", &"myhost", &"smtp", &"local.", &"tcp");
		printf("Querying %s\n", temp);
		mdnsc_query(temp, "host by service");
		while(1) { 
			mdnsc_process_network_events();}
			rec = mdnsc_get_a_result(temp, "host by service");
			if (rec){printf("Bing!\n"); printf("Retreived record for %s\n", rec->rdname);}
	}
