#include <stdlib.h>
#include <sys/mman.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <stdio.h>
#include <string.h>
#include <unistd.h>
#include <sys/types.h>
#include <errno.h>

#include "queue_internal.h"

#include <sys/time.h>
struct timeval global_tv;
#define NOW \
	(gettimeofday(&global_tv,0),(((double)global_tv.tv_sec) + ((double)global_tv.tv_usec)/1000000.0))



#define handle_error(msg) \
	do { perror(msg); exit(EXIT_FAILURE); } while (0)

#define obj_list(obj,i) \
	((struct record*)(obj->q->list + (sizeof(struct record) + obj->rec_len)*i))

struct object* new_queue(){
	struct object* obj = (struct object*)malloc(sizeof(struct object));
	obj->file = 0;
	obj->rec_len = 0;
	obj->que_len = 0;
	obj->fil_len = 0;
	obj->locked = 0;
	obj->fd = -1;
	obj->q = 0;
	return obj;
}
void free_queue(struct object* obj) {
	munmap(obj->q, obj->fil_len);
	close(obj->fd);
	free(obj);
}
void calc_queue(struct object* obj,const char* file,int que_len,int rec_len){
	int pad;
	obj->file = file;
	if( (pad = (sizeof(struct record) + rec_len) % 4) ){
		rec_len += 4 - pad;
	}
	obj->rec_len = rec_len;
	obj->que_len = que_len;
	obj->fil_len = (sizeof(struct record) + rec_len) * que_len + sizeof(struct queue);
	if( (pad = obj->fil_len % 4096)){
		obj->fil_len += 4096 - pad;
	}
}
void init_queue(struct object* obj){
	int need_init;
	obj->fd = init_file(obj->file, obj->fil_len, &need_init);
	obj->q = (struct queue*)mmap(NULL, obj->fil_len, PROT_READ | PROT_WRITE,
                                MAP_SHARED, obj->fd, 0);
	if (obj->q == MAP_FAILED) {
		handle_error("mmap");
	}
	if(need_init){
		obj->q->top = 0;
		obj->q->bottom = 0;
	}
}

