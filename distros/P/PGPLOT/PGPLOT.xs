
/*
   PGPLOT.xs

   This file contains the routines provide the glue which
   allow perl to call C and hence f77/pgplot via the CPGPLOT
   library.

*/

#include "EXTERN.h"   /* std perl include */
#include "perl.h"     /* std perl include */
#include "XSUB.h"     /* XSUB include */
#include "cpgplot.h"  /* CPGPLOT prototypes */

#include "pgfun.c"    /* Function callback code */
#include "arrays.h"   /* Pack functions decs */
#include "arrays.c"   /* Pack functions defs */

typedef int   int2D;    /* So 2D arrays are handled automagically */
typedef float float2D;  /* by typemap */
typedef float *float_packed;

/* Buffers for routines that return strings  */

static char strbuff[256];
static char strbuff2[256];
#define SIZEOF(X) sizeof(strbuff)

static IV pgplot_debugging=0;

#define DEBUG_PRINT(c) do { \
    if (pgplot_debugging < 1) break; \
    fprintf(stderr, "PGPLOT::" #c "\n"); \
  } while (0)

void MAIN__ () {
   /* Cheat to define MAIN__ symbol */
   croak("This should never happen");
}

/* New struct stuff */

/* Create structure to hold pointers to PGPLOT functions */

struct PGPLOT_function_handle {
   I32 binversion;
   void (*cpgmove) (float x, float y);
   void (*cpgdraw) (float x, float y);
   void (*cpgqcir) (int *icilo, int *icihi);
   void (*cpgsci)  (int ci);
   void (*cpgpt1)  (float x, float y, int sym);
};

typedef struct PGPLOT_function_handle PGPLOT_function_handle;

/* Now create an instance of this */

PGPLOT_function_handle myPGPLOT_handle;

/* See BOOT section for the rest of the struct stuff */


MODULE = PGPLOT     PACKAGE = PGPLOT

IV
set_debugging(i)
  IV i;
CODE:
  RETVAL = pgplot_debugging;
  pgplot_debugging = i;
OUTPUT:
  RETVAL

void
pgarro(x1,y1,x2,y2)
  float	x1
  float	y1
  float	x2
  float	y2
  CODE:
    DEBUG_PRINT(pgarro);
    cpgarro(x1,y1,x2,y2);


void
pgask(flag)
  Logical	flag
  CODE:
    DEBUG_PRINT(pgask);
    cpgask(flag);

void
pgaxis(opt,x1,y1,x2,y2,v1,v2,step,nsub,dmajl,dmajr,fmin,disp,orient)
  char *	opt
  float	x1
  float	y1
  float	x2
  float	y2
  float	v1
  float	v2
  float	step
  int	nsub
  float	dmajl
  float	dmajr
  float	fmin
  float	disp
  float	orient
  CODE:
    DEBUG_PRINT(pgaxis);
    cpgaxis(opt,x1,y1,x2,y2,v1,v2,step,nsub,dmajl,dmajr,fmin,disp,orient);



int
pgband(mode,posn,xref,yref,x,y,ch)
  int	mode
  int	posn
  float	xref
  float	yref
  float	x = NO_INIT
  float	y = NO_INIT
  char	ch = NO_INIT
  CODE:
    DEBUG_PRINT(pgband);
    RETVAL = cpgband(mode,posn,xref,yref,&x,&y,&ch);
  OUTPUT:
  x
  y
  ch
  RETVAL


void
pgbbuf()
  CODE:
    DEBUG_PRINT(pgbbuf);
    cpgbbuf();


int
pgbeg(unit,file,nxsub,nysub)
  int	unit
  char *	file
  int	nxsub
  int	nysub
  CODE:
    DEBUG_PRINT(pgbeg);
    RETVAL = cpgbeg(unit,file,nxsub,nysub);
  OUTPUT:
  RETVAL


int
pgbegin(unit,file,nxsub,nysub)
  int	unit
  char *	file
  int	nxsub
  int	nysub
  CODE:
    DEBUG_PRINT(pgbegin);
    RETVAL = cpgbeg(unit,file,nxsub,nysub);
  OUTPUT:
  RETVAL


void
pgbin(nbin,x,data,center)
  int	nbin
  float *	x
  float *	data
  Logical	center
  CODE:
    DEBUG_PRINT(pgbin);
    cpgbin(nbin,x,data,center);


void
pgbox(xopt,xtick,nxsub,yopt,ytick,nysub)
  char *	xopt
  float	xtick
  int	nxsub
  char *	yopt
  float	ytick
  int	nysub
  CODE:
    DEBUG_PRINT(pgbox);
    cpgbox(xopt,xtick,nxsub,yopt,ytick,nysub);


void
pgcirc(xcent,ycent,radius)
  float	xcent
  float	ycent
  float	radius
  CODE:
    DEBUG_PRINT(pgcirc);
    cpgcirc(xcent,ycent,radius);


