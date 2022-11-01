/*
 * Test file.
 */

#ifndef TEST_H
#define TEST_H

extern char var11;
extern signed char var12;
extern unsigned char var13;

extern short var21;
extern signed short var22;
extern unsigned short var23;

extern int var31;
extern signed int var32;
extern unsigned int var33;

extern long int var41;
extern signed long int var42;
extern unsigned long int var43;

extern long long int var51;
extern signed long long int var52;
extern unsigned long long int var53;

extern char f1(int a);
extern short f2(int a);
extern int f3(int a);
extern long int f4(int a);
extern long long int f5(int a);

struct s1
{
	char var11;
	signed char var12;
	unsigned char var13;

	short var21;
	signed short var22;
	unsigned short var23;

	int var31;
	signed int var32;
	unsigned int var33;

	long int var41;
	signed long int var42;
	unsigned long int var43;

	long long int var51;
	signed long long int var52;
	unsigned long long int var53;

	char* var11p;
	signed char* var12p;
	unsigned char* var13p;

	short* var21p;
	signed short* var22p;
	unsigned short* var23p;

	int* var31p;
	signed int* var32p;
	unsigned int* var33p;

	long int* var41p;
	signed long int* var42p;
	unsigned long int* var43p;

	long long int* var51p;
	signed long long int* var52p;
	unsigned long long int* var53p;

	char (*f1)(int a);
	short (*f2)(int a);
	int (*f3)(int a);
	long int (*f4)(int a);
	long long int (*f5)(int a);
}

union u1
{
	char var11;
	signed char var12;
	unsigned char var13;

	short var21;
	signed short var22;
	unsigned short var23;

	int var31;
	signed int var32;
	unsigned int var33;

	long int var41;
	signed long int var42;
	unsigned long int var43;

	long long int var51;
	signed long long int var52;
	unsigned long long int var53;

	char* var11p;
	signed char* var12p;
	unsigned char* var13p;

	short* var21p;
	signed short* var22p;
	unsigned short* var23p;

	int* var31p;
	signed int* var32p;
	unsigned int* var33p;

	long int* var41p;
	signed long int* var42p;
	unsigned long int* var43p;

	long long int* var51p;
	signed long long int* var52p;
	unsigned long long int* var53p;

	char (*f1)(int a);
	short (*f2)(int a);
	int (*f3)(int a);
	long int (*f4)(int a);
	long long int (*f5)(int a);
}

enum e1
{
	e1v1,
	e1v2
}

typedef unsigned int t_size;

#endif
