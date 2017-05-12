#include <string.h>
#include <stdlib.h>
#include <assert.h>

#include "fraenkel_compress.h"

unsigned int compress_fraenkel(
	unsigned char * src,
	unsigned char * dst,
	unsigned int len
) {
	int i,j,r,s = 0,q=0;
	char * tmp = malloc(len);
	char * msrc = src;
	assert(len<1024*256);
	do {
		for(s=0,r=0,j=0,i=0;i<len;i++) {
			if (msrc[i]) {
				dst[ q++ ] = msrc[i];
				r |= 1<< (i & 7);
			};
			if (i % 8 == 7) {
				tmp[ s++ ] = r;
				r = 0;
			};
		};
		if (i % 8) {
			tmp[ s++ ] = r;
		};
		len = s;
		msrc = tmp;
	} while(len != 1);
	dst[ q++ ] = tmp[0];
	return q;
}
	
unsigned int expand_fraenkel(
	unsigned char * src,
	unsigned char * odst,
	unsigned int len
) {
	char dst[ 1024*256 ];
	int s = len;
	int pass = 1;
	int i = 0, f = 0,j;
	dst[i++]=src[--s];
	do {
		int F = f; /* start of previous run */
		f = i;	/* start of this run */
		for(j=0;j<pass;j++) {
			int k;
			int m = dst[ F+j ]; /* pick up the N values from the previous run. */
			for(k=0;k<8;k++) {
				int bit = 7-k;
				if (m & (1<<bit)) {
					dst[i++] = src[ --s ];
				} else {
					dst[i++] = 0;
				}
			};
		};
		pass *= 8;
	} while(s > 0);

	/* last run, from f until i and swap */
	for(j=0;i>f;)
		odst[j++] = dst[--i];

	return j;
}

#ifdef TEST_FRAENKEL
int main(int argc, char ** argv) {
	unsigned char a[] = { 
/*		0 1 2 3 4 5 6 7  0 1 2 3 4 5 6 7  0 1 2 3 4 5 6 7  0 1 2 3 4 5 6 7  0 1 2 3 4 5 6 7  0 1 2 3 4 5 6 7  */
		0,0,1,4,0,0,0,1, 5,0,0,0,7,0,0,0, 0,0,0,7,0,0,0,0, 0,0,0,0,0,0,0,0, 0,0,0,0,0,0,7,0, 0,0,0,0,0,0,0,0,
		0,0,0,0,0,0,0,0, 0,7,0,0,0,0,0,0, 0,0,0,0,0,0,0,0, 0,0,0,0,7,0,0,0, 0,0,0,0,0,0,0,0, 0,0,0,0,0,0,0,7,
		0,0,0,0,0,0,0,0, 0,0,0,0,0,0,0,0, 0,0,7,0,0,0,0,0, 0,0,0,0,0,0,0,0, 0,0,0,0,0,7,0,0, 0,0,0,0,0,0,0,0,
		0,0,1,4,0,0,0,1,99,0,0,0,7,0,0,0, 0,0,0,7,0,0,0,0, 0,0,0,0,0,0,0,0, 0,0,0,0,0,0,0,0, 0,0,0,0,0,0,0,0,
		0,0,0,0,0,0,0,0, 0,0,0,0,0,0,0,0, 0,0,0,0,0,0,0,0, 0,0,0,0,0,0,0,0, 0,0,0,0,0,0,0,0, 0,0,0,0,0,0,0,0,
		0,0,0,0,0,0,0,0, 0,0,0,0,0,0,0,0, 0,0,0,0,0,0,0,0, 0,0,0,0,0,0,0,0, 0,0,0,0,0,0,0,0, 0,0,0,0,0,0,0,0,
		0,0,0,0,0,0,0,0, 7,0,0,0,0,0,0,0, 0,0,0,0,0,0,0,0, 0,0,0,7,0,0,0,0, 0,0,0,0,0,0,0,0, 0,0,0,0,0,0,7,0,
		0,0,0,0,0,0,0,0, 7,0,0,0,0,0,0,0, 0,0,0,0,0,0,0,0, 0,0,0,7,0,0,0,0, 0,0,0,0,0,0,0,0, 0,0,0,0,0,0,7,0
	};
	unsigned char b[ 1024 ];
	unsigned char c[ 1024 ];
	int i,l,m;

	printf("in  :");
	for(i=0;i<sizeof(a);i++) 
		printf("%02x ",a[i]);
	printf("\n");
	l = compress_fraenkel(a,b,sizeof(a));

	printf("cmp :");
	for(i=0;i<l;i++) 
		printf("%02x ",b[i]);
	printf("\n");

	m = expand_fraenkel(b,c,l);

	printf("out :");
	for(i=0;i<m;i++)  {
		int x = 0;
		if (i<sizeof(a)) x=a[i];
		printf("%02x%c",c[i], (x == c[i]) ? ' ' : '!');
	}
	printf("\n");

	printf("Size %d -> %d (%.02f) -> %d\n",sizeof(a),l,100.0*l/sizeof(a),m);

	return(0);
}
#endif		
	
