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

extern unsigned long long int
	var61;

extern char f1(int a);
extern short f2(int a);
extern int f3(int a);
extern long int f4(int a);
extern long long int f5(int a);

extern int (*f3p)(int a);

extern __attribute__((noreturn)) char f6a(int a);

/* ========================= Structures ========================== */

/* forward structure declaration */
struct s_forward;
struct {};
struct {

};
struct empty_sameline {};

// a simple structure with a C++-style comment
struct s1 // comment on s1
{
	char var11; // comment on var11
	signed char var12; /* comment on var12 */
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
#define var53_value 100

	float var61;
	double var62;
	long double var63;

	struct array_struct as1;
	struct
	{
		char ic1;
	} inner_s;
	struct inner_s2
	{
		char ic1s2;
	};
	struct
	inner_s3
	{
		char ic1s3;
	};

	union u1 field_u1;
	union
	{
		char ic1u;
	} inner_u;
	union inner_u2
	{
		char ic1u2;
	};
	union
	inner_u3
	{
		char ic1u3;
	};
};

struct array_struct /* comment on array_struct */
{
	char var11[1];
	signed char var12[2];
	unsigned char var13[3]; /* field var13 */

	short var21[4];
	signed short var22[5];
	unsigned short var23[6];

	int var31[7];
	signed int var32[8];
	unsigned int var33[9];

	long int var41[10];
	signed long int var42[11];
	unsigned long int var43[12];

	long long int var51[12];
	signed long long int var52[13];
	unsigned long long int var53[14];

	float var61[15];
	double var62[16];
	long double var63[17];

	struct s1 arr_s1[1];
	union u1 field_u1_arr[2];

	char hex_arr[0x123];
};

struct array_struct_name_size
{
#define COUNT 12
	char var11[COUNT];
	signed char var12[COUNT];
	unsigned char var13[COUNT];

	short var21[COUNT];
	signed short var22[COUNT];
	unsigned short var23[COUNT];

	int var31[COUNT];
	signed int var32[COUNT];
	unsigned int var33[COUNT];

	long int var41[COUNT];
	signed long int var42[COUNT];
	unsigned long int var43[COUNT];

	long long int var51[COUNT];
	signed long long int var52[COUNT];
	unsigned long long int var53[COUNT];

	float var61[COUNT];
	double var62[COUNT];
	long double var63[COUNT];

	struct s1 arr_s1[COUNT];
	union u1 field_u1_arr[COUNT];
};

struct point_struc
{
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

	float * var61p;
	double* var62p;
	long double *var63p;

	char (*f1)(int a);
	short (*f2)(int a); /* function pointer comment */
	int (*f3)(int a);
	long int (*f4)(int a);
	long long int (*f5)(int a);
};

struct multi_struct
{
	char mvar1, mvar2, mvar3;
	int mvar1i, mvar2i, mvar3i; /* int comment */
	long mvar1l[1], mvar2l[2];
	long mvar3l[5], mvar4l[6]; /* long comment */
	short mvar1s,
		mvar2s, mvar3s;
	float mvar1f, /* float comment */
		mvar2f, mvar3f;
};

struct point_multi_struc
{
	char* var11p, var11p2;
	signed char* var12p, var12p2;
	unsigned char* var13p, var13p2;

	short* var21p, var21p2;
	signed short* var22p, var22p2;
	unsigned short* var23p, var23p2;

	int* var31p, var31p2;
	signed int* var32p, var32p2;
	unsigned int* var33p, var33p2;

	long int* var41p, var41p2;
	signed long int* var42p, var42p2;
	unsigned long int* var43p, var43p2;

	long long int* var51p, var51p2;
	signed long long int* var52p, var52p2;
	unsigned long long int* var53p, var53p2;

	float * var61p, var61p2;
	double* var62p, var62p2;
	long double *var63p, var63p2;

	char (*f1)(int a), (*f1a)(int a);
	short (*f2)(int a), (*f2a)(int a);
	int (*f3)(int a), (*f3a)(int a); /* function pointer comment */
	long int (*f4)(int a), (*f4a)(int a);
	long long int (*f5)(int a), (*f5a)(int a);
};

struct struct_w_union
{
	union swu_u1
	{
		char mvar1, mvar2, mvar3;
	};
};

struct struct_w_union2
{
	union
	{
		char mvar1, mvar2, mvar3;
	} swu_u2;
};

struct s1 func_ret_s1(void);