int init_file (const char* file, int size,int* ni){
	struct stat sb;
	int fd = -1;
	char *tmp;
	int need;
	int wr;
	*ni = 0;
	if(stat(file,&sb) != -1){
		if(sb.st_size != size){
			remove(file);
		}else{
			fd = open(file, O_RDWR);
			if (fd == -1){
				handle_error("open");
			}
		}
	}
	if(fd == -1){
		fd = open(file,  O_WRONLY | O_CREAT | O_EXCL | O_TRUNC | O_APPEND, 0666);
		if (fd == -1){
			handle_error("open");
		}
		tmp = (char*)malloc(4096);
		memset(tmp,0,4096);
		need = size;
		while(need > 0){
			wr = write(fd, tmp, 4096 < need ? 4096 : need);
			need -= wr;
		}
		close(fd);
		free(tmp);
		fd = open(file, O_RDWR);
		if (fd == -1){
			handle_error("open");
		}
		*ni = 1;
	}
	return fd;
}
void push_queue(struct object* obj,const char* value,int len){
	int cur, top, size, off = 0, first = 1, over = 0;
	double r0,r1,r2;
	r0 = NOW;
	lock_queue(obj);
	r1 = NOW;
	cur = obj->q->bottom;
	top = obj->q->top;
	do {
		if(++cur >= obj->que_len){
			cur = 0;
		}
		if(cur == top){
			over = 1;
		}
		size = obj->rec_len < len ? obj->rec_len : len;
		memcpy(obj_list(obj,cur)->data,value + off,size);
		obj_list(obj,cur)->len = size;
		obj_list(obj,cur)->first = first;
		if(first){
			first = 0;
		}
		if((len -= size) > 0){
			obj_list(obj,cur)->last = 0;
			off += size;
		}else{
			obj_list(obj,cur)->last = 1;
			break;
		}
	} while(1);
	if(over){
		top = cur;
		do {
			if(++top >= obj->que_len){
				top = 0;
			}
		} while(obj_list(obj,top)->last == 0);
	}
	obj->q->bottom = cur;
	obj->q->top = top;
	unlock_queue(obj);
	r2 = NOW;
	obj->wait_lock = r1-r0;
	obj->wait_push = r2-r0;
}
SV* pop_queue(struct object* obj){
	int cur,top,first,size,len;
	SV* value;
	lock_queue(obj);
	cur = obj->q->bottom;
	first = top = obj->q->top;
	if(cur == top){
		unlock_queue(obj);
		return 0;
	}
	len = 0;
	do {
		if(++top >= obj->que_len){
			top = 0;
		}
		len += obj_list(obj,top)->len;
	} while(! obj_list(obj,top)->last);
	value = newSVpvn("",0);
	SvGROW(value,len);
	top = first;
	first = 0;
	do {
		if(++top >= obj->que_len){
			top = 0;
		}
		size = obj_list(obj,top)->len;
		sv_catpvn(value, obj_list(obj,top)->data, (STRLEN)size);
	} while((first += size) != len);
	obj->q->top = top;
	unlock_queue(obj);
	return value;
}
void drop_queue(struct object* obj){
	int cur,top;

	lock_queue(obj);
	cur = obj->q->bottom;
	top = obj->q->top;
	if(cur == top){
		unlock_queue(obj);
		return;
	}
	do {
		if(++top >= obj->que_len){
			top = 0;
		}
	} while(! obj_list(obj,top)->last);
	obj->q->top = top;
	unlock_queue(obj);
}
SV* top_queue(struct object* obj){
	int cur,top,first,size,len;
	SV* value;

	//lock_queue(obj);
	cur = obj->q->bottom;
	first = top = obj->q->top;
	if(cur == top){
		//unlock_queue(obj);
		return 0;
	}
	len = 0;
	do {
		if(++top >= obj->que_len){
			top = 0;
		}
		len += obj_list(obj,top)->len;
	} while(! obj_list(obj,top)->last);
	value = newSVpvn("",0);
	SvGROW(value,len);
	top = first;
	first = 0;
	do {
		if(++top >= obj->que_len){
			top = 0;
		}
		size = obj_list(obj,top)->len;
		sv_catpvn(value, obj_list(obj,top)->data, (STRLEN)size);
	} while((first += size) != len);
	//obj->q->top = top;
	//unlock_queue(obj);
	return value;
}
void unlock_queue(struct object* obj){
	struct flock lock;
	
	/* Setup fcntl locking structure */
	lock.l_type = F_UNLCK;
	lock.l_whence = SEEK_SET;
	lock.l_start = 0;
	lock.l_len = 4096;
	
	/* And unlock page */
	fcntl(obj->fd, F_SETLKW, &lock);
	
	/* Set to bad value while page not locked */
	obj->locked = 0;
}

int lock_queue(struct object* obj){
	struct flock lock;
	int old_alarm, alarm_left = 10;
	int lock_res = -1;
	if(obj->locked) {
		return 0;
	}
	
	/* Setup fcntl locking structure */
	lock.l_type = F_WRLCK;
	lock.l_whence = SEEK_SET;
	lock.l_start = 0;
	lock.l_len = 4096;
	
	old_alarm = alarm(alarm_left);
	
	while (lock_res != 0) {
	
		/* Lock the page (block till done, signal, or timeout) */
		lock_res = fcntl(obj->fd, F_SETLKW, &lock);
	  
		/* Continue immediately if success */
		if (lock_res == 0) {
		  alarm(old_alarm);
		  break;
		}
	  
		/* Turn off alarm for a moment */
		alarm_left = alarm(0);
	  
		/* Some signal interrupted, and it wasn't the alarm? Rerun lock */
		if (lock_res == -1 && errno == EINTR && alarm_left) {
		  alarm(alarm_left);
		  continue;
		}
	  
		/* Lock failed? */
		alarm(old_alarm);
		return 0;
	}
	
	return obj->locked = 1;
}
