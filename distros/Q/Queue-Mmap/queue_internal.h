#ifndef queue_internal_h
#define queue_internal_h

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

struct record {
	int len;
	int last;
	int first;
	char data[];
};

struct queue {
	int top;
	int bottom;
	int pad[4];
	char list[];
};

struct object {
	const char *file;
	int que_len;
	int rec_len;
	int fil_len;
	struct queue *q;
	int locked;
	int fd;
	double wait_lock;
	double wait_push;
};

struct object* new_queue();
int    init_file(const char*,int,int*);
void   free_queue(struct object*);
void   init_queue(struct object*);
void   calc_queue(struct object*,const char*,int,int);

int  lock_queue(struct object*);
void unlock_queue(struct object*);
void push_queue(struct object*,const char*,int);
SV*  pop_queue(struct object*);
SV*  top_queue(struct object*);
void drop_queue(struct object*);

#endif
