
/* 
   This file contains miscelleneous C code which is required
   to initialise the module and handle C<->perl function passing. 
*/

/* Alternate ways of calling F77 from C */

#ifdef NO_TRAILING_USCORE

#define PGFUNX pgfunx
#define PGFUNY pgfuny
#define PGFUNT pgfunt
#define PGCONX pgconx

#else

#define PGFUNX pgfunx_
#define PGFUNY pgfuny_
#define PGFUNT pgfunt_
#define PGCONX pgconx_

#endif


/* Prototypes */

static SV*  pgfunname[2];
float pgfun1(const float *x);
float pgfun2(const float *x);
void   pgfunplot(int *visible,float *x, float *y, float *z);
void PGFUNX(float fy(), const int *n, const float *xmin, const float *xmax, int *pgflag);
void PGFUNY(float fx(), const int *n, const float *ymin, const float *ymax, int *pgflag);
void PGFUNT(float fx(), float fy(), const int *n, const float *tmin, const float *tmax, int *pgflag);
void PGCONX(const float *a, const int *idim, const int *jdim, const int *i1, const int *i2, const int *j1, const int *j2,
            const float *c, const int *nc, void pgfunplot(int *visible,float *x, float *y, float *z));
/* 

CPGPLOT prototypes missing in PGPLOT 5 - these handle passed
functions. Mechanism used below only works with standard UNIX
C/F77 passing. I have yet to find a system where this doesn't
work but patches are welcome.

*/


void cpgfunx (float pgfun1(), int n, float xmin, float xmax, int pgflag) {

   PGFUNX(pgfun1,&n,&xmin,&xmax,&pgflag);
}


void cpgfuny (float pgfun1(), int n, float ymin, float ymax, int pgflag) {

   PGFUNY(pgfun1,&n,&ymin,&ymax,&pgflag);
}


void cpgfunt (float pgfun1(), float pgfun2(), int n, float tmin, float tmax,
         int pgflag) {

  PGFUNT(pgfun1,pgfun2,&n,&tmin,&tmax,&pgflag);
}

void cpgconx(const float *a, int idim, int jdim, int i1, int i2,
 int j1, int j2, const float *c, int nc,
 void (*plot)(int *visble, float *x, float *y, float *z)) {
   PGCONX(a,&idim,&jdim,&i1,&i2,&j1,&j2,c,&nc,pgfunplot);
}

/* The functions we actually pass to f77 - these call back
   to the correct perl function whose names(s) are passed
   via the back door (i.e. char static varables)          */

/* pgplot called function perl intermediate number 1 */

float pgfun1(const float *x) {

   dSP ;
   int count;
   SV* funname;
   float retval;

   funname = pgfunname[0];          /* Pass perl function name */

   ENTER ;
   SAVETMPS ;

   PUSHMARK(sp) ;

   /* Push arguments */

   XPUSHs(sv_2mortal(newSVnv(*x)));

   PUTBACK ;

   /* Call Perl */

   count = perl_call_sv(funname, G_SCALAR);

   SPAGAIN;

   if (count !=1) 
      croak("Error calling perl function\n");

   retval = (float) POPn ;  /* Return value */

   PUTBACK ;
   FREETMPS ;
   LEAVE ;

   return retval;  
}


/* pgplot called function perl intermediate number 2 */

float pgfun2(const float *x) {

   dSP ;
   int count;
   SV* funname;
   float retval;

   funname = pgfunname[1];          /* Pass perl function name */

   ENTER ;
   SAVETMPS ;

   PUSHMARK(sp) ;

   /* Push arguments */

   XPUSHs(sv_2mortal(newSVnv(*x)));

   PUTBACK ;

   /* Call Perl */

   count = perl_call_sv(funname, G_SCALAR);

   SPAGAIN;

   if (count !=1) 
      croak("Error calling perl function\n");

   retval = (float) POPn ;  /* Return value */

   PUTBACK ;
   FREETMPS ;
   LEAVE ;

   return retval;  
}

/* pgplot called function perl intermediate for PGCONX */

void pgfunplot(int *visible, float *x, float *y, float *z) {

   dSP ;
   int count;
   SV* funname;
   float retval;

   funname = pgfunname[0];          /* Pass perl function name */

   ENTER ;
   SAVETMPS ;

   PUSHMARK(sp) ;

   /* Push arguments */

   XPUSHs(sv_2mortal(newSViv(*visible)));
   XPUSHs(sv_2mortal(newSVnv(*x)));
   XPUSHs(sv_2mortal(newSVnv(*y)));
   XPUSHs(sv_2mortal(newSVnv(*z)));

   PUTBACK ;

   /* Call Perl */

   count = perl_call_sv(funname, G_SCALAR);

   SPAGAIN;

   if (count !=1) 
      croak("Error calling perl function\n");


   PUTBACK ;
   FREETMPS ;
   LEAVE ;
}

