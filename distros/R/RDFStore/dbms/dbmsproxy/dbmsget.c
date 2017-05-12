#include <sys/types.h>
#include <sys/socket.h>
#include <sys/un.h>
#include <stdio.h>
#include <sys/uio.h>
#include <unistd.h>
#include <string.h>
#include <stdlib.h>
#include <errno.h>

#include "dbmsproxy.h"

#ifndef pdie
#define pdie(x) { perror(x); exit(1); }
#endif

static void process(int sockfd, char * key) {
	char buff[258], *p;
	int n, l;

	/*
	 * send request <len>, <key of 'len' bytes> i.e. keylen+1 bytes in
	 * length
	 */
	buff[0] = strlen(key);
	strncpy(buff + 1, key, sizeof(buff - 2));

	for (p = buff, l = strlen(key) + 1; l > 0;) {
	    n = write(sockfd, p, l);
	    if (n < 0) {
		if ((errno != EAGAIN) && (errno != EINTR))
		    pdie("write()");
		continue;
	    }
	    else if (n == 0)
		pdie("Connection closed during send");
	    l -= n;
	    p += n;
	};

	/* expect <len><status>< len bytes of answer> back */
	for (l = 0, p = buff;;) {
	    n = read(sockfd, p, l ? l : 1);
	    if (n < 0) {
		if ((errno != EAGAIN) && (errno != EINTR))
		    pdie("read()");
		continue;
	    }
	    else if (n == 0)
		pdie("Connection closed during read");

	    if (l == 0) {
		l = buff[0] + 2 - 1;
	    }
	    else {
		l = l - n;
	    };
	    p += n;

	    if (l <= 0)
		break;
	};
	*p = '\0';

	if (buff[1]) {
	    fprintf(stderr, "No key: %s\n", buff + 2);
	    exit(buff[1]);
	};

	printf("%s\n", buff + 2);
    }

int main(int argc, char ** argv)
{
    struct sockaddr_un server;
    int sockfd, len;
    char * sock = UNIX_SOCK;

    if ((sockfd = socket(AF_UNIX, SOCK_STREAM, 0)) < 0)
	pdie("socket()");

    argv++; --argc;
    if (argc && (!strcmp(*argv, "-p"))) {
	    argv++; --argc;
            sock = *argv; 
	    argv++; --argc;
	};

    memset(&server, 0, sizeof(server));
    server.sun_family = SOCK_STREAM;

    strncpy(server.sun_path, sock, sizeof(server.sun_path) - 1);

#if defined(SCM_RIGHTS) && !defined(RDFSTORE_PLATFORM_LINUX)
    len = sizeof(server.sun_family) + strlen(server.sun_path) + sizeof(server.sun_len) + 1;
    server.sun_len = len;
#else
    len = strlen(server.sun_path) + sizeof(server.sun_family);
#endif

    if (connect(sockfd, (struct sockaddr *) & server, len) < 0)
	pdie("connect()");

    if (argc) {
	for(;argc--;argv++)
	    	process(sockfd, *argv);
    } else {
	char buff[1024];
	while(fgets(buff,sizeof(buff),stdin)) {
		char * q, * p = buff;
		while((q = strsep(&p," \r\n\t")))
			if (strlen(q))
				process(sockfd, q);
	}
    }

    exit(0);
};
