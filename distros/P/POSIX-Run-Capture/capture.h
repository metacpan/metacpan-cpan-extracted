#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include <stdlib.h>
#include <runcap/runcap.h>

struct line_closure
{
	char *str;
	size_t len;
	size_t size;
	SV *cv;
};

struct capture {
	struct runcap rc;
	int flags;
	struct line_closure closure[2];
	SV *program;
	SV *input;
};

typedef struct capture *POSIX__Run__Capture;
typedef char** ARGV;

ARGV XS_unpack_ARGV(SV *sv);
void XS_pack_ARGV(SV *const sv, ARGV argv);

struct capture *capture_new(SV *pn, ARGV argv, unsigned timeout, SV *cb[2], SV *input);
void capture_DESTROY(struct capture *rc);
char *capture_next_line(struct capture *rc, int fd);
int capture_run(struct capture *cp);
void capture_set_argv_ref(struct capture *cp, ARGV av);
void capture_set_input(struct capture *cp, SV *inp);
