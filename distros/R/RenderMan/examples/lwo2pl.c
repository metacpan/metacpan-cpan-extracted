/* lwo2rib.c - Read LWOB and convert to RIB file
 *        - Written by Glenn M. Lewis - 6/27/95
 * $Id: lwo2rib.c,v 1.3 1995/12/07 23:39:28 glewis Exp $
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <math.h>

#include "ri.h"

/* #define DEBUG     */
/* #define MEGADEBUG */

#define EMEM(n, t)  (t*)malloc((size_t)(n)*sizeof(t))
#define EFREE(x)    {if(x){free((char*)(x));(x)=0;}}
#define MEMERR(z)   { fprintf(stderr, "Out of memory at '%s'\n", z); exit(-1); }
#define SIZE (100)

RtFloat poly[3*SIZE];
RtFloat normal[3*SIZE];
RtFloat color[3*SIZE];
extern char CurrentFile[];
int use_color = 1;
int output_normals = 1;
int statistics = 0;
unsigned long stats[256];

typedef unsigned char UBYTE;
typedef unsigned short USHORT;
typedef unsigned long ULONG;

#define HASH(a,b,c,d) ((ULONG)((a)<<24L)|((b)<<16L)|((c)<<8L)|(d))

#define FLAG_LUMINOUS   (1<<0)
#define FLAG_OUTLINE    (1<<1)
#define FLAG_SMOOTHING  (1<<2)
#define FLAG_HIGHLIGHTS (1<<3)
#define FLAG_FILTER     (1<<4)
#define FLAG_OPAQUEEDGE (1<<5)
#define FLAG_TRANSPEDGE (1<<6)
#define FLAG_SHARPTERM  (1<<7)
#define FLAG_DOUBLESIDE (1<<8)
#define FLAG_ADDITIVE   (1<<9)

#define TFLG_XAXIS      (1<<0)
#define TFLG_YAXIS      (1<<1)
#define TFLG_ZAXIS      (1<<2)
#define TFLG_WORLDCOORD (1<<3)
#define TFLG_NEGATIVE   (1<<4)
#define TFLG_BLENDING   (1<<5)
#define TFLG_ANTIALIAS  (1<<6)


struct subsurf {
  char *name;  /* Name of texture type as shown on the control panel */
  char *timg;  /* texture mapping image filename */
  USHORT tflg;  /* See "TFLG_" definitions above */
  RtFloat tsiz[3];  /* Texture Size */
  RtFloat tctr[3];  /* Texture Center */
  RtFloat tfal[3];  /* Texture Falloff */
  RtFloat tvel[3];  /* Texture Velocity */
  UBYTE tclr[3];  /* Texture Color */
  USHORT tval;    /* Value for this texture (256==100%) (D,S,R,T-TEX) */
  RtFloat tamp;     /* Texture amplitude (for BTEX) */
  short tfrq;     /* Number of noise frequencies or wave sources */
  RtFloat tsp0, tsp1, tsp2;  /* special texture type-specific parameters */
};
typedef struct subsurf SUBSURF;

struct surface {
  char *name;  /* Point to name in "surface_names" string */
  RtFloat color[4];
  USHORT flag;  /* See "FLAG_" definitions above */
  USHORT lumi, diff, spec, refl, tran;
  USHORT glos;
  char *rimg;  /* Reflection map filename */
  RtFloat rsan;  /* Reflection map seam heading angle (in degrees) */
  RtFloat rind;  /* Index of refraction */
  RtFloat edge;  /* Edge transparency threshold */
  RtFloat sman;  /* Smooth shaded maximum angle (in degrees) */
  SUBSURF *ctex; /* color;        */
  SUBSURF *dtex; /* diffuse;      */
  SUBSURF *stex; /* specular;     */
  SUBSURF *rtex; /* reflection;   */
  SUBSURF *ttex; /* transparency; */
  SUBSURF *btex; /* bump;         */
};
typedef struct surface SURFACE;