void
pgclos()
  CODE:
    DEBUG_PRINT(pgclos);
    cpgclos();

void
pgconb(a,idim,jdim,i1,i2,j1,j2,c,nc,tr,blank)
  float2D *	a
  int	idim
  int	jdim
  int	i1
  int	i2
  int	j1
  int	j2
  float *	c
  int	nc
  float *	tr
  float	blank
  CODE:
    DEBUG_PRINT(pgconb);
    cpgconb(a,idim,jdim,i1,i2,j1,j2,c,nc,tr,blank);


void
pgconf(a,idim,jdim,i1,i2,j1,j2,c1,c2,tr)
  float2D *	a
  int	idim
  int	jdim
  int	i1
  int	i2
  int	j1
  int	j2
  float	c1
  float	c2
  float *	tr
  CODE:
    DEBUG_PRINT(pgconf);
    cpgconf(a,idim,jdim,i1,i2,j1,j2,c1,c2,tr);

void
pgconl(a,idim,jdim,i1,i2,j1,j2,c,tr,label,intval,minint)
  float2D *	a
  int	idim
  int	jdim
  int	i1
  int	i2
  int	j1
  int	j2
  float	c
  float *	tr
  char *	label
  int	intval
  int	minint
  CODE:
    DEBUG_PRINT(pgconl);
    cpgconl(a,idim,jdim,i1,i2,j1,j2,c,tr,label,intval,minint);


void
pgcons(a,idim,jdim,i1,i2,j1,j2,c,nc,tr)
  float2D *	a
  int	idim
  int	jdim
  int	i1
  int	i2
  int	j1
  int	j2
  float *	c
  int	nc
  float *	tr
  CODE:
    DEBUG_PRINT(pgcons);
    cpgcons(a,idim,jdim,i1,i2,j1,j2,c,nc,tr);


void
pgcont(a,idim,jdim,i1,i2,j1,j2,c,nc,tr)
  float2D *	a
  int	idim
  int	jdim
  int	i1
  int	i2
  int	j1
  int	j2
  float *	c
  int	nc
  float *	tr
  CODE:
    DEBUG_PRINT(pgcont);
    cpgcont(a,idim,jdim,i1,i2,j1,j2,c,nc,tr);


void
pgconx(a,idim,jdim,i1,i2,j1,j2,c,nc,plot)
  float2D *	a
  int	idim
  int	jdim
  int	i1
  int	i2
  int	j1
  int	j2
  float *	c
  int	nc
  SV*	plot
  CODE:
    DEBUG_PRINT(pgconx);
    pgfunname[0] = plot;
    cpgconx(a,idim,jdim,i1,i2,j1,j2,c,nc,pgfunplot);


void
pgctab(l,r,g,b,nc,contra,bright)
  float *	l
  float *	r
  float *	g
  float *	b
  int	nc
  float	contra
  float	bright
  CODE:
    DEBUG_PRINT(pgctab);
    cpgctab(l,r,g,b,nc,contra,bright);


int
pgcurs(x,y,ch)
  float	x = NO_INIT
  float	y = NO_INIT
  char	ch = NO_INIT
  CODE:
    DEBUG_PRINT(pgcurs);
    RETVAL = cpgcurs(&x,&y,&ch);
  OUTPUT:
  x
  y
  ch
  RETVAL


int
pgcurse(x,y,ch)
  float	x = NO_INIT
  float	y = NO_INIT
  char	ch = NO_INIT
  CODE:
    DEBUG_PRINT(pgcurse);
    RETVAL = cpgcurs(&x,&y,&ch);
  OUTPUT:
  x
  y
  ch
  RETVAL


void
pgdraw(x,y)
  float	x
  float	y
  CODE:
    DEBUG_PRINT(pgdraw);
    cpgdraw(x,y);


void
pgebuf()
  CODE:
    DEBUG_PRINT(pgebuf);
    cpgebuf();


void
pgend()
  CODE:
    DEBUG_PRINT(pgend);
    cpgend();


void
pgenv(xmin,xmax,ymin,ymax,just,axis)
  float	xmin
  float	xmax
  float	ymin
  float	ymax
  int	just
  int	axis
  CODE:
    DEBUG_PRINT(pgenv);
    cpgenv(xmin,xmax,ymin,ymax,just,axis);


void
pgeras()
  CODE:
    DEBUG_PRINT(pgeras);
    cpgeras();

void
pgerrb(dir,n,x,y,e,t)
  int	dir
  int	n
  float *	x
  float *	y
  float *	e
  float	t
  CODE:
    DEBUG_PRINT(pgerrb);
    cpgerrb(dir,n,x,y,e,t);

void
pgerr1(dir,x,y,e,t)
  int	dir
  float	x
  float	y
  float	e
  float	t
  CODE:
    DEBUG_PRINT(pgerr1);
    cpgerr1(dir,x,y,e,t);


