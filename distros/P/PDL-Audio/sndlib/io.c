/* IO handlers */
/*
 * --------------------------------
 * int mus_create_descriptors (void): initialize (allocate) various global arrays
 * int mus_read(int fd, int beg, int end, int chans, int **bufs)
 * int mus_write(int tfd, int beg, int end, int chans, int **bufs)
 * long mus_seek(int tfd, long offset, int origin)
 * int mus_open_read(char *arg) 
 * int mus_open_write(char *arg)
 * int mus_create(char *arg)
 * int mus_reopen_write(char *arg)
 * int mus_close(int fd)
 * int mus_probe_file(char *arg)
 * int mus_open_file_descriptors (int tfd, int df, int ds, int dl)
 * int mus_close_file_descriptors(int tfd)
 * see sndplay.c for a short example
 * --------------------------------
 */

#if defined(HAVE_CONFIG_H)
  #include "config.h"
#endif

#include <math.h>
#include <stdio.h>
#if (!defined(HAVE_CONFIG_H)) || (defined(HAVE_FCNTL_H))
  #include <fcntl.h>
#endif
#include <signal.h>
#if (!defined(HAVE_CONFIG_H)) || (defined(HAVE_LIMITS_H))
  #include <limits.h>
#endif
#include <errno.h>
#include <stdlib.h>

#if (defined(NEXT) || (defined(HAVE_LIBC_H) && (!defined(HAVE_UNISTD_H))))
  #include <libc.h>
#else
  #if (!(defined(_MSC_VER))) && (!(defined(MPW_C)))
    #include <unistd.h>
  #endif
#endif
#if (!defined(HAVE_CONFIG_H)) || (defined(HAVE_STRING_H))
  #include <string.h>
#endif

#if (defined(SIZEOF_INT) && (SIZEOF_INT != 4)) || (defined(INT_MAX) && (INT_MAX != 2147483647))
  #error sndlib C code assumes 32-bit ints
#endif

#if (defined(SIZEOF_LONG) && (SIZEOF_LONG < 4)) || (defined(LONG_MAX) && (LONG_MAX < 2147483647))
  #error sndlib C code assumes longs are at least 32 bits
#endif

#if (defined(SIZEOF_SHORT) && (SIZEOF_SHORT != 2)) || (defined(SHRT_MAX) && (SHRT_MAX != 32767))
  #error sndlib C code assumes 16-bit shorts
#endif

#if (defined(SIZEOF_CHAR) && (SIZEOF_CHAR != 1)) || (defined(CHAR_BIT) && (CHAR_BIT != 8))
  #error sndlib C code assumes 8-bit chars
#endif

#include "sndlib.h"

/* data translations for big/little endian machines -- the m_* forms are macros where possible for speed */

void mus_set_big_endian_int(unsigned char *j, int x)
{
  unsigned char *ox;
  ox=(unsigned char *)&x;
#ifdef SNDLIB_LITTLE_ENDIAN
  j[0]=ox[3]; j[1]=ox[2]; j[2]=ox[1]; j[3]=ox[0];
#else
  j[0]=ox[0]; j[1]=ox[1]; j[2]=ox[2]; j[3]=ox[3];
#endif
}

int mus_big_endian_int (unsigned char *inp)
{
  int o;
  unsigned char *outp;
  outp=(unsigned char *)&o;
#ifdef SNDLIB_LITTLE_ENDIAN
  outp[0]=inp[3]; outp[1]=inp[2]; outp[2]=inp[1]; outp[3]=inp[0];
#else
  outp[0]=inp[0]; outp[1]=inp[1]; outp[2]=inp[2]; outp[3]=inp[3];
#endif
  return(o);
}

void mus_set_little_endian_int(unsigned char *j, int x)
{
  unsigned char *ox;
  ox=(unsigned char *)&x;
#ifndef SNDLIB_LITTLE_ENDIAN
  j[0]=ox[3]; j[1]=ox[2]; j[2]=ox[1]; j[3]=ox[0];
#else
  j[0]=ox[0]; j[1]=ox[1]; j[2]=ox[2]; j[3]=ox[3];
#endif
}

int mus_little_endian_int (unsigned char *inp)
{
  int o;
  unsigned char *outp;
  outp=(unsigned char *)&o;
#ifndef SNDLIB_LITTLE_ENDIAN
  outp[0]=inp[3]; outp[1]=inp[2]; outp[2]=inp[1]; outp[3]=inp[0];
#else
  outp[0]=inp[0]; outp[1]=inp[1]; outp[2]=inp[2]; outp[3]=inp[3];
#endif
  return(o);
}

int mus_uninterpreted_int (unsigned char *inp)
{
  int o;
  unsigned char *outp;
  outp=(unsigned char *)&o;
  outp[0]=inp[0]; outp[1]=inp[1]; outp[2]=inp[2]; outp[3]=inp[3];
  return(o);
}

unsigned int mus_big_endian_unsigned_int (unsigned char *inp)
{
  unsigned int o;
  unsigned char *outp;
  outp=(unsigned char *)&o;
#ifdef SNDLIB_LITTLE_ENDIAN
  outp[0]=inp[3]; outp[1]=inp[2]; outp[2]=inp[1]; outp[3]=inp[0];
#else
  outp[0]=inp[0]; outp[1]=inp[1]; outp[2]=inp[2]; outp[3]=inp[3];
#endif
  return(o);
}

unsigned int mus_little_endian_unsigned_int (unsigned char *inp)
{
  unsigned int o;
  unsigned char *outp;
  outp=(unsigned char *)&o;
#ifndef SNDLIB_LITTLE_ENDIAN
  outp[0]=inp[3]; outp[1]=inp[2]; outp[2]=inp[1]; outp[3]=inp[0];
#else
  outp[0]=inp[0]; outp[1]=inp[1]; outp[2]=inp[2]; outp[3]=inp[3];
#endif
  return(o);
}


void mus_set_big_endian_float(unsigned char *j, float x)
{
  unsigned char *ox;
  ox=(unsigned char *)&x;
#ifdef SNDLIB_LITTLE_ENDIAN
  j[0]=ox[3]; j[1]=ox[2]; j[2]=ox[1]; j[3]=ox[0];
#else
  j[0]=ox[0]; j[1]=ox[1]; j[2]=ox[2]; j[3]=ox[3];
#endif
}

float mus_big_endian_float (unsigned char *inp)
{
  float o;
  unsigned char *outp;
  outp=(unsigned char *)&o;
#ifdef SNDLIB_LITTLE_ENDIAN
  outp[0]=inp[3]; outp[1]=inp[2]; outp[2]=inp[1]; outp[3]=inp[0];
#else
  outp[0]=inp[0]; outp[1]=inp[1]; outp[2]=inp[2]; outp[3]=inp[3];
#endif
  return(o);
}

void mus_set_little_endian_float(unsigned char *j, float x)
{
  unsigned char *ox;
  ox=(unsigned char *)&x;
#ifndef SNDLIB_LITTLE_ENDIAN
  j[0]=ox[3]; j[1]=ox[2]; j[2]=ox[1]; j[3]=ox[0];
#else
  j[0]=ox[0]; j[1]=ox[1]; j[2]=ox[2]; j[3]=ox[3];
#endif
}

float mus_little_endian_float (unsigned char *inp)
{
  float o;
  unsigned char *outp;
  outp=(unsigned char *)&o;
#ifndef SNDLIB_LITTLE_ENDIAN
  outp[0]=inp[3]; outp[1]=inp[2]; outp[2]=inp[1]; outp[3]=inp[0];
#else
  outp[0]=inp[0]; outp[1]=inp[1]; outp[2]=inp[2]; outp[3]=inp[3];
#endif
  return(o);
}

void mus_set_big_endian_short(unsigned char *j, short x)
{
  unsigned char *ox;
  ox=(unsigned char *)&x;
#ifdef SNDLIB_LITTLE_ENDIAN
  j[0]=ox[1]; j[1]=ox[0];
#else
  j[0]=ox[0]; j[1]=ox[1];
#endif
}

short mus_big_endian_short (unsigned char *inp)
{
  short o;
  unsigned char *outp;
  outp=(unsigned char *)&o;
#ifdef SNDLIB_LITTLE_ENDIAN
  outp[0]=inp[1]; outp[1]=inp[0];
#else
  outp[0]=inp[0]; outp[1]=inp[1];
#endif
  return(o);
}

void mus_set_little_endian_short(unsigned char *j, short x)
{
  unsigned char *ox;
  ox=(unsigned char *)&x;
#ifndef SNDLIB_LITTLE_ENDIAN
  j[0]=ox[1]; j[1]=ox[0];
#else
  j[0]=ox[0]; j[1]=ox[1];
#endif
}

short mus_little_endian_short (unsigned char *inp)
{
  short o;
  unsigned char *outp;
  outp=(unsigned char *)&o;
#ifndef SNDLIB_LITTLE_ENDIAN
  outp[0]=inp[1]; outp[1]=inp[0];
#else
  outp[0]=inp[0]; outp[1]=inp[1];
#endif
  return(o);
}