struct obj {
  struct obj *next;
  RtFloat llx, urx, lly, ury, llz, urz;
  ULONG numpnts;
  RtFloat *xyz;  /* Vertex */
  RtFloat *nxyz; /* Vertex normals */
  short numsurfs;
  char *surface_names;
  ULONG num_poly_shorts;  /* Number of shorts in polygon_list */
  short *polygon_list;
  RtInt num_polys;        /* Number of individual polygons */
  RtFloat *poly_nx, *poly_ny, *poly_nz;  /* Flat poly normals */
  ULONG numcrvs;  /* Number of shorts in the curves_list */
  short *curves_list;
  SURFACE **surfaces;
};
typedef struct obj OBJ;

FILE *inp = 0;
ULONG name = 0;
char strin[256];
long iffsize = 0;
long size = 0;
OBJ *head = 0;

RtFloat LLX, LLY, LLZ, URX, URY, URZ;
RtFloat XCENTER, YCENTER, ZCENTER;

char getbyte(void)
{
  iffsize--;
  size--;
#ifdef MEGADEBUG
    fprintf(stderr, "Read byte.  iffsize=%ld, size=%ld\n", iffsize, size);
#endif
  return((char)(fgetc(inp)&0xFF));
}

UBYTE getubyte(void)
{
  iffsize--;
  size--;
#ifdef MEGADEBUG
    fprintf(stderr, "Read ubyte.  iffsize=%ld, size=%ld\n", iffsize, size);
#endif
  return((UBYTE)(fgetc(inp)&0xFF));
}

short getshort(void)
{
  short val;
  val = (short)fgetc(inp);
  val = (val << 8) | (short)fgetc(inp);
  iffsize -= 2;
  size -= 2;
#ifdef MEGADEBUG
    fprintf(stderr, "Read short.  iffsize=%ld, size=%ld\n", iffsize, size);
#endif
  return(val);
}

USHORT getushort(void)
{
  USHORT val;
  val = (USHORT)fgetc(inp);
  val = (val << 8) | (USHORT)fgetc(inp);
  iffsize -= 2;
  size -= 2;
#ifdef MEGADEBUG
    fprintf(stderr, "Read ushort.  iffsize=%ld, size=%ld\n", iffsize, size);
#endif
  return(val);
}

ULONG getulong(void)
{
  ULONG val;
  val = (ULONG)fgetc(inp);
  val = (val << 8L) | (ULONG)fgetc(inp);
  val = (val << 8L) | (ULONG)fgetc(inp);
  val = (val << 8L) | (ULONG)fgetc(inp);
  iffsize -= 4;
  size -= 4;
#ifdef MEGADEBUG
    fprintf(stderr, "Read ulong.  iffsize=%ld, size=%ld\n", iffsize, size);
#endif
  return(val);
}

void getname(void)
{
#ifdef MEGADEBUG
    fprintf(stderr, "Read name: ");
#endif
  name = getulong();
}

RtFloat getfloat(void)
{
  union {
    float f;
    ULONG u;
  } num;
#ifdef MEGADEBUG
    fprintf(stderr, "Read float: ");
#endif
  num.u = getulong();
  return((RtFloat)num.f);
}

void process_subsurf(register SUBSURF *ssurf, short subsize)
{
  char *p;
  int count;

  /* First, zero out new SUBSURF structure */
  memset(ssurf, 0, sizeof(SUBSURF));

  p = &strin[0];
  count = 0;
  while (1) {  /* Read in the name of the texture type */
    *p = getbyte();
    subsize--;
    count++;
    if (!*p) break;
    p++;
  }
  if (count&1) { getubyte(); subsize--; }
  ssurf->name = strdup(strin);
#ifdef DEBUG
    fprintf(stderr, " Texture type: '%s'\n", ssurf->name);
#endif
}

void bad_ssurf(void)
{
#ifndef WINDOWS
  fprintf(stderr, "ERROR!  Chunk '%c%c%c%c' appeared before *TEX chunk!  Abort!\n",
        (char)((name>>24L)&0xFFL),
        (char)((name>>16L)&0xFFL),
        (char)((name>> 8L)&0xFFL),
        (char)((name     )&0xFFL));
#endif
  exit(-1);
}

