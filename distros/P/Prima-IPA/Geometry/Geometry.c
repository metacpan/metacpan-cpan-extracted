/* $Id$ */

#include "IPAsupp.h"
#include "Geometry.h"
#include "Geometry.inc"
#include "GeometrySupp.h"

PImage IPA__Geometry_mirror(PImage img,HV *profile)
{
    dPROFILE;
    const char *method="IPA::Geometry::mirror";
    PImage oimg;
    int mType=0;
    int y;

    if ( !img || !kind_of(( Handle) img, CImage))
       croak("%s: not an image passed", method);
    
    if (pexist(type)) {
        mType=pget_i(type);
    }

    switch (mType) {
        case HORIZONTAL:
            {
                Byte *pi,*po;
                oimg=createNamedImage(img->w,img->h,img->type,method);
                if ((oimg->type & imGrayScale)==0) {
                    memcpy(oimg->palette,img->palette,img->palSize*sizeof(RGBColor));
                    oimg->palSize=img->palSize;
                }
                if (!oimg) {
                    croak("%s: can't create output image",method);
                }
                for (y=0,pi=img->data,po=(oimg->data+oimg->lineSize*(oimg->h-1)); y<img->h; y++,pi+=img->lineSize,po-=oimg->lineSize) {
                    memcpy(po,pi,img->lineSize);
                }
            }
            break;
        case VERTICAL:
            {
                int x;
                oimg=createNamedImage(img->w,img->h,img->type,method);
                if ((oimg->type & imGrayScale)==0) {
                    memcpy(oimg->palette,img->palette,img->palSize*sizeof(RGBColor));
                    oimg->palSize=img->palSize;
                }
                switch (img->type & imBPP) {
                    case imbpp1:
                        {
                            Byte *pi,*po;
                            int x1;
                            for (y=0,pi=img->data,po=oimg->data; y<img->h; y++,pi+=img->lineSize,po+=oimg->lineSize) {
                                po[(oimg->w-1)>>3]=0;
                                for (x=0,x1=(oimg->w-1); x<img->w; x++,x1--) {
                                    if ((x1%8)==7) {
                                        po[x1>>3]=0;
                                    }
                                    po[x1>>3]|=((pi[x>>3] >> (7-(x & 7))) & 1)<<(7-(x1 & 7));
                                }
                            }
                        }
                        break;
                    case imbpp4:
                        {
                            Byte *pi,*po,p;
                            int x1;
                            for (y=0,pi=img->data,po=oimg->data; y<img->h; y++,pi+=img->lineSize,po+=oimg->lineSize) {
                                po[(oimg->w-1)>>1]=0;
                                for (x=0,x1=(oimg->w-1); x<img->w; x++,x1--) {
                                    p=pi[x>>1];
                                    p=(x&1 ? p : (p>>4)) & 0x0f;
                                    if (x1&1) {
                                        po[x1>>1]=p;
                                    }
                                    else {
                                        po[x1>>1]|=p<<4;
                                    }
                                }
                            }
                        }
                        break;
                    case imbpp8:
                        {
                            Byte *pi,*po;
                            for (y=0,pi=img->data,po=oimg->data; y<img->h; y++,pi+=img->lineSize,po+=oimg->lineSize) {
                                for (x=0; x<img->w; x++) {
                                    po[img->w-x-1]=pi[x];
                                }
                            }
                        }
                        break;
                    case imbpp16:
                        {
                            Short *pi,*po;
                            for (y=0,pi=(Short*)img->data,po=(Short*)oimg->data; y<img->h; y++,(*((Byte**)&pi))+=img->lineSize,(*((Byte**)&po))+=oimg->lineSize) {
                                for (x=0; x<img->w; x++) {
                                    po[img->w-x-1]=pi[x];
                                }
                            }
                        }
                        break;
                    case imbpp24:
                        {
                            PRGBColor pi,po;
                            for (y=0,pi=(PRGBColor)img->data,po=(PRGBColor)oimg->data; y<img->h; y++,(*((Byte**)&pi))+=img->lineSize,(*((Byte**)&po))+=oimg->lineSize) {
                                for (x=0; x<img->w; x++) {
                                    po[img->w-x-1]=pi[x];
                                }
                            }
                        }
                        break;
                    case imbpp32:
                        {
                            U32 *pi,*po;
                            for (y=0,pi=(U32*)img->data,po=(U32*)oimg->data; y<img->h; y++,(*((Byte**)&pi))+=img->lineSize,(*((Byte**)&po))+=oimg->lineSize) {
                                for (x=0; x<img->w; x++) {
                                    po[img->w-x-1]=pi[x];
                                }
                            }
                        }
                        break;
                    case imbpp64:
                        {
                            typedef Byte pix64[8];
                            pix64 *pi,*po;
                            for (y=0,pi=(pix64*)img->data,po=(pix64*)oimg->data; y<img->h; y++,(*((Byte**)&pi))+=img->lineSize,(*((Byte**)&po))+=oimg->lineSize) {
                                for (x=0; x<img->w; x++) {
                                    memcpy(po,pi,sizeof(pix64));
                                }
                            }
                        }
                        break;
                    case imbpp128:
                        {
                            typedef Byte pix128[8];
                            pix128 *pi,*po;
                            for (y=0,pi=(pix128*)img->data,po=(pix128*)oimg->data; y<img->h; y++,(*((Byte**)&pi))+=img->lineSize,(*((Byte**)&po))+=oimg->lineSize) {
                                for (x=0; x<img->w; x++) {
                                    memcpy(po,pi,sizeof(pix128));
                                }
                            }
                        }
                        break;
                    default:
                        croak("%s: unsupported image type",method);
                }
            }
            break;
        default:
            croak("%s: %d is unknown type of mirroring",method,mType);
    }

    return oimg;
}

