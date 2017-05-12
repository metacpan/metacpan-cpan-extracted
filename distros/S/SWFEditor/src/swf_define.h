#ifndef __SWF_DEFINE__H__
#define __SWF_DEFINE__H__

#include <stdlib.h>

#ifdef HAVE_CONFIG_H
#include "config.h"
#endif

#ifndef SWFED_JPEG_RST_SCAN_STDJPEG
#define SWFED_JPEG_RST_SCAN_STDJPEG 0 // default
#endif
#ifndef SWFED_JPEG_RST_SCAN_SWFJPEG
#define SWFED_JPEG_RST_SCAN_SWFJPEG 0 // default
#endif

#define INDENT_UNIT 4
#define print_indent(depth) printf("%*s", INDENT_UNIT*(depth), " ")

#define SWF_TWIPS 20
#define SWF_MAGIC_SIZE 4
#define SWF_FILE_LENGTH_SIZE 4
#define SWF_HEADER_SIZE 8

extern int swf_debug;

#ifdef MALLOC_DEBUG /*  malloc debug */

extern void malloc_debug_start(void);
extern void malloc_debug_end(void);

extern void *calloc_debug(size_t nmemb, size_t size, char *filename, int linenum);
extern void *malloc_debug(size_t size, char *filename, int linenum);
extern void free_debug(void *ptr, char *filename, int linenum);
extern void *realloc_debug(void *ptr, size_t size, char *filename, int linenum);

#define calloc(n,s)  calloc_debug(n,s,__FILE__,__LINE__)
#define malloc(s)    malloc_debug(s,__FILE__,__LINE__)
#define free(p)      free_debug(p,__FILE__,__LINE__)
#define realloc(p,s) realloc_debug(p,s,__FILE__,__LINE__)

extern void print_hexbin(unsigned char *data, int data_len);

#else

// no MALLOC_DEBUG is disabled this functions
#define malloc_debug_start() 
#define malloc_debug_end()

#endif

#if 0 /* PHP Extension */
#define calloc(n,s)  ecalloc(n,s)
#define malloc(s)    emalloc(s)
#define free(p)      efree(p)
#define realloc(p,s) erealloc(p,s)
#endif

#define NumOfTable(t) (sizeof(t) / sizeof(*t))

#define GV2B(a,b) ((a << 8) + b)
#define GV4B(a,b,c,d) GV2B(GV2B(GV2B(a,b),c),d)
#define GV8B(a,b,c,d,e,f,g,h) GV2B(GV2B(GV2B(GV2B(GV2B(GV2B(GV2B(a,b),c),d),e),f),g),h)

#define GetUShortLE(data) ((unsigned short) GV2B(data[1], data[0]))

#define GetULongLE(data) ((unsigned long) GV4B(data[3], data[2], data[1], data[0]))
#define GetFloatIEEE(data) ((double) GV4B(data[0], data[1], data[2], data[3]))
#define GetDoubleIEEE(data) ((double) GV8B(data[4], data[5], data[6], data[7], data[0], data[1], data[2], data[3]))

#define PutUShortLE(data, value) ((data[0] = (value & 0xff)), (data[1] = (value >> 8)))

// tag

// DefineBitsJPEG1,2,3
#define isBitsJPEGTag(tag) (((tag) == 6) || ((tag) == 21) || ((tag) == 35))
// DefineLossless1,2
#define isBitsLosslessTag(tag) (((tag) == 20) || ((tag) == 36))
#define isBitmapTag(tag) (isBitsJPEGTag(tag) || isBitsLosslessTag(tag))
// DefineShape1,2,3, DefineMorphShape1
#define isShapeTag(tag) (((tag) == 2) || ((tag) == 22) || ((tag) == 32) || ((tag) == 46))
// DefineButton1,2
#define isButtonTag(tag) (((tag) == 7) || ((tag) == 34))
// PlaceObject1,2
#define isPlaceTag(tag) (((tag) == 4) || ((tag) == 26))
#define isSpriteTag(tag) ((tag) == 39)
// DoAction,DoInitAction
#define isActionTag(tag) (((tag) == 12) || ((tag) == 59))

#endif /* __SWF_DEFINE__H__ */
