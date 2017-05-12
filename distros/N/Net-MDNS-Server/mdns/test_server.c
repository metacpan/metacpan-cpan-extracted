#include "mdnsd.h"

int
main()
	{
		mdnss_start();
		mdnss_add_service("myhost", "1.0.0.10",  25, "smtp", "tcp");
		mdnss_add_service("myhost", "1.0.0.10",  13, "goblin", "tcp");
		mdnss_add_service("myhost", "1.0.0.10",  9, "sandwich", "tcp");
		while(1) { mdnss_process_network_events();}
	}