void mus_set_big_endian_unsigned_short(unsigned char *j, unsigned short x)
{
  unsigned char *ox;
  ox=(unsigned char *)&x;
#ifdef SNDLIB_LITTLE_ENDIAN
  j[0]=ox[1]; j[1]=ox[0];
#else
  j[0]=ox[0]; j[1]=ox[1];
#endif
}

unsigned short mus_big_endian_unsigned_short (unsigned char *inp)
{
  unsigned short o;
  unsigned char *outp;
  outp=(unsigned char *)&o;
#ifdef SNDLIB_LITTLE_ENDIAN
  outp[0]=inp[1]; outp[1]=inp[0];
#else
  outp[0]=inp[0]; outp[1]=inp[1];
#endif
  return(o);
}

void mus_set_little_endian_unsigned_short(unsigned char *j, unsigned short x)
{
  unsigned char *ox;
  ox=(unsigned char *)&x;
#ifndef SNDLIB_LITTLE_ENDIAN
  j[0]=ox[1]; j[1]=ox[0];
#else
  j[0]=ox[0]; j[1]=ox[1];
#endif
}

unsigned short mus_little_endian_unsigned_short (unsigned char *inp)
{
  unsigned short o;
  unsigned char *outp;
  outp=(unsigned char *)&o;
#ifndef SNDLIB_LITTLE_ENDIAN
  outp[0]=inp[1]; outp[1]=inp[0];
#else
  outp[0]=inp[0]; outp[1]=inp[1];
#endif
  return(o);
}

double mus_little_endian_double (unsigned char *inp)
{
  double o;
#ifndef SNDLIB_LITTLE_ENDIAN
  int i;
#endif
  unsigned char *outp;
  outp=(unsigned char *)&o;
#ifndef SNDLIB_LITTLE_ENDIAN
  for (i=0;i<8;i++) outp[i]=inp[i];
#else
  outp[0]=inp[7]; outp[1]=inp[6]; outp[2]=inp[5]; outp[3]=inp[4]; outp[4]=inp[3]; outp[5]=inp[2]; outp[6]=inp[1]; outp[7]=inp[0];
#endif
  return(o);
}

double mus_big_endian_double (unsigned char *inp)
{
  double o;
#ifdef SNDLIB_LITTLE_ENDIAN
  int i;
#endif
  unsigned char *outp;
  outp=(unsigned char *)&o;
#ifndef SNDLIB_LITTLE_ENDIAN
  outp[0]=inp[7]; outp[1]=inp[6]; outp[2]=inp[5]; outp[3]=inp[4]; outp[4]=inp[3]; outp[5]=inp[2]; outp[6]=inp[1]; outp[7]=inp[0];
#else
  for (i=0;i<8;i++) outp[i]=inp[i];
#endif
  return(o);
}

void mus_set_big_endian_double(unsigned char *j, double x)
{
#ifdef SNDLIB_LITTLE_ENDIAN
  int i;
#endif
  unsigned char *ox;
  ox=(unsigned char *)&x;
#ifndef SNDLIB_LITTLE_ENDIAN
  j[0]=ox[7]; j[1]=ox[6]; j[2]=ox[5]; j[3]=ox[4]; j[4]=ox[3]; j[5]=ox[2]; j[6]=ox[1]; j[7]=ox[0];
#else
  for (i=0;i<8;i++) j[i]=ox[i];
#endif
}

void mus_set_little_endian_double(unsigned char *j, double x)
{
#ifndef SNDLIB_LITTLE_ENDIAN
  int i;
#endif
  unsigned char *ox;
  ox=(unsigned char *)&x;
#ifndef SNDLIB_LITTLE_ENDIAN
  for (i=0;i<8;i++) j[i]=ox[i];
#else
  j[0]=ox[7]; j[1]=ox[6]; j[2]=ox[5]; j[3]=ox[4]; j[4]=ox[3]; j[5]=ox[2]; j[6]=ox[1]; j[7]=ox[0];
#endif
}

/* Vax float translation taken from Mosaic libdtm/vaxcvt.c */
static float from_vax_float(unsigned char *inp)
{
  unsigned char exp;
  unsigned char c0, c1, c2, c3;
  float o;
  unsigned char *outp;
  outp=(unsigned char *)&o;
  c0 = inp[0]; c1 = inp[1]; c2 = inp[2]; c3 = inp[3];
  exp = (c1 << 1) | (c0 >> 7);             /* extract exponent */
  if (!exp && !c1) return(0.0);            /* zero value */
  else if (exp>2) {                        /* normal value */
    outp[0] = c1 - 1;                      /* subtracts 2 from exponent */
    outp[1] = c0;                          /* copy mantissa, LSB of exponent */
    outp[2] = c3;
    outp[3] = c2;}
  else if (exp) {                          /* denormalized number */
    unsigned int shft;
    outp[0] = c1 & 0x80;                   /* keep sign, zero exponent */
    shft = 3 - exp;
    /* shift original mant by 1 or 2 to get denormalized mant */
    /* prefix mantissa with '1'b or '01'b as appropriate */
    outp[1] = ((c0 & 0x7f) >> shft) | (0x10 << exp);
    outp[2] = (c0 << (8-shft)) | (c3 >> shft);
    outp[3] = (c3 << (8-shft)) | (c2 >> shft);}
  else {                                   /* sign=1 -> infinity or NaN */
    outp[0] = 0xff;                        /* set exp to 255 */
    outp[1] = c0 | 0x80;                   /* LSB of exp = 1 */
    outp[2] = c3;
    outp[3] = c2;}
  return(o);
}

#if USE_BYTESWAP
  #include <byteswap.h>
  /* in fully optimized code, the byteswap macros are about 15% faster than the calls used here */
#endif

#ifdef SNDLIB_LITTLE_ENDIAN

#if USE_BYTESWAP
  #define m_big_endian_short(n)                   ((short)(bswap_16((*((unsigned short *)n)))))
  #define m_big_endian_int(n)                     ((int)(bswap_32((*((unsigned int *)n)))))
#else
  #define m_big_endian_short(n)                   (mus_big_endian_short(n))
  #define m_big_endian_int(n)                     (mus_big_endian_int(n))
#endif
  #define m_big_endian_float(n)                   (mus_big_endian_float(n))
  #define m_big_endian_double(n)                  (mus_big_endian_double(n))
  #define m_big_endian_unsigned_short(n)          (mus_big_endian_unsigned_short(n))

  #define m_little_endian_short(n)                (*((short *)n))
  #define m_little_endian_int(n)                  (*((int *)n))
  #define m_little_endian_float(n)                (*((float *)n))
  #define m_little_endian_double(n)               (*((double *)n))
  #define m_little_endian_unsigned_short(n)       (*((unsigned short *)n))

  #define m_set_big_endian_short(n,x)             mus_set_big_endian_short(n,x)
  #define m_set_big_endian_int(n,x)               mus_set_big_endian_int(n,x)
  #define m_set_big_endian_float(n,x)             mus_set_big_endian_float(n,x)
  #define m_set_big_endian_double(n,x)            mus_set_big_endian_double(n,x)
  #define m_set_big_endian_unsigned_short(n,x)    mus_set_big_endian_unsigned_short(n,x)

  #define m_set_little_endian_short(n,x)          (*((short *)n)) = x
  #define m_set_little_endian_int(n,x)            (*((int *)n)) = x
  #define m_set_little_endian_float(n,x)          (*((float *)n)) = x
  #define m_set_little_endian_double(n,x)         (*((double *)n)) = x
  #define m_set_little_endian_unsigned_short(n,x) (*((unsigned short *)n)) = x

#else

  #ifndef SUN
    #define m_big_endian_short(n)                   (*((short *)n))
    #define m_big_endian_int(n)                     (*((int *)n))
    #define m_big_endian_float(n)                   (*((float *)n))
    #define m_big_endian_double(n)                  (*((double *)n))
    #define m_big_endian_unsigned_short(n)          (*((unsigned short *)n))

    #define m_set_big_endian_short(n,x)             (*((short *)n)) = x
    #define m_set_big_endian_int(n,x)               (*((int *)n)) = x
    #define m_set_big_endian_float(n,x)             (*((float *)n)) = x
    #define m_set_big_endian_double(n,x)            (*((double *)n)) = x
    #define m_set_big_endian_unsigned_short(n,x)    (*((unsigned short *)n)) = x
  #else
    #define m_big_endian_short(n)                   (mus_big_endian_short(n))
    #define m_big_endian_int(n)                     (mus_big_endian_int(n))
    #define m_big_endian_float(n)                   (mus_big_endian_float(n))
    #define m_big_endian_double(n)                  (mus_big_endian_double(n))
    #define m_big_endian_unsigned_short(n)          (mus_big_endian_unsigned_short(n))

    #define m_set_big_endian_short(n,x)             mus_set_big_endian_short(n,x)
    #define m_set_big_endian_int(n,x)               mus_set_big_endian_int(n,x)
    #define m_set_big_endian_float(n,x)             mus_set_big_endian_float(n,x)
    #define m_set_big_endian_double(n,x)            mus_set_big_endian_double(n,x)
    #define m_set_big_endian_unsigned_short(n,x)    mus_set_big_endian_unsigned_short(n,x)
  #endif

