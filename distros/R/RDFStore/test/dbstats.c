#include <sys/types.h>
#include <db.h>
#include <stdlib.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <signal.h>
#include <stdio.h>
#include <stdlib.h>
#include <errno.h>
#include <unistd.h>

int main(int argc, char ** argv) {
	DB * db;
	DBT k, v;
	int i = 0;

	if (argc != 2) {
		fprintf(stderr,"usage: %s <dbfilename>",argv[0]);
		exit(1);
	}

	db = dbopen(argv[1], 0, DB_BTREE, 0, NULL);
	if(!(db)) {
		perror("Failed to open db");
		exit(1);
	};

	printf("#\tkey\tval\n");
	while((db->seq)(db,&k, &v, i ? R_FIRST : R_NEXT) == 0) {
		printf("%06d\t%d\t%d\n", i, k.size, v.size);
		i++;
	}
}