void
pgerrx(n,x1,x2,y,t)
  int	n
  float *	x1
  float *	x2
  float *	y
  float	t
  CODE:
    DEBUG_PRINT(pgerrx);
    cpgerrx(n,x1,x2,y,t);


void
pgerry(n,x,y1,y2,t)
  int	n
  float *	x
  float *	y1
  float *	y2
  float	t
  CODE:
    DEBUG_PRINT(pgerry);
    cpgerry(n,x,y1,y2,t);


void
pgetxt()
  CODE:
    DEBUG_PRINT(pgetxt);
    cpgetxt();


void
pgfunt(fx,fy,n,tmin,tmax,pgflag)
  SV*	fx
  SV*	fy
  int	n
  float	tmin
  float	tmax
  int	pgflag
  CODE:
    DEBUG_PRINT(pgfunt);
    pgfunname[0] = fx;
    pgfunname[1] = fy;
    cpgfunt(pgfun1,pgfun2,n,tmin,tmax,pgflag);


void
pgfunx(fy,n,xmin,xmax,pgflag)
  SV*	fy
  int	n
  float	xmin
  float	xmax
  int	pgflag
  CODE:
    DEBUG_PRINT(pgfunx);
    pgfunname[0] = fy;
    cpgfunx(pgfun1,n,xmin,xmax,pgflag);


void
pgfuny(fx,n,ymin,ymax,pgflag)
  SV*	fx
  int	n
  float	ymin
  float	ymax
  int	pgflag
  CODE:
    DEBUG_PRINT(pgfuny);
    pgfunname[0] = fx;
    cpgfuny(pgfun1,n,ymin,ymax,pgflag);


void
pggray(a,idim,jdim,i1,i2,j1,j2,fg,bg,tr)
  float2D *	a
  int	idim
  int	jdim
  int	i1
  int	i2
  int	j1
  int	j2
  float	fg
  float	bg
  float *	tr
  CODE:
    DEBUG_PRINT(pggray);
    cpggray(a,idim,jdim,i1,i2,j1,j2,fg,bg,tr);


void
pghi2d(data,nxv,nyv,ix1,ix2,iy1,iy2,x,ioff,bias,center,ylims)
  float2D *	data
  int	nxv
  int	nyv
  int	ix1
  int	ix2
  int	iy1
  int	iy2
  float *	x
  int	ioff
  float	bias
  Logical	center
  float *	ylims
  CODE:
    DEBUG_PRINT(pghi2d);
    cpghi2d(data,nxv,nyv,ix1,ix2,iy1,iy2,x,ioff,bias,center,ylims);


void
pghist(n,data,datmin,datmax,nbin,pgflag)
  int	n
  float *	data
  float	datmin
  float	datmax
  int	nbin
  int	pgflag
  CODE:
    DEBUG_PRINT(pghist);
    cpghist(n,data,datmin,datmax,nbin,pgflag);


void
pgiden()
  CODE:
    DEBUG_PRINT(pgiden);
    cpgiden();


void
pgimag(a,idim,jdim,i1,i2,j1,j2,a1,a2,tr)
  float2D *	a
  int	idim
  int	jdim
  int	i1
  int	i2
  int	j1
  int	j2
  float	a1
  float	a2
  float *	tr
  CODE:
    DEBUG_PRINT(pgimag);
    cpgimag(a,idim,jdim,i1,i2,j1,j2,a1,a2,tr);


void
pglab(xlbl,ylbl,toplbl)
  char *	xlbl
  char *	ylbl
  char *	toplbl
  CODE:
    DEBUG_PRINT(pglab);
    cpglab(xlbl,ylbl,toplbl);


void
pglabel(xlbl,ylbl,toplbl)
  char *	xlbl
  char *	ylbl
  char *	toplbl
  CODE:
    DEBUG_PRINT(pglabel);
    cpglab(xlbl,ylbl,toplbl);


void
pglcur(maxpt,npt,x,y)
  int	maxpt
  int	npt = NO_INIT
  float *	x = NO_INIT
  float *	y = NO_INIT
  CODE:
    DEBUG_PRINT(pglcur);
    coerce1D( (SV*)ST(2), maxpt );  /* Make sure arrays are big enough */
    coerce1D( (SV*)ST(3), maxpt );
    x = (float *) pack1D( (SV*)ST(2), 'f' );  /* Pack arrays */
    y = (float *) pack1D( (SV*)ST(3), 'f' );
    cpglcur(maxpt,&npt,x,y);
    unpack1D( (SV*)ST(2),  (void *)x, 'f', 0);
    unpack1D( (SV*)ST(3),  (void *)y, 'f', 0);
  OUTPUT:
  npt


void
pgldev()
  CODE:
    DEBUG_PRINT(pgldev);
    cpgldev();