#if USE_BYTESWAP
  #define m_little_endian_short(n)                  ((short)(bswap_16((*((unsigned short *)n)))))
  #define m_little_endian_int(n)                    ((int)(bswap_32((*((unsigned int *)n)))))
#else
  #define m_little_endian_short(n)                  (mus_little_endian_short(n))
  #define m_little_endian_int(n)                    (mus_little_endian_int(n))
#endif
  #define m_little_endian_float(n)                  (mus_little_endian_float(n))
  #define m_little_endian_double(n)                 (mus_little_endian_double(n))
  #define m_little_endian_unsigned_short(n)         (mus_little_endian_unsigned_short(n))

  #define m_set_little_endian_short(n,x)            mus_set_little_endian_short(n,x)
  #define m_set_little_endian_int(n,x)              mus_set_little_endian_int(n,x)
  #define m_set_little_endian_float(n,x)            mus_set_little_endian_float(n,x)
  #define m_set_little_endian_double(n,x)           mus_set_little_endian_double(n,x)
  #define m_set_little_endian_unsigned_short(n,x)   mus_set_little_endian_unsigned_short(n,x)

#endif


/* ---------------- file descriptors ----------------
 *
 * I'm using unbuffered IO here because it is faster on the machines I normally use,
 * and I'm normally doing very large reads/writes (that is, the stuff is self-buffered).
 *
 *   machine                     read/write:              fread/fwrite:             arithmetic: 
 *                               256   512   8192  65536  same sizes                tbl   bigfft sffts
 *
 * NeXT 68040 (32MB):            11575 10514 10256  9943  11951 11923 12358 12259   10478 108122 26622
 * NeXT Turbo (16MB):             8329  7760  6933  6833   9216  8742  9416  9238    7825 121591 19495
 * HP 90MHz Pentium NextStep:    11970 10069  9840  9920  11930 11209 11399 11540    1930  46389  4019
 * Mac 8500 120 MHz PPC MacOS:   21733 15416  5000  2916   9566  9550  9733  9850    <died in memory manager>
 * Mac G3 266 MHz PPC MacOS:      4866  3216  1850  1366   2400  2400  2366  2450     550  12233   700
 * MkLinux G3 266 MHz:             580   462   390   419    640   631   552   500     485  11364   770
 * LinuxPPC G3 266 MHz:            456   385   366   397    489   467   467   487     397  11808   763
 * Mac clone 120 MHz PPC BeOS:    1567   885   725  3392   1015  1000  1114  1161    1092  37212  1167
 * SGI R4600 132 MHz Indy (32MB): 2412  1619   959  1045   1172  1174  1111  1126    1224  30825  3490
 * SGI R5000 150 MHz Indy (32MB): 1067   846   684   737    847   817   734   791     885  25878  1591
 * SGI R5000 180 MHz O2 (64MB):   1359   788   431   446   1919  1944  1891  1885     828  24658  1390
 * Sun Ultra5 270 MHz (128 MB):    981   880   796   827    965  1029   922   903     445  26791   691
 * HP 200 MHz Pentium Linux:       576   492   456   482    615   613   599   592     695  14851   882
 * Asus 266 MHz Pentium II Linux:  475   426   404   406    466   455   467   465     490  13170   595
 * ditto W95:                     1320   660   600   550   2470  2470  2470  2470     990  17410  1540
 * Dell XPSD300 Pentium II Linux:  393   350   325   332    376   369   397   372     414   8793   576
 * 450MHz PC Linux:                263   227   208   217    268   263   274   270     275   6224   506
 *
 * the first 8 numbers are comparing read/write fread/fwrite at various buffer sizes -- CLM uses 65536.
 * the last 3 numbers are comparing table lookup, a huge fft, and a bunch of small ffts.
 * In normal CLM usage, small instruments and mixes are IO bound, so these differences can matter.
 * The reason to use 65536 rather than 8192 is that it allows us to forgo IO completely in
 * many cases -- the output buffer can collect many notes before flushing, etc.
 */

#if defined(SGI) || defined(LINUX) || defined(UW2) || defined(SCO5)
  #define FILE_DESCRIPTORS 400
  #define BASE_FILE_DESCRIPTORS 200
#else
  #define FILE_DESCRIPTORS 128
  #define BASE_FILE_DESCRIPTORS 64
#endif

/* this from the glibc FAQ: 
 *   You can always get the maximum number of file descriptors a process is
 *   allowed to have open at any time using number = sysconf (_SC_OPEN_MAX)
 */

static int io_descriptors_ok = 0;
static int *io_data_format,*io_bytes_per_sample,*io_data_location,*io_files,*io_data_clipped,*io_chans,*io_header_type;
static int io_files_ready = 0;
static int max_descriptor = 0;

static int rt_ap_out;   /* address of RT audio ports, if any */

#ifdef CLM
void set_rt_audio_p (int rt)
{
  rt_ap_out = rt;
}
#endif

int mus_create_descriptors (void)
{
  if (!io_descriptors_ok)
    {
      io_descriptors_ok = 1;
      max_descriptor = 0;
      io_data_format = (int *)CALLOC(FILE_DESCRIPTORS,sizeof(int));
      io_bytes_per_sample = (int *)CALLOC(FILE_DESCRIPTORS,sizeof(int));
      io_data_clipped = (int *)CALLOC(FILE_DESCRIPTORS,sizeof(int));
      io_header_type = (int *)CALLOC(FILE_DESCRIPTORS,sizeof(int));
      io_chans = (int *)CALLOC(FILE_DESCRIPTORS,sizeof(int));
      io_data_location = (int *)CALLOC(FILE_DESCRIPTORS,sizeof(int));
      io_files = (int *)CALLOC(BASE_FILE_DESCRIPTORS,sizeof(int));
      if ((io_data_format == NULL) || (io_bytes_per_sample == NULL) || (io_data_location == NULL) || (io_files == NULL) ||
	  (io_data_clipped == NULL) || (io_header_type == NULL))
	{
	  mus_error(MUS_MEMORY_ALLOCATION_FAILED,"file descriptor buffer allocation trouble");
	  return(-1);
	}
    }
  return(0);
}

static int convert_fd(int n)
{
  if (n<BASE_FILE_DESCRIPTORS)
    return(n);
  else
    {
      int i;
      for (i=0;i<BASE_FILE_DESCRIPTORS;i++)
	{
	  if (io_files[i] == n) return(i+BASE_FILE_DESCRIPTORS);
	}
      return(-1);
    }
}

static int open_mus_file (int tfd)
{
  int fd;
  if (tfd < BASE_FILE_DESCRIPTORS) return(tfd);
  if (io_files_ready == 0)
    {
      for (fd=0;fd<BASE_FILE_DESCRIPTORS;fd++) io_files[fd]=-1;
      io_files_ready = 1;
    }
  for (fd=0;fd<BASE_FILE_DESCRIPTORS;fd++)
    {
      if (io_files[fd] == -1)
	{
	  io_files[fd] = tfd;
	  return(fd+BASE_FILE_DESCRIPTORS);
	}
    }
  return(-1);
}

int mus_open_file_descriptors (int tfd, int format, int size, int location)
{ /* transfers header info from functions in header.c back to us for reads here and in merge.c */
  int fd;
  if (!io_descriptors_ok) return(-1);
  fd = open_mus_file(tfd);
  if (fd == -1) return(-1);
  io_data_format[fd] = format;
  io_bytes_per_sample[fd] = size;
  io_data_location[fd] = location;
  io_data_clipped[fd] = 0;
  io_header_type[fd] = 0;
  io_chans[fd] = 1;
  if (fd > max_descriptor) max_descriptor = fd;
  return(0);
}

int mus_set_file_descriptors (int tfd, int format, int size, int location, int chans, int type)
{
  /* new form to make sound.c handlers cleaner, 4-Sep-99 */
  int fd;
  if (!io_descriptors_ok) return(-1);
  fd = open_mus_file(tfd);
  if (fd == -1) return(-1);
  io_data_format[fd] = format;
  io_bytes_per_sample[fd] = size;
  io_data_location[fd] = location;
  io_header_type[fd] = type;
  io_data_clipped[fd] = 0;
  io_chans[fd] = chans;
  if (fd > max_descriptor) max_descriptor = fd;
  return(0);
}

int mus_close_file_descriptors(int tfd)
{
  int fd;
  if (!io_descriptors_ok) return(0); /* not necessarily an error -- c-close before with-sound etc */
  fd = convert_fd(tfd);
  if (fd >= 0)
    {
      if (fd >= BASE_FILE_DESCRIPTORS)
	io_files[fd-BASE_FILE_DESCRIPTORS] = -1;
      io_data_format[fd]=SNDLIB_NO_SND;
      io_header_type[fd] = 0;
      io_data_clipped[fd] = 0;
      io_chans[fd] = 0;
      return(0);
    }
  return(-1);
}