PImage IPA__Geometry_rotate90(PImage img, Bool clockwise)
{
	const char *method="IPA::Geometry::rotate90";
	PImage nimg;

	register Byte *src;
	int bs, sdw, ddh, w, y;

	if ( !img || !kind_of(( Handle) img, CImage))
		croak("%s: not an image passed", method);

	if (( img-> type & imBPP) < 8) {
	   	Handle convt, type8;
	        convt = img-> self-> dup((Handle) img);
		CImage(convt)-> set_type( convt, imbpp8);
		type8 = ( Handle) IPA__Geometry_rotate90((PImage) convt, clockwise);
		Object_destroy( convt);

		CImage(type8)-> set_conversion( type8, ictNone);
		CImage(type8)-> set_type( type8, img-> type);
		CImage(type8)-> set_conversion( type8, img-> conversion);
		return (PImage) type8;
	}

	nimg = createImage( img-> h, img-> w, img-> type);
	memcpy( nimg-> palette, img-> palette, ( nimg-> palSize = img-> palSize) * 3);

	w = img-> w;
	bs = (img-> type & imBPP) / 8;
	src = img-> data;
	sdw = img-> lineSize - w * bs;
	ddh = nimg-> lineSize;

	if ( clockwise) {
	   	if ( bs == 1) {
			Byte * dst0 = nimg-> data + nimg-> w - ddh - 1;
			for ( y = 0; y < img-> h; y++) {
			   	register int x = w;
			   	register Byte * dst = dst0--;
				while (x--) 
					*(dst += ddh) = *src++;
				src += sdw;
			}
		} else {
			Byte * dst0 = nimg-> data + ( nimg-> w - 1) * bs;
			ddh -= bs;
			for ( y = 0; y < img-> h; y++) {
			   	register int x = w;
			   	register Byte * dst = dst0;
				while (x--) {
				   	register int b = bs;
					while ( b--) 
						*dst++ = *src++;
					dst += ddh;
					
				}
				src += sdw;
				dst0 -= bs;
			}
		}
	} else {
	   	if ( bs == 1) {
			Byte * dst0 = nimg-> data + nimg-> h * nimg-> lineSize;
			for ( y = 0; y < img-> h; y++) {
			   	register int x = w;
			   	register Byte * dst = dst0++;
				while (x--) 
					*(dst -= ddh) = *src++;
				src += sdw;
			}
		} else {
			Byte * dst0 = nimg-> data + ( nimg-> h - 1) * nimg-> lineSize;
			ddh += bs;
			for ( y = 0; y < img-> h; y++) {
			   	register int x = w;
			   	register Byte * dst = dst0;
				while (x--) {
				   	register int b = bs;
					while ( b--) 
						*dst++ = *src++;
					dst -= ddh;
				}
				src += sdw;
				dst0 += bs;
			}
		}
	}

	return nimg;
}

PImage IPA__Geometry_rotate180(PImage img)
{
	const char *method="IPA::Geometry::rotate180";
	PImage nimg;

	register Byte *src, *dst;
	int bs, dw, w, y;

	if ( !img || !kind_of(( Handle) img, CImage))
		croak("%s: not an image passed", method);

	if (( img-> type & imBPP) < 8) {
	   	Handle convt, type8;
	        convt = img-> self-> dup((Handle) img);
		CImage(convt)-> set_type( convt, imbpp8);
		type8 = ( Handle) IPA__Geometry_rotate180((PImage) convt);
		Object_destroy( convt);

		CImage(type8)-> set_conversion( type8, ictNone);
		CImage(type8)-> set_type( type8, img-> type);
		CImage(type8)-> set_conversion( type8, img-> conversion);
		return (PImage) type8;
	}

	nimg = createImage( img-> w, img-> h, img-> type);
	memcpy( nimg-> palette, img-> palette, ( nimg-> palSize = img-> palSize) * 3);

	w = img-> w;
	bs  = (img-> type & imBPP) / 8;
	dw  = img-> lineSize - w * bs;
	src = img-> data;
	dst = nimg-> data + nimg-> h * nimg-> lineSize - dw - bs;

   	if ( bs == 1) {
		for ( y = 0; y < img-> h; y++) {
		   	register int x = w;
			while (x--) 
				*dst-- = *src++;
			src += dw;
			dst -= dw;
		}
	} else {
	   	int bs2 = bs + bs;
		for ( y = 0; y < img-> h; y++) {
		   	register int x = w;
			while (x--) {
			   	register int b = bs;
				while ( b--) 
					*dst++ = *src++;
				dst -= bs2;
			}
			src += dw;
			dst -= dw;
		}
	}

	return nimg;
}