void
pglen(units,string,xl,yl)
  int	units
  char *	string
  float	xl = NO_INIT
  float	yl = NO_INIT
  CODE:
    DEBUG_PRINT(pglen);
    cpglen(units,string,&xl,&yl);
  OUTPUT:
  xl
  yl


void
pgline(n,xpts,ypts)
  int	n
  float *	xpts
  float *	ypts
  CODE:
    DEBUG_PRINT(pgline);
    cpgline(n,xpts,ypts);


void
pgmove(x,y)
  float	x
  float	y
  CODE:
    DEBUG_PRINT(pgmove);
    cpgmove(x,y);


void
pgmtxt(side,disp,coord,fjust,text)
  char *	side
  float	disp
  float	coord
  float	fjust
  char *	text
  CODE:
    DEBUG_PRINT(pgmtxt);
    cpgmtxt(side,disp,coord,fjust,text);


void
pgmtext(side,disp,coord,fjust,text)
  char *	side
  float	disp
  float	coord
  float	fjust
  char *	text
  CODE:
    DEBUG_PRINT(pgmtext);
    cpgmtxt(side,disp,coord,fjust,text);


void
pgncur(maxpt,npt,x,y,symbol)
  int	maxpt
  int	npt = NO_INIT
  float *	x = NO_INIT
  float *	y = NO_INIT
  int	symbol
  CODE:
    DEBUG_PRINT(pgncur);
    coerce1D( (SV*)ST(2), maxpt );  /* Make sure arrays are big enough */
    coerce1D( (SV*)ST(3), maxpt );
    x = (float *) pack1D( (SV*)ST(2), 'f' );  /* Pack arrays */
    y = (float *) pack1D( (SV*)ST(3), 'f' );
    cpgncur(maxpt,&npt,x,y,symbol);
    unpack1D( (SV*)ST(2),  (void *)x, 'f', 0);
    unpack1D( (SV*)ST(3),  (void *)y, 'f', 0);
  OUTPUT:
  npt


void
pgncurse(maxpt,npt,x,y,symbol)
  int	maxpt
  int	npt = NO_INIT
  float *	x = NO_INIT
  float *	y = NO_INIT
  int	symbol
  CODE:
    DEBUG_PRINT(pgncurse);
    coerce1D( (SV*)ST(2), maxpt );  /* Make sure arrays are big enough */
    coerce1D( (SV*)ST(3), maxpt );
    x = (float *) pack1D( (SV*)ST(2), 'f' );  /* Pack arrays */
    y = (float *) pack1D( (SV*)ST(3), 'f' );
    cpgncur(maxpt,&npt,x,y,symbol);
    unpack1D( (SV*)ST(2),  (void *)x, 'f', 0);
    unpack1D( (SV*)ST(3),  (void *)y, 'f', 0);
  OUTPUT:
  npt


void
pgnumb(mm,pp,form,string,nc)
  int	mm
  int	pp
  int	form
  char *	string = NO_INIT
  int	nc = NO_INIT
  CODE:
    DEBUG_PRINT(pgnumb);
    string = strbuff;
           nc     = SIZEOF(string);
    cpgnumb(mm,pp,form,string,&nc);
  OUTPUT:
  string
  nc


void
pgolin(maxpt,npt,x,y,symbol)
  int	maxpt
  int	npt = NO_INIT
  float *	x = NO_INIT
  float *	y = NO_INIT
  int	symbol
  CODE:
    DEBUG_PRINT(pgolin);
    coerce1D( (SV*)ST(2), maxpt );  /* Make sure arrays are big enough */
    coerce1D( (SV*)ST(3), maxpt );
    x = (float *) pack1D( (SV*)ST(2), 'f' );  /* Pack arrays */
    y = (float *) pack1D( (SV*)ST(3), 'f' );
    cpgolin(maxpt,&npt,x,y,symbol);
    unpack1D( (SV*)ST(2),  (void *)x, 'f', 0);
    unpack1D( (SV*)ST(3),  (void *)y, 'f', 0);
  OUTPUT:
  npt


int
pgopen(device)
  char *	device
  CODE:
    DEBUG_PRINT(pgopen);
    RETVAL = cpgopen(device);
  OUTPUT:
  RETVAL

void
pgpage()
  CODE:
    DEBUG_PRINT(pgpage);
    cpgpage();


void
pgadvance()
  CODE:
    DEBUG_PRINT(pgadvance);
    cpgpage();


void
pgpanl(ix,iy)
  int	ix
  int	iy
  CODE:
    DEBUG_PRINT(pgpanl);
    cpgpanl(ix,iy);


void
pgpap(width,aspect)
  float	width
  float	aspect
  CODE:
    DEBUG_PRINT(pgpap);
    cpgpap(width,aspect);