int mus_cleanup_file_descriptors(void)
{
  /* error cleanup -- try to find C-opened files that are invisible to lisp and close them */
  int fd,lim;
  if (!io_descriptors_ok) return(0);
  lim = BASE_FILE_DESCRIPTORS-1;
  if (max_descriptor < lim) lim = max_descriptor;
  for (fd=0;fd<=lim;fd++)
    if (io_data_format[fd] != SNDLIB_NO_SND) mus_close(fd);
  if ((io_files_ready) && (max_descriptor > BASE_FILE_DESCRIPTORS))
    {
      lim = max_descriptor - BASE_FILE_DESCRIPTORS;
      if (lim >= BASE_FILE_DESCRIPTORS) lim = BASE_FILE_DESCRIPTORS - 1;
      for (fd=0;fd<=lim;fd++)
	if (io_files[fd] != -1)
	  mus_close(io_files[fd]);
    }
  return(0);
}

int mus_set_data_clipped (int tfd, int clipped)
{
  int fd;
  if (!io_descriptors_ok) return(0);
  fd = convert_fd(tfd);
  if (fd < 0) return(-1);
  io_data_clipped[fd] = clipped;
  return(0);
}

int mus_set_header_type (int tfd, int type)
{
  int fd;
  if (!io_descriptors_ok) return(0);
  fd = convert_fd(tfd);
  if (fd < 0) return(-1);
  io_header_type[fd] = type;
  return(0);
}

int mus_get_header_type(int tfd)
{
  int fd;
  if (!io_descriptors_ok) return(0);
  fd = convert_fd(tfd);
  if (fd < 0) return(-1);
  return(io_header_type[fd]);
}

int mus_set_chans (int tfd, int chans)
{
  int fd;
  if (!io_descriptors_ok) return(0);
  fd = convert_fd(tfd);
  if (fd < 0) return(-1);
  io_chans[fd] = chans;
  return(0);
}


/* ---------------- open, creat, close ---------------- */

int mus_open_read(char *arg) 
{
#ifdef MACOS
  return(open (arg, O_RDONLY));
#else
  int fd;
  #ifdef WINDOZE
    fd = open (arg, O_RDONLY | O_BINARY);
  #else
    fd = open (arg, O_RDONLY, 0);
  #endif
  return(fd);
#endif
}

int mus_probe_file(char *arg) 
{
  int fd;
#ifdef MACOS
  fd = (open (arg, O_RDONLY));
#else
  #ifdef WINDOZE
    fd = open (arg, O_RDONLY | O_BINARY);
  #else
    #ifdef O_NONBLOCK
      fd = open(arg,O_RDONLY,O_NONBLOCK);
    #else
      fd = open(arg,O_RDONLY,0);
    #endif
  #endif
#endif
  if (fd == -1) return(0);
  close(fd);
  return(1);
}

int mus_open_write(char *arg)
{
  int fd;
#ifdef MACOS
  if ((fd = open(arg,O_RDWR)) == -1)
  #ifdef MPW_C
    fd = creat(arg);
  #else
    fd = creat(arg, 0);
  #endif
  else
    lseek(fd,0L,SEEK_END);
#else
  #ifdef WINDOZE
    if ((fd = open(arg,O_RDWR | O_BINARY)) == -1)
  #else
    if ((fd = open(arg,O_RDWR,0)) == -1)
  #endif
      {
        fd = creat(arg,0666);  /* equivalent to the new open(arg,O_RDWR | O_CREAT | O_TRUNC, 0666) */
      }
    else
      lseek(fd,0L,SEEK_END);
#endif
  return(fd);
}

int mus_create(char *arg)
{
#ifdef MACOS
  #ifdef MPW_C
    return(creat(arg));
  #else
    return(creat(arg,0));
  #endif
#else
  int fd;
  fd = creat(arg,0666);
  return(fd);
#endif
}

int mus_reopen_write(char *arg)
{
#ifdef MACOS
  return(open(arg,O_RDWR));
#else
  int fd;
  #ifdef WINDOZE
    fd = open(arg,O_RDWR | O_BINARY);
  #else
    fd = open(arg,O_RDWR,0);
  #endif
  return(fd);
#endif
}

int mus_close(int fd)
{
  mus_close_file_descriptors(fd);
  return(close(fd));
}



/* ---------------- seek ---------------- */

long mus_seek(int tfd, long offset, int origin)
{
  int fd,siz; /* siz = datum size in bytes */
  long loc,true_loc,header_end;
  if (!io_descriptors_ok) {mus_error(MUS_FILE_DESCRIPTORS_NOT_INITIALIZED,"mus_seek: file descriptors not initialized!"); return(-1);}
  if ((tfd == SNDLIB_DAC_CHANNEL) || (tfd == SNDLIB_DAC_REVERB)) return(0);
  fd = convert_fd(tfd);
  if (fd < 0) return(-1);
  if (io_data_format[fd] == SNDLIB_NO_SND) 
    {
      mus_error(MUS_NOT_A_SOUND_FILE,"mus_seek: invalid stream: %d (%d, %d, %d)",fd,tfd,(int)offset,origin);
      return(-1);
    }
  siz = io_bytes_per_sample[fd];
  if ((siz == 2) || (origin != 0))
    return(lseek(tfd,offset,origin));
  else
    {
      header_end = io_data_location[fd];
      loc = offset - header_end;
      switch (siz)
	{
	case 1: 
	  true_loc = lseek(tfd,header_end+(loc>>1),origin);
	  /* now pretend we're still in 16-bit land and return where we "actually" are in that region */
	  /* that is, loc (in bytes) = how many (2-byte) samples into the file we want to go, return what we got */
	  return(header_end + ((true_loc - header_end)<<1));
	  break;
	case 3:
	  true_loc = lseek(tfd,header_end+loc+(loc>>1),origin);
	  return(true_loc + ((true_loc - header_end)>>1));
	  break;
	case 4:
	  true_loc = lseek(tfd,header_end+(loc<<1),origin);
	  return(header_end + ((true_loc - header_end)>>1));
	  break;
	case 8:
	  true_loc = lseek(tfd,header_end+(loc<<2),origin);
	  return(header_end + ((true_loc - header_end)>>2));
	  break;
	}
    }
  return(-1);
}

int mus_seek_frame(int tfd, int frame)
{
  int fd;
  if (!io_descriptors_ok) {mus_error(MUS_FILE_DESCRIPTORS_NOT_INITIALIZED,"mus_seek_frame: file descriptors not initialized!"); return(-1);}
  if ((tfd == SNDLIB_DAC_CHANNEL) || (tfd == SNDLIB_DAC_REVERB)) return(0);
  fd = convert_fd(tfd);
  if (fd < 0) return(-1);
  if (io_data_format[fd] == SNDLIB_NO_SND) 
    {
      mus_error(MUS_NOT_A_SOUND_FILE,"mus_seek_frame: invalid stream: %d (%d, %d)",fd,tfd,frame);
      return(-1);
    }
  return(lseek(tfd,io_data_location[fd] + (io_chans[fd] * frame * io_bytes_per_sample[fd]),SEEK_SET));
}



/* ---------------- mulaw/alaw conversions ----------------
 *
 *      x : input signal with max value 32767
 *     mu : compression parameter (mu=255 used for telephony)
 *     y = (32767/log(1+mu))*log(1+mu*abs(x)/32767)*sign(x); -- this isn't right -- typo?
 */

/* from sox g711.c */

#define	SIGN_BIT	(0x80)		/* Sign bit for a A-law byte. */
#define	QUANT_MASK	(0xf)		/* Quantization field mask. */
#define	NSEGS		(8)		/* Number of A-law segments. */
#define	SEG_SHIFT	(4)		/* Left shift for segment number. */
#define	SEG_MASK	(0x70)		/* Segment field mask. */

static short seg_end[8] = {0xFF, 0x1FF, 0x3FF, 0x7FF,  0xFFF, 0x1FFF, 0x3FFF, 0x7FFF};

static int search(int val, short *table, int size)
{
  int i;
  for (i = 0; i < size; i++) {if (val <= *table++) return (i);}
  return (size);
}

static unsigned char to_alaw(int pcm_val)
{
  int mask,seg;
  unsigned char	aval;
  if (pcm_val >= 0) {mask = 0xD5;} else {mask = 0x55; pcm_val = -pcm_val - 8;}
  seg = search(pcm_val, seg_end, 8);
  if (seg >= 8)	return (0x7F ^ mask);
  else 
    {
      aval = seg << SEG_SHIFT;
      if (seg < 2) aval |= (pcm_val >> 4) & QUANT_MASK; else aval |= (pcm_val >> (seg + 3)) & QUANT_MASK;
      return (aval ^ mask);
    }
}

