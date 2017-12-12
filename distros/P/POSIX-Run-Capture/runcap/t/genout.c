#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <errno.h>
#include <unistd.h>
#include <assert.h>

int skip;
int length;

static void
cat(char const *filename, FILE *out)
{
	FILE *in;
	int c;
	
	if (strcmp (filename, "-") == 0)
		in = stdin;
	else {
		in = fopen(filename, "r");
		if (!in) {
			perror(filename);
			exit(1);
		}
	}
	while ((c = fgetc(in)) != EOF) {
		if (skip) {
			skip--;
			continue;
		}
		fputc(c, out);
		if (length && --length == 0)
			break;
	}
	if (strcmp (filename, "-") == 0 && !feof(in)) {
		/* drain input */
		while (fgetc(in) != EOF)
			;
	}
	fclose(in);
}

int
main(int argc, char **argv)
{
	if (argc == 1)
		cat("-", stdout);
	else {
		int c;
		while ((c = getopt(argc, argv, "o:e:w:s:l:")) != EOF) {
			switch (c) {
			case 'o':
				cat(optarg, stdout);
				break;
			case 'e':
				cat(optarg, stderr);
				break;
			case 'w':
				sleep(atoi(optarg));
				break;
			case 's':
				skip = atoi(optarg);
				assert(skip >= 0);
				break;
			case 'l':
				length = atoi(optarg);
				assert(length >= 0);
				break;
			default:
				return 1;
			}
		}
		argc -= optind;
		argv += optind;
		while (argc--)
			cat(*argv++, stdout);
	}
	return 0;
}
			