void
pgpaper(width,aspect)
  float	width
  float	aspect
  CODE:
    DEBUG_PRINT(pgpaper);
    cpgpap(width,aspect);


void
pgpixl(ia,idim,jdim,i1,i2,j1,j2,x1,x2,y1,y2)
  int2D *	ia
  int	idim
  int	jdim
  int	i1
  int	i2
  int	j1
  int	j2
  float	x1
  float	x2
  float	y1
  float	y2
  CODE:
    DEBUG_PRINT(pgpixl);
    cpgpixl(ia,idim,jdim,i1,i2,j1,j2,x1,x2,y1,y2);


void
pgpnts(n,x,y,symbol,ns)
  int	n
  float *	x
  float *	y
  int *	symbol
  int	ns
  CODE:
    DEBUG_PRINT(pgpnts);
    cpgpnts(n,x,y,symbol,ns);

void
pgpoly(n,xpts,ypts)
  int	n
  float *	xpts
  float *	ypts
  CODE:
    DEBUG_PRINT(pgpoly);
    cpgpoly(n,xpts,ypts);


void
pgpt(n,xpts,ypts,symbol)
  int	n
  float *	xpts
  float *	ypts
  int	symbol
  CODE:
    DEBUG_PRINT(pgpt);
    cpgpt(n,xpts,ypts,symbol);

void
pgpt1(xpt,ypt,symbol)
  float	xpt
  float	ypt
  int	symbol
  CODE:
    DEBUG_PRINT(pgpt1);
    cpgpt1(xpt,ypt,symbol);

void
pgpoint(n,xpts,ypts,symbol)
  int	n
  float *	xpts
  float *	ypts
  int	symbol
  CODE:
    DEBUG_PRINT(pgpoint);
    cpgpt(n,xpts,ypts,symbol);


void
pgptxt(x,y,angle,fjust,text)
  float	x
  float	y
  float	angle
  float	fjust
  char *	text
  CODE:
    DEBUG_PRINT(pgptxt);
    cpgptxt(x,y,angle,fjust,text);


void
pgptext(x,y,angle,fjust,text)
  float	x
  float	y
  float	angle
  float	fjust
  char *	text
  CODE:
    DEBUG_PRINT(pgptext);
    cpgptxt(x,y,angle,fjust,text);


void
pgqah(fs,angle,vent)
  int	fs = NO_INIT
  float	angle = NO_INIT
  float	vent = NO_INIT
  CODE:
    DEBUG_PRINT(pgqah);
    cpgqah(&fs,&angle,&vent);
  OUTPUT:
  fs
  angle
  vent


void
pgqcf(font)
  int	font = NO_INIT
  CODE:
    DEBUG_PRINT(pgqcf);
    cpgqcf(&font);
  OUTPUT:
  font


void
pgqch(size)
  float	size = NO_INIT
  CODE:
    DEBUG_PRINT(pgqch);
    cpgqch(&size);
  OUTPUT:
  size


void
pgqci(ci)
  int	ci = NO_INIT
  CODE:
    DEBUG_PRINT(pgqci);
    cpgqci(&ci);
  OUTPUT:
  ci


void
pgqcir(icilo,icihi)
  int	icilo = NO_INIT
  int	icihi = NO_INIT
  CODE:
    DEBUG_PRINT(pgqcir);
    cpgqcir(&icilo,&icihi);
  OUTPUT:
  icilo
  icihi


void
pgqclp(state)
  int	state = NO_INIT
  CODE:
    DEBUG_PRINT(pgqclp);
    cpgqclp(&state);
  OUTPUT:
  state

void
pgqcol(ci1,ci2)
  int	ci1 = NO_INIT
  int	ci2 = NO_INIT
  CODE:
    DEBUG_PRINT(pgqcol);
    cpgqcol(&ci1,&ci2);
  OUTPUT:
  ci1
  ci2

void
pgqcr(ci,cr,cg,cb)
  int	ci
  float	cr = NO_INIT
  float	cg = NO_INIT
  float	cb = NO_INIT
  CODE:
    DEBUG_PRINT(pgqcr);
    cpgqcr(ci,&cr,&cg,&cb);
  OUTPUT:
  cr
  cg
  cb


void
pgqcs(units,xch,ych)
  int	units
  float	xch = NO_INIT
  float	ych = NO_INIT
  CODE:
    DEBUG_PRINT(pgqcs);
    cpgqcs(units,&xch,&ych);
  OUTPUT:
  xch
  ych

void
pgqdt(n,type,tlen,descr,dlen,inter)
  int	n
  char *	type = NO_INIT
  int	tlen = NO_INIT
  char *	descr = NO_INIT
  int	dlen = NO_INIT
  int	inter = NO_INIT
  CODE:
    DEBUG_PRINT(pgqdt);
    type = strbuff;
    tlen = SIZEOF(type);
    descr = strbuff2;
    dlen = SIZEOF(descr);
    cpgqdt(n,type,&tlen,descr,&dlen,&inter);
  OUTPUT:
    type
    tlen
    descr
    dlen
    inter