static const int alaw[256] = {
 -5504, -5248, -6016, -5760, -4480, -4224, -4992, -4736, -7552, -7296, -8064, -7808, -6528, -6272, -7040, -6784, 
 -2752, -2624, -3008, -2880, -2240, -2112, -2496, -2368, -3776, -3648, -4032, -3904, -3264, -3136, -3520, -3392, 
 -22016, -20992, -24064, -23040, -17920, -16896, -19968, -18944, -30208, -29184, -32256, -31232, -26112, -25088, -28160, -27136, 
 -11008, -10496, -12032, -11520, -8960, -8448, -9984, -9472, -15104, -14592, -16128, -15616, -13056, -12544, -14080, -13568, 
 -344, -328, -376, -360, -280, -264, -312, -296, -472, -456, -504, -488, -408, -392, -440, -424, 
 -88, -72, -120, -104, -24, -8, -56, -40, -216, -200, -248, -232, -152, -136, -184, -168, 
 -1376, -1312, -1504, -1440, -1120, -1056, -1248, -1184, -1888, -1824, -2016, -1952, -1632, -1568, -1760, -1696, 
 -688, -656, -752, -720, -560, -528, -624, -592, -944, -912, -1008, -976, -816, -784, -880, -848, 
 5504, 5248, 6016, 5760, 4480, 4224, 4992, 4736, 7552, 7296, 8064, 7808, 6528, 6272, 7040, 6784, 
 2752, 2624, 3008, 2880, 2240, 2112, 2496, 2368, 3776, 3648, 4032, 3904, 3264, 3136, 3520, 3392, 
 22016, 20992, 24064, 23040, 17920, 16896, 19968, 18944, 30208, 29184, 32256, 31232, 26112, 25088, 28160, 27136, 
 11008, 10496, 12032, 11520, 8960, 8448, 9984, 9472, 15104, 14592, 16128, 15616, 13056, 12544, 14080, 13568, 
 344, 328, 376, 360, 280, 264, 312, 296, 472, 456, 504, 488, 408, 392, 440, 424, 
 88, 72, 120, 104, 24, 8, 56, 40, 216, 200, 248, 232, 152, 136, 184, 168, 
 1376, 1312, 1504, 1440, 1120, 1056, 1248, 1184, 1888, 1824, 2016, 1952, 1632, 1568, 1760, 1696, 
 688, 656, 752, 720, 560, 528, 624, 592, 944, 912, 1008, 976, 816, 784, 880, 848
};

#if 0
static int from_alaw(unsigned char a_val)
{
  int t,seg;
  a_val ^= 0x55;
  t = (a_val & QUANT_MASK) << 4;
  seg = ((unsigned)a_val & SEG_MASK) >> SEG_SHIFT;
  switch (seg) 
    {
    case 0: t += 8; break;
    case 1: t += 0x108; break;
  default:  t += 0x108; t <<= seg - 1;
    }
  return((a_val & SIGN_BIT) ? t : -t);
}
#endif 

#define	BIAS		(0x84)		/* Bias for linear code. */

static unsigned char to_mulaw(int pcm_val)
{
  int mask;
  int seg;
  unsigned char	uval;
  if (pcm_val < 0) {pcm_val = BIAS - pcm_val; mask = 0x7F;} else {pcm_val += BIAS; mask = 0xFF;}
  seg = search(pcm_val, seg_end, 8);
  if (seg >= 8) return (0x7F ^ mask);
  else 
    {
      uval = (seg << 4) | ((pcm_val >> (seg + 3)) & 0xF);
      return (uval ^ mask);
    }
}

/* generated by SNDiMulaw on a NeXT -- see /usr/include/sound/mulaw.h */
static const int mulaw[256] = {
  -32124, -31100, -30076, -29052, -28028, -27004, -25980, -24956, -23932, -22908, -21884, -20860, 
  -19836, -18812, -17788, -16764, -15996, -15484, -14972, -14460, -13948, -13436, -12924, -12412, 
  -11900, -11388, -10876, -10364, -9852, -9340, -8828, -8316, -7932, -7676, -7420, -7164, -6908, 
  -6652, -6396, -6140, -5884, -5628, -5372, -5116, -4860, -4604, -4348, -4092, -3900, -3772, -3644, 
  -3516, -3388, -3260, -3132, -3004, -2876, -2748, -2620, -2492, -2364, -2236, -2108, -1980, -1884, 
  -1820, -1756, -1692, -1628, -1564, -1500, -1436, -1372, -1308, -1244, -1180, -1116, -1052, -988, 
  -924, -876, -844, -812, -780, -748, -716, -684, -652, -620, -588, -556, -524, -492, -460, -428, 
  -396, -372, -356, -340, -324, -308, -292, -276, -260, -244, -228, -212, -196, -180, -164, -148, 
  -132, -120, -112, -104, -96, -88, -80, -72, -64, -56, -48, -40, -32, -24, -16, -8, 0, 32124, 31100, 
  30076, 29052, 28028, 27004, 25980, 24956, 23932, 22908, 21884, 20860, 19836, 18812, 17788, 16764, 
  15996, 15484, 14972, 14460, 13948, 13436, 12924, 12412, 11900, 11388, 10876, 10364, 9852, 9340, 
  8828, 8316, 7932, 7676, 7420, 7164, 6908, 6652, 6396, 6140, 5884, 5628, 5372, 5116, 4860, 4604, 
  4348, 4092, 3900, 3772, 3644, 3516, 3388, 3260, 3132, 3004, 2876, 2748, 2620, 2492, 2364, 2236, 
  2108, 1980, 1884, 1820, 1756, 1692, 1628, 1564, 1500, 1436, 1372, 1308, 1244, 1180, 1116, 1052, 
  988, 924, 876, 844, 812, 780, 748, 716, 684, 652, 620, 588, 556, 524, 492, 460, 428, 396, 372, 
  356, 340, 324, 308, 292, 276, 260, 244, 228, 212, 196, 180, 164, 148, 132, 120, 112, 104, 96, 
  88, 80, 72, 64, 56, 48, 40, 32, 24, 16, 8, 0};

#if 0
/* in case it's ever needed, here's the mulaw to linear converter from g711.c -- identical to table above */
static int from_mulaw(unsigned char u_val)
{
  int t;
  u_val = ~u_val;
  t = ((u_val & QUANT_MASK) << 3) + BIAS;
  t <<= ((unsigned)u_val & SEG_MASK) >> SEG_SHIFT;
  return ((u_val & SIGN_BIT) ? (BIAS - t) : (t - BIAS));
}
#endif

/* ---------------- read/write buffer allocation ---------------- */

#if LONG_INT_P
static int **long_int_p_table = NULL;
static int long_int_p_table_size = 0;

int *delist_ptr(int arr) {return(long_int_p_table[arr]);}

int list_ptr(int *arr) 
{
  int i,loc;
  loc = -1;
  for (i=0;i<long_int_p_table_size;i++) 
    {
      if (long_int_p_table[i] == NULL)
	{
	  loc = i;
	  break;
	}
    }
  if (loc == -1)
    {
      loc = long_int_p_table_size;
      long_int_p_table_size+=16;
      if (long_int_p_table)
	{
	  long_int_p_table = (int **)REALLOC(long_int_p_table,long_int_p_table_size * sizeof(int *));
	  for (i=loc;i<long_int_p_table_size;i++) long_int_p_table[i] = NULL;
	}
      else
	long_int_p_table = (int **)CALLOC(long_int_p_table_size,sizeof(int *));
    }
  long_int_p_table[loc] = arr;
  return(loc);
}

void freearray(int ip_1) 
{
  int *ip; 
  ip = delist_ptr(ip_1); 
  if (ip) FREE(ip); 
  long_int_p_table[ip_1] = NULL;
}
#else
void freearray(int *ip) {if (ip) FREE(ip);}
#endif

#define BUFLIM (64*1024)

static int checked_write(int fd, char *buf, int chars)
{
#ifdef CLM
#ifndef MACOS
  long lisp_call(int index);
#endif
#endif
  int bytes,cfd;
  if (fd == SNDLIB_DAC_CHANNEL)
    {
      write_audio(rt_ap_out,buf,chars);
    }
  else
    {
      bytes=write(fd,buf,chars);
      if (bytes != chars) 
	{
	  if (!io_descriptors_ok) {mus_error(MUS_FILE_DESCRIPTORS_NOT_INITIALIZED,"checked_write: file descriptors not initialized!"); return(-1);}
	  cfd = convert_fd(fd);
	  if (cfd < 0) return(-1);
	  if (io_data_format[cfd] == SNDLIB_NO_SND) mus_error(MUS_FILE_CLOSED,"checked_write called on closed file");
#if LONG_INT_P
	  mus_error(MUS_WRITE_ERROR,"IO write error (%s): %d of %d bytes written for %d from %d (%d %d %d)\n",
		    strerror(errno),
		    bytes,chars,fd,cfd,io_bytes_per_sample[cfd],io_data_format[cfd],io_data_location[cfd]);
#else
  #ifndef MACOS
	  mus_error(MUS_WRITE_ERROR,"IO write error (%s): %d of %d bytes written for %d from %d (%d %d %d %d)\n",
		    strerror(errno),
		    bytes,chars,fd,cfd,(int)buf,io_bytes_per_sample[cfd],io_data_format[cfd],io_data_location[cfd]);
  #else
	  mus_error(MUS_WRITE_ERROR,"IO write error: %d of %d bytes written for %d from %d (%d %d %d %d)\n",
		    bytes,chars,fd,cfd,(int)buf,io_bytes_per_sample[cfd],io_data_format[cfd],io_data_location[cfd]);
  #endif
#endif
	  return(-1);
	}
    }
  return(0);
}



/* ---------------- read ---------------- */