void handle_surf(void)
{
  register OBJ *obj = head;
  SURFACE *surf;
  SUBSURF *ssurf = 0;
  char *p;
  int count;
  int i;
  short subsize;

  p = &strin[0];
  count = 0;
  while (1) {  /* Read in the name of the surface */
    *p = getbyte();
    count++;
    if (!*p) break;
    p++;
  }
  if (count&1) getubyte();

  /* Now, match up against the stored surface names for this object */
  for (count=1; count <= obj->numsurfs; count++)
    if (strcmp(strin, obj->surfaces[count]->name)==0) break;
  if (count > obj->numsurfs) {
#ifndef WINDOWS
    fprintf(stderr, "ERROR!!!  Couldn't find surface '%s' in SRFS!  Abort!\n",
          strin);
#endif
    exit(-1);
  }
  surf = obj->surfaces[count];
#ifndef WINDOWS
#ifdef DEBUG
  fprintf(stderr, "Reading properties for surface #%d: '%s'...\n",
        count, surf->name);
#endif
#endif

  /* Start processing sub-chunks for this surface */
  while (size > 0) {
    getname();
    subsize = (short)getushort();
#ifdef DEBUG
    fprintf(stderr, "Processing SURF sub-chunk '%c%c%c%c', size=%d=%04X...\n",
          (char)((name>>24L)&0xFFL),
          (char)((name>>16L)&0xFFL),
          (char)((name>> 8L)&0xFFL),
          (char)((name     )&0xFFL),
          subsize, (USHORT)subsize);
#endif
    switch(name) {
    case HASH('C','O','L','R'):
      surf->color[0] = (RtFloat)getubyte() * (1.0 / 255.0);
      surf->color[1] = (RtFloat)getubyte() * (1.0 / 255.0);
      surf->color[2] = (RtFloat)getubyte() * (1.0 / 255.0);
      surf->color[3] = 1.0;
      getubyte();
      break;
    case HASH('F','L','A','G'): surf->flag = getushort(); break;
    case HASH('L','U','M','I'): surf->lumi = getushort(); break;
    case HASH('D','I','F','F'): surf->diff = getushort(); break;
    case HASH('S','P','E','C'): surf->spec = getushort(); break;
    case HASH('R','E','F','L'): surf->refl = getushort(); break;
    case HASH('T','R','A','N'): surf->tran = getushort(); break;
    case HASH('G','L','O','S'): surf->glos = getushort(); break;
    case HASH('R','I','M','G'):
      p = &strin[0];
      if (subsize & 1) subsize++;
      for (i=subsize; i--; ) *p++ = getbyte();
      surf->rimg = strdup(strin);
      break;
    case HASH('R','S','A','N'): surf->rsan = getfloat(); break;
    case HASH('R','I','N','D'): surf->rind = getfloat(); break;
    case HASH('S','M','A','N'): surf->sman = getfloat(); break;
    case HASH('C','T','E','X'):
      if (!(ssurf = surf->ctex = EMEM(1, SUBSURF))) MEMERR("ctex");
      process_subsurf(surf->ctex, subsize);
      break;
    case HASH('D','T','E','X'):
      if (!(ssurf = surf->dtex = EMEM(1, SUBSURF))) MEMERR("dtex");
      process_subsurf(surf->dtex, subsize);
      break;
    case HASH('S','T','E','X'):
      if (!(ssurf = surf->stex = EMEM(1, SUBSURF))) MEMERR("stex");
      process_subsurf(surf->stex, subsize);
      break;
    case HASH('R','T','E','X'):
      if (!(ssurf = surf->rtex = EMEM(1, SUBSURF))) MEMERR("rtex");
      process_subsurf(surf->rtex, subsize);
      break;
    case HASH('T','T','E','X'):
      if (!(ssurf = surf->ttex = EMEM(1, SUBSURF))) MEMERR("ttex");
      process_subsurf(surf->ttex, subsize);
      break;
    case HASH('B','T','E','X'):
      if (!(ssurf = surf->btex = EMEM(1, SUBSURF))) MEMERR("btex");
      process_subsurf(surf->btex, subsize);
      break;

      /* texture properties */
    case HASH('T','I','M','G'):
      if (!ssurf) bad_ssurf();
      p = &strin[0];
      if (subsize & 1) subsize++;
      for (i=subsize; i--; ) *p++ = getbyte();
      ssurf->timg = strdup(strin);
      break;
    case HASH('T','F','L','G'):
      if (!ssurf) bad_ssurf();
      ssurf->tflg = getushort();
      break;
    case HASH('T','S','I','Z'):
      if (!ssurf) bad_ssurf();
      ssurf->tsiz[0] = getfloat();
      ssurf->tsiz[1] = getfloat();
      ssurf->tsiz[2] = getfloat();
      break;
    case HASH('T','C','T','R'):
      if (!ssurf) bad_ssurf();
      ssurf->tctr[0] = getfloat();
      ssurf->tctr[1] = getfloat();
      ssurf->tctr[2] = getfloat();
      break;
    case HASH('T','F','A','L'):
      if (!ssurf) bad_ssurf();
      ssurf->tfal[0] = getfloat();
      ssurf->tfal[1] = getfloat();
      ssurf->tfal[2] = getfloat();
      break;
    case HASH('T','V','E','L'):
      if (!ssurf) bad_ssurf();
      ssurf->tvel[0] = getfloat();
      ssurf->tvel[1] = getfloat();
      ssurf->tvel[2] = getfloat();
      break;
    case HASH('T','C','L','R'):
      if (!ssurf) bad_ssurf();
      ssurf->tclr[0] = getubyte();
      ssurf->tclr[1] = getubyte();
      ssurf->tclr[2] = getubyte();
      getubyte();
      break;
    case HASH('T','V','A','L'):
      if (!ssurf) bad_ssurf();
      ssurf->tval = getushort();
      break;
    case HASH('T','A','M','P'):
      if (!ssurf) bad_ssurf();
      ssurf->tamp = getfloat();
      break;
    case HASH('T','F','R','Q'):
      if (!ssurf) bad_ssurf();
      ssurf->tfrq = getshort();
      break;
    case HASH('T','S','P','0'):
      if (!ssurf) bad_ssurf();
      ssurf->tsp0 = getfloat();
      break;
    case HASH('T','S','P','1'):
      if (!ssurf) bad_ssurf();
      ssurf->tsp1 = getfloat();
      break;
    case HASH('T','S','P','2'):
      if (!ssurf) bad_ssurf();
      ssurf->tsp2 = getfloat();
      break;

    default:
#ifndef WINDOWS
      fprintf(stderr, "Unknown SURF sub-chunk '%c%c%c%c', size=%d=%04X.  Skipping.\n",
            (char)((name>>24L)&0xFFL),
            (char)((name>>16L)&0xFFL),
            (char)((name>> 8L)&0xFFL),
            (char)((name     )&0xFFL),
            subsize, (USHORT)subsize);
#endif
      if (subsize&1) { getubyte(); subsize--; }
      while (subsize) { getubyte(); subsize--; }
    }
  }
#ifndef WINDOWS
#ifdef DEBUG
  fprintf(stderr, "Done reading properties for surface #%d: '%s'.\n",
        count, surf->name);
#endif
#endif
}