void
pgqfs(fs)
  int	fs = NO_INIT
  CODE:
    DEBUG_PRINT(pgqfs);
    cpgqfs(&fs);
  OUTPUT:
  fs


void
pgqhs(angle,sepn,phase)
  float	angle = NO_INIT
  float	sepn = NO_INIT
  float	phase = NO_INIT
  CODE:
    DEBUG_PRINT(pgqhs);
    cpgqhs(&angle,&sepn,&phase);
  OUTPUT:
  angle
  sepn
  phase

void
pgqid(id)
  int	id = NO_INIT
  CODE:
    DEBUG_PRINT(pgqid);
    cpgqid(&id);
  OUTPUT:
  id

void
pgqinf(item,value,length)
  char *	item
  char *	value = NO_INIT
  int	length = NO_INIT
  CODE:
    DEBUG_PRINT(pgqinf);
    value = strbuff;
    length = SIZEOF(value);
    cpgqinf(item,value,&length);
  OUTPUT:
  value
  length


void
pgqitf(itf)
  int	itf = NO_INIT
  CODE:
    DEBUG_PRINT(pgqitf);
    cpgqitf(&itf);
  OUTPUT:
  itf


void
pgqls(ls)
  int	ls = NO_INIT
  CODE:
    DEBUG_PRINT(pgqls);
    cpgqls(&ls);
  OUTPUT:
  ls


void
pgqlw(lw)
  int	lw = NO_INIT
  CODE:
    DEBUG_PRINT(pgqlw);
    cpgqlw(&lw);
  OUTPUT:
  lw

void
pgqndt(n)
  int	n = NO_INIT
  CODE:
    DEBUG_PRINT(pgqndt);
    cpgqndt(&n);
  OUTPUT:
  n

void
pgqpos(x,y)
  float	x = NO_INIT
  float	y = NO_INIT
  CODE:
    DEBUG_PRINT(pgqpos);
    cpgqpos(&x,&y);
  OUTPUT:
  x
  y


void
pgqtbg(tbci)
  int	tbci = NO_INIT
  CODE:
    DEBUG_PRINT(pgqtbg);
    cpgqtbg(&tbci);
  OUTPUT:
  tbci


void
pgqtxt(x,y,angle,fjust,text,xbox,ybox)
  float	x
  float	y
  float	angle
  float	fjust
  char *	text
  float *	xbox = NO_INIT
  float *	ybox = NO_INIT
  CODE:
    DEBUG_PRINT(pgqtxt);
    xbox = get_mortalspace(4,'f');
    ybox = get_mortalspace(4,'f');
    cpgqtxt(x,y,angle,fjust,text,xbox,ybox);
    unpack1D( (SV*)ST(5),  (void *)xbox, 'f', 4);
    unpack1D( (SV*)ST(6),  (void *)ybox, 'f', 4);

void
pgqvp(units,x1,x2,y1,y2)
  int	units
  float	x1 = NO_INIT
  float	x2 = NO_INIT
  float	y1 = NO_INIT
  float	y2 = NO_INIT
  CODE:
    DEBUG_PRINT(pgqvp);
    cpgqvp(units,&x1,&x2,&y1,&y2);
  OUTPUT:
  x1
  x2
  y1
  y2


void
pgqvsz(units,x1,x2,y1,y2)
  int	units
  float	x1 = NO_INIT
  float	x2 = NO_INIT
  float	y1 = NO_INIT
  float	y2 = NO_INIT
  CODE:
    DEBUG_PRINT(pgqvsz);
    cpgqvsz(units,&x1,&x2,&y1,&y2);
  OUTPUT:
  x1
  x2
  y1
  y2


void
pgqwin(x1,x2,y1,y2)
  float	x1 = NO_INIT
  float	x2 = NO_INIT
  float	y1 = NO_INIT
  float	y2 = NO_INIT
  CODE:
    DEBUG_PRINT(pgqwin);
    cpgqwin(&x1,&x2,&y1,&y2);
  OUTPUT:
  x1
  x2
  y1
  y2


void
pgrect(x1,x2,y1,y2)
  float	x1
  float	x2
  float	y1
  float	y2
  CODE:
    DEBUG_PRINT(pgrect);
    cpgrect(x1,x2,y1,y2);


float
pgrnd(x,nsub)
  float	x
  int	nsub = NO_INIT
  CODE:
    DEBUG_PRINT(pgrnd);
    RETVAL = cpgrnd(x,&nsub);
  OUTPUT:
  nsub
  RETVAL


void
pgrnge(x1,x2,xlo,xhi)
  float	x1
  float	x2
  float	xlo = NO_INIT
  float	xhi = NO_INIT
  CODE:
    DEBUG_PRINT(pgrnge);
    cpgrnge(x1,x2,&xlo,&xhi);
  OUTPUT:
  xlo
  xhi