struct {
	char str_ptr;
} *anon_str_ptr;

struct sattr {
	char astr_attr;
} __attribute__((packed));

/* ========================= Unions ========================== */

/* forward union declaration */
union u_forward;
union {};
union {

};
union empty_sameline_u {};

union u1
{
	char var11; // comment on var11 in union
	signed char var12; /* comment on var12 in union */
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

	float var61;
	double var62;
	long double var63;
#define var63_value 1
	struct array_struct as1;
	struct
	{
		char ic1;
	} inner_s;
	struct inner_s2
	{
		char ic1s2;
	};
	struct
	inner_s3
	{
		char ic1s3;
	};

	union u1 field_u1;
	union
	{
		char ic1u;
	} inner_u;
	union inner_u2
	{
		char ic1u2;
	};
	union
	inner_u3
	{
		char ic1u3;
	};
};

union array_union
{
	char var11[1];
	signed char var12[2];
	unsigned char var13[3];

	short var21[4];
	signed short var22[5];
	unsigned short var23[6];

	int var31[7];
	signed int var32[8];
	unsigned int var33[9];

	long int var41[10];
	signed long int var42[11];
	unsigned long int var43[12];

	long long int var51[12];
	signed long long int var52[13];
	unsigned long long int var53[14];

	float var61[15];
	double var62[16];
	long double var63[17];

	struct s1 arr_s1[1];
	union u1 field_u1_arr[2];

	char u1_hex_arr[0x123];
};

union array_union_name_size
{
	char var11[COUNT];
	signed char var12[COUNT];
	unsigned char var13[COUNT];

	short var21[COUNT];
	signed short var22[COUNT];
	unsigned short var23[COUNT];

	int var31[COUNT];
	signed int var32[COUNT];
	unsigned int var33[COUNT];

	long int var41[COUNT];
	signed long int var42[COUNT];
	unsigned long int var43[COUNT];

	long long int var51[COUNT];
	signed long long int var52[COUNT];
	unsigned long long int var53[COUNT];

	float var61[COUNT];
	double var62[COUNT];
	long double var63[COUNT];

	struct s1 arr_s1[COUNT];
	union u1 field_u1_arr[COUNT];
};

union point_union
{
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

	float * var61p;
	double* var62p;
	long double *var63p;

	char (*f1)(int a);
	short (*f2)(int a);
	int (*f3)(int a);
	long int (*f4)(int a);
	long long int (*f5)(int a);
};

union multi_union
{
	char mvar1, mvar2, mvar3;
	int mvar1i, mvar2i, mvar3i;
	short mvar1s,
		mvar2s, mvar3s;
	/* float comment */ float mvar1f,
		mvar2f, mvar3f;
};

union u1 func_ret_u1(void);

union {
	char u_ptr;
} *anon_u_ptr;

/* ========================= Enums ========================== */

enum e1
{
	// enum 1 value 1
	e1v1,
	/* enum 1 value 2 */
	e1v2
};

enum e2
{
	e2v1 = 2,
#define E2V1 e2v1
	e2v2
};

enum e3 { e3v1 = 2, e3v2 };

enum e4 { e4v1, e4v2 = 5 };

enum e4w { e4v1w, e4v2w }; /* comment on e4w */
enum e4z { e4v1z, e4v2z }; // comment on e4z

enum
e5
{
	e5v1,
	e5v2
};

enum estrange
{
	esv1 = ,
};

enum eminus
{
	emv1 = -5
};

/* ========================= Typedefs ========================== */

typedef unsigned int ti_size;
typedef unsigned long int tl_size,
	tl_size2;
typedef unsigned int ti_size_attr __attribute__((align(8)));

typedef int (*int_ret_func_ptr)(int);
typedef int (*int_ret_func_ptr2)(int, char);
typedef int (*int_ret_func_ptr3)(int,
	int, char);
typedef int (*
	int_ret_func_ptr4)(int, int, char, char);
typedef int (__attribute__((noreturn)) *int_ret_func_ptr)(int);

typedef struct {

	char tc1;
} tp_struct;

typedef struct tps2 {

	char tc2;
} tp_struct2;

typedef union {

	char tc3;
} tp_union;

typedef union tpu2 {

	char tc4;
} tp_union2;

typedef enum te1
{
	te1v1,
	te1v2
} typ_enum1;

typedef syntax-error err_type;
typedef syntax-error-struc err_type_str {};

extern "C" {
} // empty extern

#endif