/* normally we assume a 16-bit fractional part, but sometimes user want 24-bits */
static int shift_24_choice = 0;
#ifdef CLM
int get_shift_24_choice(void) {return(shift_24_choice);}
void set_shift_24_choice(int choice) {shift_24_choice = choice;}
#endif

int mus_read_any(int tfd, int beg, int chans, int nints, int **bufs, int *cm)
{
  int fd;
  int bytes,j,lim,siz,total,leftover,total_read,k,loc,oldloc,siz_chans,buflim;
  unsigned char *jchar;
  char *charbuf = NULL;
  int *buffer;
  if (!io_descriptors_ok) {mus_error(MUS_FILE_DESCRIPTORS_NOT_INITIALIZED,"mus_read: file descriptors not initialized!"); return(-1);}
  if (nints <= 0) return(0);
  fd = convert_fd(tfd);
  if (fd < 0) return(-1);
  if (io_data_format[fd] == SNDLIB_NO_SND) {mus_error(MUS_FILE_CLOSED,"read_any called on closed file"); return(-1);}
  charbuf = (char *)CALLOC(BUFLIM,sizeof(char)); 
  if (charbuf == NULL) {mus_error(MUS_MEMORY_ALLOCATION_FAILED,"IO buffer allocation trouble"); return(-1);}
  siz = io_bytes_per_sample[fd];
  siz_chans = siz*chans;
  leftover = (nints*siz_chans);
  k = (BUFLIM) % siz_chans;
  if (k != 0) /* for example, 3 channel output of 1-byte (mulaw) samples will need a mod 3 buffer */
    buflim = (BUFLIM) - k;
  else buflim = BUFLIM;
  total_read = 0;
  loc = beg;
  while (leftover > 0)
    {
      bytes = leftover;
      if (bytes > buflim) {leftover = (bytes-buflim); bytes = buflim;} else leftover = 0;
      total = read(tfd,charbuf,bytes); 
      if (total <= 0) 
	{
	  /* zero out trailing section (some callers don't check the returned value) -- this added 9-May-99 */
	  lim = beg+nints;
	  if (loc < lim)
	    {
	      for (k=0;k<chans;k++)
		{
		  if ((cm == NULL) || (cm[k]))
		    {
		      for (j=loc;j<lim;j++) 
			bufs[k][j] = 0;
		    }
		}
	    }
	  FREE(charbuf);
	  return(total_read);
	}
      lim = (int) (total / siz_chans);  /* this divide must be exact (hence the buflim calc above) */
      total_read += lim;
      oldloc = loc;

      for (k=0;k<chans;k++)
	{
	  if ((cm == NULL) || (cm[k]))
	    {
	      buffer = (int *)(bufs[k]);
	      if (buffer)
		{
		  loc = oldloc;
		  jchar = (unsigned char *)charbuf;
		  jchar += (k*siz);
		  switch (io_data_format[fd])
		    {
		    case SNDLIB_16_LINEAR:               
		      for (j=0;j<lim;j++,loc++,jchar+=siz_chans) buffer[loc] = (int)m_big_endian_short(jchar); 
		      break;
		    case SNDLIB_16_LINEAR_LITTLE_ENDIAN: 
		      for (j=0;j<lim;j++,loc++,jchar+=siz_chans) buffer[loc] = (int)m_little_endian_short(jchar); 
		      break;
		    case SNDLIB_32_LINEAR:              
		      for (j=0;j<lim;j++,loc++,jchar+=siz_chans) buffer[loc] = m_big_endian_int(jchar); 
		      break;
		    case SNDLIB_32_LINEAR_LITTLE_ENDIAN: 
		      for (j=0;j<lim;j++,loc++,jchar+=siz_chans) buffer[loc] = m_little_endian_int(jchar); 
		      break;
		    case SNDLIB_8_MULAW:  	              
		      for (j=0;j<lim;j++,loc++,jchar+=siz_chans) buffer[loc] = mulaw[*jchar]; 
		      break;
		    case SNDLIB_8_ALAW:                  
		      for (j=0;j<lim;j++,loc++,jchar+=siz_chans) buffer[loc] = alaw[*jchar]; 
		      break;
		    case SNDLIB_8_LINEAR:                
		      for (j=0;j<lim;j++,loc++,jchar+=siz_chans) buffer[loc] = (int)(((signed char)(*jchar)) << 8); 
		      break;
		    case SNDLIB_8_UNSIGNED:     	      
		      for (j=0;j<lim;j++,loc++,jchar+=siz_chans) buffer[loc] = (int) ((((int)(*jchar))-128) << 8); 
		      break;
		    case SNDLIB_32_FLOAT:
		      for (j=0;j<lim;j++,loc++,jchar+=siz_chans) buffer[loc] = (int) (SNDLIB_SNDFIX*(m_big_endian_float(jchar)));
		      break;
		    case SNDLIB_64_DOUBLE:   
		      for (j=0;j<lim;j++,loc++,jchar+=siz_chans) buffer[loc] = (int) (SNDLIB_SNDFIX*(m_big_endian_double(jchar)));
		      break;
		    case SNDLIB_32_FLOAT_LITTLE_ENDIAN:    
		      for (j=0;j<lim;j++,loc++,jchar+=siz_chans) buffer[loc] = (int) (SNDLIB_SNDFIX*(m_little_endian_float(jchar)));
		      break;
		    case SNDLIB_64_DOUBLE_LITTLE_ENDIAN:   
		      for (j=0;j<lim;j++,loc++,jchar+=siz_chans) buffer[loc] = (int) (SNDLIB_SNDFIX*(m_little_endian_double(jchar)));
		      break;
		    case SNDLIB_16_UNSIGNED:   
		      for (j=0;j<lim;j++,loc++,jchar+=siz_chans) buffer[loc] = ((int)(m_big_endian_unsigned_short(jchar)) - 32768);
		      break;
		    case SNDLIB_16_UNSIGNED_LITTLE_ENDIAN:   
		      for (j=0;j<lim;j++,loc++,jchar+=siz_chans) buffer[loc] = ((int)(m_little_endian_unsigned_short(jchar)) - 32768);
		      break;
		    case SNDLIB_32_VAX_FLOAT:   
		      for (j=0;j<lim;j++,loc++,jchar+=siz_chans) buffer[loc] = (int)from_vax_float(jchar);
		      break;
		    case SNDLIB_24_LINEAR:
		      if (shift_24_choice == 0)
			{
			  for (j=0;j<lim;j++,loc++,jchar+=siz_chans)
			    buffer[loc] = (int)(((jchar[0]<<24)+(jchar[1]<<16))>>16);
			}
		      else
			{
			  for (j=0;j<lim;j++,loc++,jchar+=siz_chans)
			    buffer[loc] = (int)(((jchar[0]<<24)+(jchar[1]<<16)+(jchar[2]<<8))>>8);
			}
		      break;
		    case SNDLIB_24_LINEAR_LITTLE_ENDIAN:   
		      if (shift_24_choice == 0)
			{
			  for (j=0;j<lim;j++,loc++,jchar+=siz_chans)
			    buffer[loc] = (int)(((jchar[2]<<24)+(jchar[1]<<16))>>16);
			}
		      else
			{
			  for (j=0;j<lim;j++,loc++,jchar+=siz_chans)
			    buffer[loc] = (int)(((jchar[2]<<24)+(jchar[1]<<16)+(jchar[0]<<8))>>8);
			}
		      break;
		    }
		}
	    }
	}
    }
  FREE(charbuf);
  return(total_read);
}

int mus_read(int fd, int beg, int end, int chans, int **bufs)
{
  int num,rtn,i,k;
  int *buffer;
  num=(end-beg+1);
  rtn=mus_read_any(fd,beg,chans,num,bufs,NULL);
  if (rtn == -1) return(-1);
  if (rtn<num) 
    {
      for (k=0;k<chans;k++)
	{
	  buffer=(int *)(bufs[k]);
	  for (i=rtn+beg;i<=end;i++)
	    {
	      buffer[i]=0;
	    }
	}
    }
  return(num);
}

int mus_read_chans(int fd, int beg, int end, int chans, int **bufs, int *cm)
{
  /* an optimization of mus_read -- just reads the desired channels */
  int num,rtn,i,k;
  int *buffer;
  num=(end-beg+1);
  rtn=mus_read_any(fd,beg,chans,num,bufs,cm);
  if (rtn == -1) return(-1);
  if (rtn<num) 
    {
      for (k=0;k<chans;k++)
	{
	  if ((cm == NULL) || (cm[k]))
	    {
	      buffer=(int *)(bufs[k]);
	      for (i=rtn+beg;i<=end;i++)
		{
		  buffer[i]=0;
		}
	    }
	}
    }
  return(num);
}


/* ---------------- write ---------------- */

#ifdef WINDOZE
  #undef min
#endif

#define min(x,y)  ((x) < (y) ? (x) : (y))