void
pgsah(fs,angle,vent)
  int	fs
  float	angle
  float	vent
  CODE:
    DEBUG_PRINT(pgsah);
    cpgsah(fs,angle,vent);


void
pgsave()
  CODE:
    DEBUG_PRINT(pgsave);
    cpgsave();


void
pgunsa()
  CODE:
    DEBUG_PRINT(pgunsa);
    cpgunsa();


void
pgscf(font)
  int	font
  CODE:
    DEBUG_PRINT(pgscf);
    cpgscf(font);


void
pgsch(size)
  float	size
  CODE:
    DEBUG_PRINT(pgsch);
    cpgsch(size);


void
pgsci(ci)
  int	ci
  CODE:
    DEBUG_PRINT(pgsci);
    cpgsci(ci);


void
pgscir(icilo,icihi)
  int	icilo
  int	icihi
  CODE:
    DEBUG_PRINT(pgscir);
    cpgscir(icilo,icihi);

void
pgsclp(state)
  int	state
  CODE:
    DEBUG_PRINT(pgsclp);
    cpgsclp(state);

void
pgscr(ci,cr,cg,cb)
  int	ci
  float	cr
  float	cg
  float	cb
  CODE:
    DEBUG_PRINT(pgscr);
    cpgscr(ci,cr,cg,cb);

void
pgscrl(dx,dy)
  float	dx
  float	dy
  CODE:
    DEBUG_PRINT(pgscrl);
    cpgscrl(dx,dy);

void
pgscrn(ci,name,ier)
  int	ci
  char *	name
  int	ier = NO_INIT
  CODE:
    DEBUG_PRINT(pgscrn);
    cpgscrn(ci,name,&ier);
  OUTPUT:
  ier


void
pgsfs(fs)
  int	fs
  CODE:
    DEBUG_PRINT(pgsfs);
    cpgsfs(fs);


void
pgshls(ci,ch,cl,cs)
  int	ci
  float	ch
  float	cl
  float	cs
  CODE:
    DEBUG_PRINT(pgshls);
    cpgshls(ci,ch,cl,cs);


void
pgshs(angle,sepn,phase)
  float	angle
  float	sepn
  float	phase
  CODE:
    DEBUG_PRINT(pgshs);
    cpgshs(angle,sepn,phase);


void
pgsitf(itf)
  int	itf
  CODE:
    DEBUG_PRINT(pgsitf);
    cpgsitf(itf);

void
pgslct(id)
  int	id
  CODE:
    DEBUG_PRINT(pgslct);
    cpgslct(id);

void
pgsls(ls)
  int	ls
  CODE:
    DEBUG_PRINT(pgsls);
    cpgsls(ls);


void
pgslw(lw)
  int	lw
  CODE:
    DEBUG_PRINT(pgslw);
    cpgslw(lw);


void
pgstbg(tbci)
  int	tbci
  CODE:
    DEBUG_PRINT(pgstbg);
    cpgstbg(tbci);


void
pgsubp(nxsub,nysub)
  int	nxsub
  int	nysub
  CODE:
    DEBUG_PRINT(pgsubp);
    cpgsubp(nxsub,nysub);


void
pgsvp(xleft,xright,ybot,ytop)
  float	xleft
  float	xright
  float	ybot
  float	ytop
  CODE:
    DEBUG_PRINT(pgsvp);
    cpgsvp(xleft,xright,ybot,ytop);


void
pgvport(xleft,xright,ybot,ytop)
  float	xleft
  float	xright
  float	ybot
  float	ytop
  CODE:
    DEBUG_PRINT(pgvport);
    cpgsvp(xleft,xright,ybot,ytop);


void
pgswin(x1,x2,y1,y2)
  float	x1
  float	x2
  float	y1
  float	y2
  CODE:
    DEBUG_PRINT(pgswin);
    cpgswin(x1,x2,y1,y2);


void
pgwindow(x1,x2,y1,y2)
  float	x1
  float	x2
  float	y1
  float	y2
  CODE:
    DEBUG_PRINT(pgwindow);
    cpgswin(x1,x2,y1,y2);


void
pgtbox(xopt,xtick,nxsub,yopt,ytick,nysub)
  char *	xopt
  float	xtick
  int	nxsub
  char *	yopt
  float	ytick
  int	nysub
  CODE:
    DEBUG_PRINT(pgtbox);
    cpgtbox(xopt,xtick,nxsub,yopt,ytick,nysub);

void
pgtick(x1,y1,x2,y2,v,tikl,tikr,disp,orient,str)
  float	x1
  float	y1
  float	x2
  float	y2
  float	v
  float	tikl
  float	tikr
  float	disp
  float	orient
  char *	str
  CODE:
    DEBUG_PRINT(pgtick);
    cpgtick(x1,y1,x2,y2,v,tikl,tikr,disp,orient,str);

