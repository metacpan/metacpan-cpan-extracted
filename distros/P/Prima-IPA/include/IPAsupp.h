/* $Id$ */

#ifndef __IPA_H__
#define __IPA_H__

#include <apricot.h>
#include <Image.h>

#ifndef dPROFILE
#define dPROFILE  SV ** temporary_prf_Sv
#endif

#define createImage(w,h,type)               create_object("Prima::Image","iii","width",(w),"height",(h),"type",(type))
#define createNamedImage(w,h,type,name)     create_object("Prima::Image","iiis","width",(w),"height",(h),"type",(type),"name",(name))
#define destroyImage(img)                   Object_destroy((Handle)img)

#ifndef min
#define min(x,y)                ((x)<(y) ? (x) : (y))
#endif
#ifndef max
#define max(x,y)                ((x)>(y) ? (x) : (y))
#endif
#ifndef sign
#define sign(x)                 ((x)<0 ? -1 : ((x)>0 ? 1 : 0))
#endif

#define COMBINE_MAXABS          1
#define COMBINE_SUMABS          2
#define COMBINE_SUM             3
#define COMBINE_SQRT            4
#define COMBINE_SIGNEDMAXABS    5
#define COMBINE_MULTIPLY        6
#define COMBINE_FIRST           COMBINE_MAXABS
#define COMBINE_LAST            COMBINE_MULTIPLY
                                        
#define CONV_TRUNCABS           1
#define CONV_TRUNC              2
#define CONV_SCALE              3
#define CONV_SCALEABS           4
#define CONV_FIRST              CONV_TRUNCABS
#define CONV_LAST               CONV_SCALEABS

extern PImage                           create_compatible_image(PImage,Bool);
extern PImage_vmt                       CImage;

typedef float Float;
typedef double Double;

#define dPIX_ARGS int x, y, h, w, sls, dls, src_ls, dst_ls, in_type;\
   Byte *dsrc, *ddst
#define PIX_INITARGS(in,out) \
   dsrc = (in)->data;\
   sls = (in)->lineSize;\
   ddst = (out)->data;\
   dls = (out)->lineSize;\
   in_type = (in)->type;\
   h = (in)->h;\
   w = (in)->w;
#define PIX_SWITCH switch(in_type) {
#define PIX_TYPE2(type1,type2,op) {\
   type1 * src = ( type1 *) dsrc;\
   type2 * dst = ( type2 *) ddst;\
   src_ls=sls/sizeof(type1);\
   dst_ls=dls/sizeof(type2);\
   for ( y = 0; y < h; y++, dsrc += sls, ddst += dls, src = (type1*)dsrc, dst =(type2*)ddst){\
      for ( x = 0; x < w; x++, src++, dst++) {\
         *dst = (type2)(op);\
      }\
   }\
}
#define PIX_CASE(type,op) case im##type:\
   PIX_TYPE2(type,type,op)\
   break
#define PIX_CASE2(type1,type2,op) case im##type1:\
   PIX_TYPE2(type1,type2,op)\
   break
#define PIX_END_SWITCH default: croak("%s: unsupported pixel type", method); }
#define PIX_BODY(op) \
   PIX_CASE(Byte,op);\
   PIX_CASE(Short,op);\
   PIX_CASE(Long,op);\
   PIX_CASE(Float,op);\
   PIX_CASE(Double,op);
#define PIX_BODY2(type,op) \
   PIX_CASE2(Byte,type,op);\
   PIX_CASE2(Short,type,op);\
   PIX_CASE2(Long,type,op);\
   PIX_CASE2(Float,type,op);\
   PIX_CASE2(Double,type,op);

#define PIX_SRC_DST(src,dst,op) \
{\
   dPIX_ARGS;\
   PIX_INITARGS(src,dst)\
   PIX_SWITCH\
   PIX_BODY(op)\
   PIX_END_SWITCH\
}

#define PIX_SRC_DST2(src,dst,type,op) \
{\
   dPIX_ARGS;\
   PIX_INITARGS(src,dst)\
   PIX_SWITCH\
   PIX_BODY2(type,op)\
   PIX_END_SWITCH\
}

#endif /* __IPA_H__ */
