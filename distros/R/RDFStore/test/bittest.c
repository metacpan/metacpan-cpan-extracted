#include <assert.h>

void printbits( unsigned int size, unsigned char * bits, int type)
{
	int k=0,i,j;
	if (type == 1) {
	for(i=0;i<size;i++) {
		for(j=0;j<8;j++)  { if (k % 10 == 0) 
			printf("%d",k/10); else printf(" ");
		k++;
		};
	};
	printf("\n");
	for(k=0,i=0;i<size;i++) {
		for(j=0;j<8;j++)  {
			printf("%d",k%10);
		k++;
		};
	};
	printf("\n");
	};
	for(i=0;i<size;i++) {
		for(j=0;j<8;j++) 
			printf("%c",(bits[i] & (1<<j)) ? '1' : '0');
	};
	printf("\n");
}

int main(int argc, char ** argv ) {
	unsigned char bits[] = { 1,229,3,127,12,9,255,0,128 };
	unsigned char bits2[] = { 12,3,45,123,89,3 };
	unsigned char bits3[100];
	int at,l;

	printf("GetFirstSetAfter\n");
	printbits(sizeof(bits),bits,1);
	at = 0;
	while ((at = rdfstore_bits_getfirstsetafter(sizeof(bits),bits,at)) < 8*sizeof(bits)) {
		int i;
		for(i=0;i<at;i++) printf(" ");
		printf("1 @ %d\n",at);
		at++;
	};

	printf("getfirstrecord - mask = 1\n");
	at = 0;
	while ((at = rdfstore_bits_getfirstrecord(sizeof(bits),bits,at,1)) < sizeof(bits) * 2) {
		int i;
		printbits(sizeof(bits),bits,2);
		for(i=0;i<at*4;i++) printf(" ");
		printf("1000 @ %d\n",at);
		at++;
	};

	printf("getfirstrecord - mask = 10\n");
	at = 0;
	while ((at = rdfstore_bits_getfirstrecord(sizeof(bits),bits,at,10)) < sizeof(bits) * 2) {
		int i;
		printbits(sizeof(bits),bits,2);
		for(i=0;i<at*4;i++) printf(" ");
		printf("0101 @ %d\n\n",at);
		at++;
	};

	printf("getfirstrecord - mask = 0xf\n");
	at = 0;
	while ((at = rdfstore_bits_getfirstrecord(sizeof(bits),bits,at,0xf)) < sizeof(bits) * 2) {
		int i;
		printbits(sizeof(bits),bits,2);
		for(i=0;i<at*4;i++) printf(" ");
		printf("1111 @ %d\n",at);
		at++;
	};

	printf("isanyset()- mask = 1\n");
	at = 0;
	l = sizeof(bits);
	while (rdfstore_bits_isanyset(&l,bits,&at,1)) {
		int i;
		printbits(sizeof(bits),bits,2);
		for(i=0;i<at;i++) printf(" ");
		printf("1 @ %d\n\n",at);
		at++;
	};

	printf("\nAND\n");
	printf("A   =");
	printbits(sizeof(bits),bits,2);
	printf("B   =");
	printbits(sizeof(bits2),bits2,2);
	l = rdfstore_bits_and(sizeof(bits),bits,sizeof(bits2),bits2,bits3);
	printf("A&B =");
	printbits(l,bits3,2);
	l = rdfstore_bits_and(sizeof(bits2),bits2,sizeof(bits),bits,bits3);
	printf("B&A =");
	printbits(l,bits3,2);
	printf("\nOR\n");
	printf("A   =");
	printbits(sizeof(bits),bits,2);
	printf("B   =");
	printbits(sizeof(bits2),bits2,2);
	l = rdfstore_bits_or(sizeof(bits),bits,sizeof(bits2),bits2,bits3);
	printf("A|B =");
	printbits(l,bits3,2);
	l = rdfstore_bits_or(sizeof(bits2),bits2,sizeof(bits),bits,bits3);
	printf("B|A =");
	printbits(l,bits3,2);
	printf("\nEXOR\n");
	printf("A   =");
	printbits(sizeof(bits),bits,2);
	printf("B   =");
	printbits(sizeof(bits2),bits2,2);
	l = rdfstore_bits_exor(sizeof(bits),bits,sizeof(bits2),bits2,bits3);
	printf("A^B =");
	printbits(l,bits3,2);
	l = rdfstore_bits_exor(sizeof(bits2),bits2,sizeof(bits),bits,bits3);
	printf("B^A =");
	printbits(l,bits3,2);

}