int mus_write_zeros(int tfd, int num)
{
  int i,lim,curnum,fd,err;
  char *charbuf = NULL;
  if (tfd == -1) return(-1);
  if (tfd == SNDLIB_DAC_REVERB) return(0);
  if (!io_descriptors_ok) {mus_error(MUS_FILE_DESCRIPTORS_NOT_INITIALIZED,"mus_write: file descriptors not initialized!"); return(-1);}
  fd = convert_fd(tfd);
  if (fd < 0) return(-1);
  if (io_data_format[fd] == SNDLIB_NO_SND) {mus_error(MUS_FILE_CLOSED,"write_zeros called on closed file"); return(-1);}
  charbuf = (char *)CALLOC(BUFLIM,sizeof(char)); 
  if (charbuf == NULL) {mus_error(MUS_MEMORY_ALLOCATION_FAILED,"IO buffer allocation trouble"); return(-1);}
  lim = num*(io_bytes_per_sample[fd]);
  curnum=min(lim,BUFLIM);
  for (i=0;i<curnum;i++) charbuf[i]=0;
  while (curnum>0)
    {
      err = checked_write(tfd,charbuf,curnum);
      if (err == -1) return(-1);
      lim -= (BUFLIM);
      curnum=min(lim,BUFLIM);
    }
  FREE(charbuf);
  return(num);
}


#ifdef CLM
void mus_write_float(int fd, float val) {write(fd,(char *)(&val),4);}

#if defined(ACL4) && defined(ALPHA)
/* in this case, the array passed from lisp is a list of table indices */
void mus_write_1(int tfd, int beg, int end, int chans, int *buflist)
{
  int i;
  int **bufs;
  bufs = (int **)CALLOC(chans,sizeof(int *));
  for (i=0;i<chans;i++) bufs[i] = delist_ptr(buflist[i]);
  mus_write(tfd,beg,end,chans,bufs);
  FREE(bufs);
}
void mus_read_1(int fd, int beg, int end, int chans, int *buflist)
{
  int i;
  int **bufs;
  bufs = (int **)CALLOC(chans,sizeof(int *));
  for (i=0;i<chans;i++) bufs[i] = delist_ptr(buflist[i]);
  mus_read(fd,beg,end,chans,bufs);
  FREE(bufs);
}
#endif
#endif

int mus_write(int tfd, int beg, int end, int chans, int **bufs)
{
  int fd,err;
  int bytes,j,k,lim,siz,leftover,loc,bk,oldloc,buflim,siz_chans,cliploc;
  unsigned char *jchar;
  char *charbuf = NULL;
  int *buffer;
  if (tfd == -1) return(-1);
  if (tfd == SNDLIB_DAC_REVERB) return(0);
  if (!io_descriptors_ok) {mus_error(MUS_FILE_DESCRIPTORS_NOT_INITIALIZED,"mus_write: file descriptors not initialized!"); return(-1);}
  fd = convert_fd(tfd);
  if (fd < 0) return(-1);
  if (io_data_format[fd] == SNDLIB_NO_SND) {mus_error(MUS_FILE_CLOSED,"write called on closed file"); return(-1);}
  charbuf = (char *)CALLOC(BUFLIM,sizeof(char)); 
  if (charbuf == NULL) {mus_error(MUS_MEMORY_ALLOCATION_FAILED,"IO buffer allocation trouble"); return(-1);}
  siz = io_bytes_per_sample[fd];
  lim=(end-beg+1);
  siz_chans = siz*chans;
  leftover = lim*siz_chans;
  k = (BUFLIM) % siz_chans;
  if (k != 0) 
    buflim = (BUFLIM) - k;
  else buflim = BUFLIM;
  loc = beg;
  while (leftover > 0)
    {
      bytes = leftover;
      if (bytes > buflim) {leftover = (bytes-buflim); bytes = buflim;} else leftover = 0;
      lim = (int)(bytes/siz_chans); /* see note above */
      oldloc = loc;

      for (k=0;k<chans;k++)
	{
	  loc = oldloc;
	  buffer = (int *)(bufs[k]);
	  if (io_data_clipped[fd])
	    {
	      cliploc = oldloc;
	      for (j=0;j<lim;j++,cliploc++)
		{
		  if (buffer[cliploc] > 32767)
		    buffer[cliploc] = 32767;
		  else
		    if (buffer[cliploc] < -32768)
		      buffer[cliploc] = -32768;
		}
	    }
	  jchar = (unsigned char *)charbuf;
	  jchar += (k*siz);
	  switch (io_data_format[fd])
	    {
	    case SNDLIB_16_LINEAR: 
	      for (j=0;j<lim;j++,loc++,jchar+=siz_chans) m_set_big_endian_short(jchar,(short)(buffer[loc]));
	      break;
	    case SNDLIB_16_LINEAR_LITTLE_ENDIAN:   
	      for (j=0;j<lim;j++,loc++,jchar+=siz_chans) m_set_little_endian_short(jchar,(short)(buffer[loc]));
	      break;
	    case SNDLIB_32_LINEAR:   
	      for (j=0;j<lim;j++,loc++,jchar+=siz_chans) m_set_big_endian_int(jchar,buffer[loc]);
	      break;
	    case SNDLIB_32_LINEAR_LITTLE_ENDIAN:   
	      for (j=0;j<lim;j++,loc++,jchar+=siz_chans) m_set_little_endian_int(jchar,buffer[loc]);
	      break;
	    case SNDLIB_8_MULAW:     
	      for (j=0;j<lim;j++,loc++,jchar+=siz_chans) (*jchar) = to_mulaw(buffer[loc]);
	      break;
	    case SNDLIB_8_ALAW:      
	      for (j=0;j<lim;j++,loc++,jchar+=siz_chans) (*jchar) = to_alaw(buffer[loc]);
	      break;
	    case SNDLIB_8_LINEAR:    
	      for (j=0;j<lim;j++,loc++,jchar+=siz_chans) (*((signed char *)jchar)) = ((buffer[loc])>>8);
	      break;
	    case SNDLIB_8_UNSIGNED:  
	      for (j=0;j<lim;j++,loc++,jchar+=siz_chans) (*jchar) = ((buffer[loc])>>8)+128;
	      break;
	    case SNDLIB_32_FLOAT:    
	      for (j=0;j<lim;j++,loc++,jchar+=siz_chans) m_set_big_endian_float(jchar,(SNDLIB_SNDFLT * (buffer[loc])));
	      break;
	    case SNDLIB_32_FLOAT_LITTLE_ENDIAN:    
	      for (j=0;j<lim;j++,loc++,jchar+=siz_chans) m_set_little_endian_float(jchar,(SNDLIB_SNDFLT * (buffer[loc])));
	      break;
	    case SNDLIB_64_DOUBLE:
	      for (j=0;j<lim;j++,loc++,jchar+=siz_chans) m_set_big_endian_double(jchar,(SNDLIB_SNDFLT * (buffer[loc])));
	      break;
	    case SNDLIB_64_DOUBLE_LITTLE_ENDIAN:   
	      for (j=0;j<lim;j++,loc++,jchar+=siz_chans) m_set_little_endian_double(jchar,(SNDLIB_SNDFLT * (buffer[loc])));
	      break;
	    case SNDLIB_16_UNSIGNED: 
	      for (j=0;j<lim;j++,loc++,jchar+=siz_chans) m_set_big_endian_unsigned_short(jchar,(short)(buffer[loc] + 32768));
	      break;
	    case SNDLIB_16_UNSIGNED_LITTLE_ENDIAN: 
	      for (j=0;j<lim;j++,loc++,jchar+=siz_chans) m_set_little_endian_unsigned_short(jchar,(short)(buffer[loc] + 32768));
	      break;
	    case SNDLIB_24_LINEAR:   
	      bk=(k*3);
	      if (shift_24_choice == 0)
		{
		  for (j=0;j<lim;j++,loc++,bk+=(chans*3)) 
		    {
		      charbuf[bk]=((buffer[loc])>>8); 
		      charbuf[bk+1]=((buffer[loc])&0xFF); 
		      charbuf[bk+2]=0;	
		    }
		}
	      else
		{
		  for (j=0;j<lim;j++,loc++,bk+=(chans*3)) 
		    {
		      charbuf[bk]=((buffer[loc])>>16); 
		      charbuf[bk+1]=((buffer[loc])>>8); 
		      charbuf[bk+2]=((buffer[loc])&0xFF); 
		    }
		}
	      break;
	    case SNDLIB_24_LINEAR_LITTLE_ENDIAN:   
	      bk=(k*3);
	      if (shift_24_choice == 0)
		{
		  for (j=0;j<lim;j++,loc++,bk+=(chans*3))
		    {
		      charbuf[bk+2]=((buffer[loc])>>8); 
		      charbuf[bk+1]=((buffer[loc])&0xFF); 
		      charbuf[bk]=0;    
		    }
		}
	      else
		{
		  for (j=0;j<lim;j++,loc++,bk+=(chans*3))
		    {
		      charbuf[bk+2]=((buffer[loc])>>16); 
		      charbuf[bk+1]=((buffer[loc])>>8); 
		      charbuf[bk]=((buffer[loc])&0xFF); 
		    }
		}
	      break;
	    }
	}
      err = checked_write(tfd,charbuf,bytes);
      if (err == -1) {FREE(charbuf); return(-1);}
    }
  FREE(charbuf);
  return(0);
}