void
pgtext(x,y,text)
  float	x
  float	y
  char *	text
  CODE:
    DEBUG_PRINT(pgtext);
    cpgtext(x,y,text);


void
pgupdt()
  CODE:
    DEBUG_PRINT(pgupdt);
    cpgupdt();


void
pgvect(a,b,idim,jdim,i1,i2,j1,j2,c,nc,tr,blank)
  float2D *	a
  float2D *	b
  int	idim
  int	jdim
  int	i1
  int	i2
  int	j1
  int	j2
  float	c
  int	nc
  float *	tr
  float	blank
  CODE:
    DEBUG_PRINT(pgvect);
    cpgvect(a,b,idim,jdim,i1,i2,j1,j2,c,nc,tr,blank);


void
pgvsiz(xleft,xright,ybot,ytop)
  float	xleft
  float	xright
  float	ybot
  float	ytop
  CODE:
    DEBUG_PRINT(pgvsiz);
    cpgvsiz(xleft,xright,ybot,ytop);


void
pgvsize(xleft,xright,ybot,ytop)
  float	xleft
  float	xright
  float	ybot
  float	ytop
  CODE:
    DEBUG_PRINT(pgvsize);
    cpgvsiz(xleft,xright,ybot,ytop);


void
pgvstd()
  CODE:
    DEBUG_PRINT(pgvstd);
    cpgvstd();


void
pgvstand()
  CODE:
    DEBUG_PRINT(pgvstand);
    cpgvstd();


void
pgwedg(side,disp,width,fg,bg,label)
  char *	side
  float	disp
  float	width
  float	fg
  float	bg
  char *	label
  CODE:
    DEBUG_PRINT(pgwedg);
    cpgwedg(side,disp,width,fg,bg,label);


void
pgwnad(x1,x2,y1,y2)
  float	x1
  float	x2
  float	y1
  float	y2
  CODE:
    DEBUG_PRINT(pgwnad);
    cpgwnad(x1,x2,y1,y2);


void
pggapline(n,msgval,xpts,ypts)
  int	n
  float msgval
  float_packed	xpts
  float_packed	ypts
  CODE:
    DEBUG_PRINT(pggapline);
    { int i;
      int start = 0;
      while (xpts[start] == msgval) start++;  /* make sure we have a good starting point */
      cpgmove(xpts[start], ypts[start]);
      for (i=start+1;i<n;i++) {
        if (ypts[i] == msgval) {
           /* check we are not at end of array and we don't move to a missing value */
           if (i != n-1 && ypts[i+1] != msgval) {
             cpgmove(xpts[i+1], ypts[i+1]);
           }
        }
        else {
          cpgdraw(xpts[i], ypts[i]);
        }
      }
    }


void
pgcolorpnts(n,x,y,z,sym)
  int	n
  float_packed	x
  float_packed	y
  float_packed	z
  int   sym
  CODE:
    DEBUG_PRINT(pgcolorpnts);
    {
      /* find range of color pallette */
      int icilo, icihi, i, cirange, ci;
      float minz, maxz, zrange;

      cpgqcir(&icilo, &icihi);

      /* find min and max values of zpts variable */
      minz =  9.99e30;
      maxz = -9.99e30;
      for (i=0;i<n;i++) {
	if (z[i] < minz) minz = z[i];
	if (z[i] > maxz) maxz = z[i];
      }

      /* determine range of available z indices and range of input 'z' values */
      cirange = icihi - icilo;
      zrange  = maxz  - minz;

      /* printf ("cilo = %d, cihi = %d\n", icilo, icihi); */

      /* for each input point, compute a scaled color index and plot the point */
      for (i=0;i<n;i++) {
	ci = (int)(icilo + (z[i] - minz) * (float)(cirange/zrange));
	/* printf ("x = %f, y = %f, ci = %d\n", x[i], y[i], ci); */
	cpgsci(ci);
	cpgpt1(x[i], y[i], sym);
      }
    }

BOOT:
   /* New struct stuff */

   /* Initialise structure of pointers to core C routines */

   myPGPLOT_handle.binversion  = 20001129; /* Date structure redefined */
   myPGPLOT_handle.cpgdraw     = cpgdraw;
   myPGPLOT_handle.cpgmove     = cpgmove;
   myPGPLOT_handle.cpgqcir     = cpgqcir;
   myPGPLOT_handle.cpgsci      = cpgsci;
   myPGPLOT_handle.cpgpt1      = cpgpt1;

   /*
      "Publish" pointer to this structure in perl variable for use
       by other modules
   */

   sv_setiv(get_sv("PGPLOT::HANDLE",TRUE|GV_ADDMULTI), (IV) (void*) &myPGPLOT_handle);