#define VECSUB(a,b,c);   { c[0]=a[0]-b[0]; c[1]=a[1]-b[1]; c[2]=a[2]-b[2];}
#define VECSCALE(a,b,c); { c[0]=(a)*b[0]; c[1]=(a)*b[1]; c[2]=(a)*b[2];}
#define CROSS(v1,v2,r);  { \
			  r[0] = (v1[1]*v2[2]) - (v2[1]*v1[2]);  \
			  r[1] = (v1[2]*v2[0]) - (v1[0]*v2[2]);  \
			  r[2] = (v1[0]*v2[1]) - (v2[0]*v1[1]);  \
		      }


static int normalize(RtFloat *v)
{
  double n,nn;

  n= (double)((v[0]*v[0]) + (v[1]*v[1]) + (v[2]*v[2]));
  if (n < 1.e-10) return(0);
  nn=sqrt(n);
  n = ((double)1.0/(double)nn);
  VECSCALE(n,v,v);
  return(1);
}

static int getnormal(RtFloat *x, RtFloat *y, RtFloat *z, RtFloat *n)
{
  RtFloat dz[3],dy[3];
  VECSUB(y,x,dy);
  VECSUB(z,x,dz);
  CROSS(dy,dz,n);
  return(normalize(n));
}

int read_file(void)
{
  register OBJ *obj;
  register short *sp;
  register RtFloat *fp;
  long num;
  int last_null;
  long i;
  long count;
  RtFloat v1[3],v2[3],v3[3],nn[3];

  getname();
  if (name != HASH('F','O','R','M')) {
#ifdef WINDOWS
    MessageBox(NULL, "Not an IFF file.", "Error", MB_OK);
#else
    fprintf(stderr, "Not an IFF file!\n");
#endif
    return(0);
  }
  iffsize = (long)getulong();

#ifdef DEBUG
    fprintf(stderr, "iffsize = %ld = %08lX\n", iffsize, (ULONG)iffsize);
#endif

  getname();
  if (name != HASH('L','W','O','B')) {
#ifdef WINDOWS
    MessageBox(NULL, "Not a LightWave Object file.", "Error", MB_OK);
#else
    fprintf(stderr, "Not a LightWave Object file!\n");
#endif
    return(0);
  }

  /* OK, this is a real LWOB file.  Allocate a structure for it */
  if (!(obj = EMEM(1, OBJ))) MEMERR("obj");
  memset(obj, 0, sizeof(OBJ));  /* Clear it out. */
  obj->next = head;
  head = obj;       /* Put it at the head of the list */

  while (iffsize > 0) {  /* Read in file */
    getname();
    size = (long)getulong();
#ifdef DEBUG
      fprintf(stderr, "Found '%c%c%c%c' chunk, size=%ld=%08lX.\n",
	    (char)((name>>24L)&0xFFL),
	    (char)((name>>16L)&0xFFL),
	    (char)((name>> 8L)&0xFFL),
	    (char)((name     )&0xFFL),
	    size, (ULONG)size);
#endif
    if(name == HASH('P','N','T','S')) {
      obj->numpnts = size / 12L;
#ifndef WINDOWS
#ifdef DEBUG
      fprintf(stderr, "Reading in %lu points...\n", obj->numpnts);
#endif
#endif
      if (!(obj->xyz  = EMEM(3*obj->numpnts, RtFloat))) MEMERR("xyz");
      if (output_normals) {
	if (!(obj->nxyz = EMEM(3*obj->numpnts, RtFloat))) MEMERR("nxyz");
	memset(obj->nxyz, 0, 3*obj->numpnts*sizeof(RtFloat));  /* Clear them out. */
      }
      obj->llx = obj->urx = obj->xyz[0] = getfloat();
      obj->lly = obj->ury = obj->xyz[1] = getfloat();
      obj->llz = obj->urz = obj->xyz[2] = getfloat();
      for (num=1, fp= &obj->xyz[3]; num < obj->numpnts; num++, fp+=3) {
	fp[0] = getfloat();
	fp[1] = getfloat();
	fp[2] = getfloat();
	if (fp[0] < obj->llx) obj->llx = fp[0];
	if (fp[0] > obj->urx) obj->urx = fp[0];
	if (fp[1] < obj->lly) obj->lly = fp[1];
	if (fp[1] > obj->ury) obj->ury = fp[1];
	if (fp[1] < obj->llz) obj->llz = fp[2];
	if (fp[1] > obj->urz) obj->urz = fp[2];
      }
#ifndef WINDOWS
      fprintf(stderr, "MBB: (%g,%g,%g)-(%g,%g,%g)\n",
            obj->llx, obj->lly, obj->llz,
            obj->urx, obj->ury, obj->urz);
#endif
      if (obj->llx < LLX) LLX = obj->llx;
      if (obj->urx > URX) URX = obj->urx;
      if (obj->lly < LLY) LLY = obj->lly;
      if (obj->ury > URY) URY = obj->ury;
      if (obj->llz < LLZ) LLZ = obj->llz;
      if (obj->urz > URZ) URZ = obj->urz;
      XCENTER = (URX + LLX) * 0.5;
      YCENTER = (URY + LLY) * 0.5;
      ZCENTER = (URZ + LLZ) * 0.5;
    } else if (name == HASH('S','R','F','S')) {  /* Read in surface names */
      if (size&1) size++;
      if (!(obj->surface_names = EMEM(size, char))) MEMERR("SRFS");
      last_null = 0;
      obj->numsurfs = 0;
      for (num=0; size; num++) {
	obj->surface_names[num] = getubyte();
	if (!obj->surface_names[num]) {
	  if (!last_null) {
	    obj->numsurfs++;
	    last_null = 1;
	  }
	} else last_null = 0;
      }
#ifndef WINDOWS
#ifdef DEBUG
      fprintf(stderr, "Found %d surface names.\n", obj->numsurfs);
#endif
#endif

      /* Now, create the array to hold all the surfaces */
      if (!(obj->surfaces = EMEM(obj->numsurfs+1, SURFACE*))) MEMERR("surfaces");

      /* Allocate structures for each one... */
      obj->surfaces[0] = 0;  /* Not a real surface... Index=1..N */
      last_null = 0;

      for (num=1; num <= obj->numsurfs; num++) {
	if (!(obj->surfaces[num] = EMEM(1, SURFACE))) MEMERR("surface");
	memset(obj->surfaces[num], 0, sizeof(SURFACE));
	obj->surfaces[num]->name = &obj->surface_names[last_null];
#ifndef WINDOWS
#ifdef DEBUG
      fprintf(stderr, " Surface #%lu: '%s'\n", num, obj->surfaces[num]->name);
#endif
#endif
	if (num < obj->numsurfs) {
	  while (obj->surface_names[last_null]) last_null++;
	  while (!obj->surface_names[last_null]) last_null++;
	}
      }
    } else if (name == HASH('P','O','L','S')) {  /* Read in polygon list */
      obj->num_poly_shorts = size >> 1L;
#ifndef WINDOWS
#ifdef DEBUG
      fprintf(stderr, "Reading in %lu shorts...\n", obj->num_poly_shorts);
#endif
#endif
      if (!(obj->polygon_list = EMEM(obj->num_poly_shorts, short))) MEMERR("poly");
      obj->num_polys = 0;
      count = 1;
      for (num = 0; num < obj->num_poly_shorts; num++) {
	obj->polygon_list[num] = getshort();
	if (!--count) {
	  obj->num_polys++;
	  count = obj->polygon_list[num] + 2;  /* +2 for count & surface number */
	}
      }
#ifndef WINDOWS
#ifdef DEBUG
      fprintf(stderr, "Found %lu individual polygons.\n", obj->num_polys);
#endif
#endif
    } else if (name == HASH('S','U','R','F')) {  /* Read in surface description */
      handle_surf();
    } else if (name == HASH('C','R','V','S')) {  /* Read in curves */
      obj->numcrvs = size >> 1L;
#ifndef WINDOWS
#ifdef DEBUG
      fprintf(stderr, "Reading in %lu shorts...\n", obj->numcrvs);
#endif
#endif
      if (!(obj->curves_list = EMEM(obj->numcrvs, short))) MEMERR("crvs");
      for (num = 0; num < obj->numcrvs; num++)
	obj->curves_list[num] = getshort();
    } else {
#ifndef WINDOWS
      fprintf(stderr, "Unknown chunk '%c%c%c%c', size=%ld=%08lX.  Skipping.\n",
            (char)((name>>24L)&0xFFL),
            (char)((name>>16L)&0xFFL),
            (char)((name>> 8L)&0xFFL),
            (char)((name     )&0xFFL),
            size, (ULONG)size);
#endif
      if (size&1) getubyte();
      while (size) getubyte();
    }
  }
#ifndef WINDOWS
#ifdef DEBUG
  fprintf(stderr, "Done reading object.\n");
#endif
#endif

  if (!output_normals) return(1);

#ifndef WINDOWS
#ifdef DEBUG
  fprintf(stderr, "Calculating vertex normals...\n");
#endif
#endif
  for (obj=head; obj; obj=obj->next) {
    /* First, loop through polygons and get a flat normal from them... */
    if (!(obj->poly_nx = EMEM(obj->num_polys, RtFloat))) MEMERR("poly_nx");
    if (!(obj->poly_ny = EMEM(obj->num_polys, RtFloat))) MEMERR("poly_ny");
    if (!(obj->poly_nz = EMEM(obj->num_polys, RtFloat))) MEMERR("poly_nz");
    count = 0;
    for (sp=obj->polygon_list, num=obj->num_poly_shorts; num; count++) {
      if (!*sp) {
#ifndef WINDOWS
	fprintf(stderr, "Hey Glenn!!  A 0-sided poly!\n");
#endif
	num--; sp++; continue;
      }

      obj->poly_nx[count] = 0.0;
      obj->poly_ny[count] = 0.0;
      obj->poly_nz[count] = 0.0;

      if(*sp > 2) { /* calculate normal */
	v1[0]=obj->xyz[3*(*(sp+1))  ];
	v1[1]=obj->xyz[3*(*(sp+1))+1];
	v1[2]=obj->xyz[3*(*(sp+1))+2];
	v2[0]=obj->xyz[3*(*(sp+2))  ];
	v2[1]=obj->xyz[3*(*(sp+2))+1];
	v2[2]=obj->xyz[3*(*(sp+2))+2];
	v3[0]=obj->xyz[3*(*(sp+3))  ];
	v3[1]=obj->xyz[3*(*(sp+3))+1];
	v3[2]=obj->xyz[3*(*(sp+3))+2];
	if (getnormal(v1,v2,v3,nn)) {
	  obj->poly_nx[count] = nn[0];
	  obj->poly_ny[count] = nn[1];
	  obj->poly_nz[count] = nn[2];
#ifdef MEGADEBUG
          fprintf(stderr, "%d-poly #%ld, normal=(%g,%g,%g)\n",
		  *sp, count, (double)nn[0], (double)nn[1], (double)nn[2]);
#endif
	}
      }

      for (i = *sp++, num--; i--; ) {
	obj->nxyz[3*(*sp)  ] += obj->poly_nx[count];
	obj->nxyz[3*(*sp)+1] += obj->poly_ny[count];
	obj->nxyz[3*(*sp)+2] += obj->poly_nz[count];
	sp++; num--;
      }
      sp++; num--;  /* Skip surface number */
    }

#ifndef WINDOWS
#ifdef DEBUG
    fprintf(stderr, "Normalizing vertex normals...\n");
#endif
#endif

      /* Now, loop through vertices and normalize */
      for (num=obj->numpnts, fp= &obj->nxyz[0]; num--; fp+=3)
	normalize(fp);
  }
#ifndef WINDOWS
#ifdef DEBUG
  fprintf(stderr, "Done calculating vertex normals.\n");
#endif
#endif
  return(1);  /* Success */
}