int mus_float_sound(char *charbuf, int samps, int charbuf_format, float *buffer)
{
  /* translate whatever is in charbuf to 32-bit floats still interleaved */
  int j,siz;
  unsigned char *jchar;
  siz = mus_format2bytes(charbuf_format);
  jchar = (unsigned char *)charbuf;
  switch (charbuf_format)
    {
    case SNDLIB_16_LINEAR:   
      for (j=0;j<samps;j++,jchar+=siz) buffer[j] = (float)(m_big_endian_short(jchar)); 
      break;
    case SNDLIB_16_LINEAR_LITTLE_ENDIAN:   
      for (j=0;j<samps;j++,jchar+=siz) buffer[j] = (float)(m_little_endian_short(jchar)); 
      break;
    case SNDLIB_32_LINEAR:   
      for (j=0;j<samps;j++,jchar+=siz) buffer[j] = (float)(m_big_endian_int(jchar));
      break;
    case SNDLIB_32_LINEAR_LITTLE_ENDIAN:   
      for (j=0;j<samps;j++,jchar+=siz) buffer[j] = (float)(m_little_endian_int(jchar));
      break;
    case SNDLIB_8_MULAW:
      for (j=0;j<samps;j++,jchar+=siz) buffer[j] = (float)(mulaw[*jchar]);
      break;
    case SNDLIB_8_ALAW:      
      for (j=0;j<samps;j++,jchar+=siz) buffer[j] = (float)(alaw[*jchar]);
      break;
    case SNDLIB_8_LINEAR:
      for (j=0;j<samps;j++,jchar+=siz) buffer[j] = (float)((int)((*((signed char *)jchar)) << 8));
      break;
    case SNDLIB_8_UNSIGNED:  
      for (j=0;j<samps;j++,jchar+=siz) buffer[j] = (float)((int) ((((int)(*jchar))-128) << 8));
      break;
    case SNDLIB_24_LINEAR:
      for (j=0;j<samps;j++,jchar+=siz) buffer[j] = (float)((int)(((jchar[0]<<24)+(jchar[1]<<16))>>16));
      break;
    case SNDLIB_24_LINEAR_LITTLE_ENDIAN:   
      for (j=0;j<samps;j++,jchar+=siz) buffer[j] = (float)((int)(((jchar[2]<<24)+(jchar[1]<<16))>>16));
      break;
    case SNDLIB_32_FLOAT:
      for (j=0;j<samps;j++,jchar+=siz) buffer[j] = m_big_endian_float(jchar);
      break;
    case SNDLIB_64_DOUBLE:   
      for (j=0;j<samps;j++,jchar+=siz) buffer[j] = (float)(m_big_endian_double(jchar));
      break;
    case SNDLIB_32_FLOAT_LITTLE_ENDIAN:    
      for (j=0;j<samps;j++,jchar+=siz) buffer[j] = m_little_endian_float(jchar);
      break;
    case SNDLIB_64_DOUBLE_LITTLE_ENDIAN:   
      for (j=0;j<samps;j++,jchar+=siz) buffer[j] = (float)(m_little_endian_double(jchar));
      break;
    case SNDLIB_16_UNSIGNED:   
      for (j=0;j<samps;j++,jchar+=siz) buffer[j] = (float)(((int)(m_big_endian_unsigned_short(jchar)) - 32768));
      break;
    case SNDLIB_32_VAX_FLOAT:   
      for (j=0;j<samps;j++,jchar+=siz) buffer[j] = (float)((int)from_vax_float(jchar));
      break;
    case SNDLIB_16_UNSIGNED_LITTLE_ENDIAN:   
      for (j=0;j<samps;j++,jchar+=siz) buffer[j] = (float)((int)(m_little_endian_unsigned_short(jchar)) - 32768);
      break;
    default: return(-1); break;
    }
  return(0);
}

#ifdef CLM

/* originally part of clmnet.c, but requires endian handlers and is easier to deal with on the Mac if it's in this file */
int net_mix(int fd, int loc, char *buf1, char *buf2, int bytes)
{
#if defined(SNDLIB_LITTLE_ENDIAN) || defined(SUN)
  unsigned char*b1,*b2;
#else
  short *dat1,*dat2;
#endif  
  int i,lim,rtn;
  lim = bytes>>1;
  lseek(fd,loc,SEEK_SET);
  rtn = read(fd,buf1,bytes);
  if (rtn < bytes)
    {
      for (i=rtn;i<bytes;i++) buf1[i]=buf2[i];
      lim = rtn>>1;
    }
  lseek(fd,loc,SEEK_SET);
#if defined(SNDLIB_LITTLE_ENDIAN) || defined(SUN)
  /* all intermediate results are written as big-endian shorts (NeXT output) */
  b1 = (unsigned char *)buf1;
  b2 = (unsigned char *)buf2;
  for (i=0;i<lim;i++,b1+=2,b2+=2) mus_set_big_endian_short(b1,(short)(mus_big_endian_short(b1) + mus_big_endian_short(b2)));
#else
  dat1 = (short *)buf1;
  dat2 = (short *)buf2;
  for (i=0;i<lim;i++) dat1[i] += dat2[i];
#endif
  write(fd,buf1,bytes);
  return(0);
}
#endif

int mus_unshort_sound(short *in_buf, int samps, int new_format, char *out_buf)
{
  int j,siz;
  unsigned char *jchar;
  siz = mus_format2bytes(new_format);
  jchar = (unsigned char *)out_buf;
  switch (new_format)
    {
    case SNDLIB_16_LINEAR:   
      for (j=0;j<samps;j++,jchar+=siz) m_set_big_endian_short(jchar,in_buf[j]);
      break;
    case SNDLIB_16_LINEAR_LITTLE_ENDIAN:   
      for (j=0;j<samps;j++,jchar+=siz) m_set_little_endian_short(jchar,in_buf[j]);
      break;
    case SNDLIB_32_LINEAR:   
      for (j=0;j<samps;j++,jchar+=siz) m_set_big_endian_int(jchar,(int)in_buf[j]);
      break;
    case SNDLIB_32_LINEAR_LITTLE_ENDIAN:   
      for (j=0;j<samps;j++,jchar+=siz) m_set_little_endian_int(jchar,(int)in_buf[j]);
      break;
    case SNDLIB_8_MULAW:     
      for (j=0;j<samps;j++,jchar+=siz) (*jchar) = to_mulaw(in_buf[j]);
      break;
    case SNDLIB_8_ALAW:      
      for (j=0;j<samps;j++,jchar+=siz) (*jchar) = to_alaw(in_buf[j]);
      break;
    case SNDLIB_8_LINEAR:    
      for (j=0;j<samps;j++,jchar+=siz) (*((signed char *)jchar)) = ((in_buf[j])>>8);
      break;
    case SNDLIB_8_UNSIGNED:  
      for (j=0;j<samps;j++,jchar+=siz) (*jchar) = ((in_buf[j])>>8)+128;
      break;
    case SNDLIB_32_FLOAT:    
      for (j=0;j<samps;j++,jchar+=siz) m_set_big_endian_float(jchar,(SNDLIB_SNDFLT * (in_buf[j])));
      break;
    case SNDLIB_32_FLOAT_LITTLE_ENDIAN:    
      for (j=0;j<samps;j++,jchar+=siz) m_set_little_endian_float(jchar,(SNDLIB_SNDFLT * (in_buf[j])));
      break;
    default: return(0); break;
    }
  return(samps*siz);
}

#ifdef CLM
void reset_io_c(void) 
{
  io_descriptors_ok = 0; 
  io_files_ready = 0;
#if LONG_INT_P
  long_int_p_table = NULL;
  long_int_p_table_size = 0;
#endif
}
#endif

char *mus_complete_filename(char *tok)
{
  /* fill out under-specified library pathnames and check for the damned '//' business (SGI file selection box uses this) */
  /* what about "../" and "./" ? these work, but perhaps we should handle them explicitly) */
  char *file_name_buf;
  int i,j,len;
  file_name_buf = (char *)CALLOC(SNDLIB_MAX_FILE_NAME,sizeof(char));
  if ((tok) && (*tok)) len = strlen(tok); else len = 0;
  j = 0;
  for (i=0;i<len-1;i++)
    {
      if ((tok[i] == '/') && (tok[i+1] == '/')) j=i+1;
    }
  if (j > 0)
    {
      for (i=0;j<len;i++,j++) tok[i] = tok[j];
      tok[i]='\0';
    }
#ifdef MACOS
  strcpy(file_name_buf,tok);
#else
  if (tok[0] != '/')
    {
      file_name_buf[0] = '\0';
      if (tok[0] == '~')
	{
	  strcpy(file_name_buf,getenv("HOME"));
	  strcat(file_name_buf,++tok);
	}
      else
	{
  #if (!defined(NEXT)) || defined(HAVE_GETCWD)
	  getcwd(file_name_buf,SNDLIB_MAX_FILE_NAME);
  #else
	  getwd(file_name_buf);
  #endif
	  strcat(file_name_buf,"/");
	  strcat(file_name_buf,tok);
	}
    }
  else strcpy(file_name_buf,tok);
#endif
  return(file_name_buf);
}
