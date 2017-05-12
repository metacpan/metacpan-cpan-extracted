/*   lockdefs.c - supply information about struct flock
 *   Copyright (C) 2005, 2006 Proofpoint, Inc.
 *
 *   This program is free software; you can redistribute it and/or modify it under
 *   the same terms as Perl itself
 */

#include <stddef.h>
#include <stdio.h>
#include <unistd.h>
#include <fcntl.h>

main ()
{
    struct flock fl;
    unsigned offset;
    char buf[256];

    for (;;) {
	if (!fgets(buf, sizeof(buf), stdin)) {
	    fprintf(stderr, "__DATA__ not found\n");
	    exit(1);
	}
	if (!strcmp(buf, "__DATA__\n")) break;
    }

    for (;;) {
	if (!fgets(buf, sizeof(buf), stdin)) {
	    fprintf(stderr, "FLOCK_DEFS not found\n");
	    exit(1);
	}
	if (!strcmp(buf, "FLOCK_DEFS\n")) break;
	fputs(buf, stdout);
    }

    memset(&fl, 0, sizeof(fl));
    fl.l_type = F_WRLCK;
    fl.l_whence = SEEK_SET;
    fl.l_start = 0;
    fl.l_len = 0;
    fl.l_pid = 0;

    printf("our $_flock_init = \"");
    for (offset = 0; offset < sizeof(fl); ++offset) {
	printf("\\%o", ((unsigned char *)&fl)[offset]);
    }
    printf("\";\nour $_flock_pid_template = \"x%d", offsetof(struct flock, l_pid));
    if (sizeof(fl.l_pid) == 4) {
	printf("L");
    } else if (sizeof(fl.l_pid) == 2) {
	printf("S");
    } else if (sizeof(fl.l_pid) == 8) {
	printf("Q");
    } else {
	fprinf(stderr, "Unknown pid size\n");
	exit(1);
    }
    printf("\";\n");

    while (fgets(buf, sizeof(buf), stdin)) {
	fputs(buf, stdout);
    }
    exit(0);
}