void render_objects(void)
{
  register OBJ *obj;
  register short *sp;
  register ULONG num;
  short *psurf;
  SURFACE *surf;
  short i;
  int is_color;
  RtInt *nloops, *nverts, *verts;
  RtInt *np, *vp, j;
  RtFloat* fp;

#ifdef MEGADEBUG
    fprintf(stderr, "Drawing object...\n");
#endif

/*  RiBegin(RI_NULL); */

  for (obj=head; obj; obj=obj->next) {

    if (!(nloops = EMEM(obj->num_polys, RtInt))) MEMERR("nloops");
    for (np=nloops, j=obj->num_polys; j--; ) *np++ = 1;  /* All have 1 loop */
    if (!(np = nverts = EMEM(obj->num_polys, RtInt))) MEMERR("nverts");
    if (!(vp = verts  = EMEM(obj->num_poly_shorts-2*obj->num_polys, RtInt))) MEMERR("verts");


    for (sp=obj->polygon_list, num=obj->num_poly_shorts; num; ) {
      if (!*sp) {
#ifndef WINDOWS
	fprintf(stderr, "Hey Glenn!!  A 0-sided poly!\n");
#endif
	num--;
	sp++;
	continue;
      }

      psurf = sp + 1 + (*sp);
      i = *psurf;
      if (i < 0) i = -i;
      if (i && (surf = obj->surfaces[i])) {  /* Set surface attributes here */
	is_color = 1;
      } else {   /* No surface assigned */
	is_color = 0;
      }

      *np++ = *sp;
      if (*sp < 256)
	stats[*sp]++;
      else if (statistics)
	fprintf(stderr, "Woah!  A %d-point polygon!\n", *sp);

      for (i = *sp++, num--; i--; ) {
	*vp++ = *sp;
	sp++; num--;
      }
      sp++; num--;  /* Skip surface number */
    }

    /* The reason I use RiPointGeneralPolygons instead of RiPointPolygons
     * is because LW uses convex *and* concave polygons
     */
      /* RiPointsGeneralPolygons(obj->num_polys,
			      nloops,
			      nverts,
			      verts,
			      "P", obj->xyz,
			      "N", obj->nxyz,
			      RI_NULL); */
      fprintf(stdout, "sub obj {\n");
      fprintf(stdout, "  my $obj;\n");
      fprintf(stdout, "  $obj->{nloops} = [\n");
      for (np=nloops, j=obj->num_polys; j--; )
	fprintf(stdout, "%ld,\n", *np++);
      fprintf(stdout, "  ];\n\n");
      fprintf(stdout, "  $obj->{nverts} = [\n");
      for (np=nverts, j=obj->num_polys; j--; )
	fprintf(stdout, "%ld,\n", *np++);
      fprintf(stdout, "  ];\n\n");
      fprintf(stdout, "  $obj->{verts} = [\n");
      for (np=verts, j=obj->num_poly_shorts-2*obj->num_polys; j--; )
	fprintf(stdout, "%ld,\n", *np++);
      fprintf(stdout, "  ];\n\n");
      fprintf(stdout, "  $obj->{P} = [\n");
      for (fp=obj->xyz, j=obj->numpnts; j--; )
	fprintf(stdout, "%g,%g,%g,\n", *fp++, *fp++, *fp++);
      fprintf(stdout, "  ];\n\n");
      if (output_normals) {
	fprintf(stdout, "  $obj->{N} = [\n");
	for (fp=obj->nxyz, j=obj->numpnts; j--; )
	  fprintf(stdout, "%g,%g,%g,\n", *fp++, *fp++, *fp++);
	fprintf(stdout, "  ];\n\n");
      }
      fprintf(stdout, "  return $obj;\n}\n\n");
      /* RiPointsGeneralPolygons(obj->num_polys,
			      nloops,
			      nverts,
			      verts,
			      "P", obj->xyz,
			      RI_NULL); */

    EFREE(verts);
    EFREE(nverts);
    EFREE(nloops);
  }

/*  RiEnd(); */
#ifdef MEGADEBUG
    fprintf(stderr, "Done.\n");
#endif
}

int main(int argc, char *argv[])
{
  int i;
  int file_count = 0;

  LLX = LLY = LLZ =  1.0e10;
  URX = URY = URZ = -1.0e10;

  for (i=256; i--; ) stats[i] = 0;  /* Zero-out histogram */

  for (i=1; i<argc; i++) {
    if (argv[i][0] == '-') {
      switch(argv[i][1]) {
      case 'n': output_normals = 0; break;
      case 'c': use_color = 0; break;
      case 's': statistics = 1; break;
      default:
	fprintf(stderr, "Unknown option '%s' ignored.\n", argv[i]);
      }
    } else {
      if (!(inp = fopen(argv[i], "rb"))) {
	fprintf(stderr, "Can't open file '%s' for input.  Skipped.\n",
		argv[i]);
	continue;
      }
      /* Opened the file... read it */
      fprintf(stderr, "Reading file '%s'...\n", argv[i]);
      file_count++;
      read_file();
      fclose(inp);
    }
  }
  if (!file_count) {  /* Read from standard input */
    inp = stdin;
    read_file();
  }

  render_objects();

  if (statistics)
    for (i=0; i<256; i++)
      if (stats[i])
	fprintf(stderr, "%d-point polygons: %ld\n", i, stats[i]);

  return(0);
}
