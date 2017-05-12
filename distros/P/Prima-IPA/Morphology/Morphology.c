/* $Id$ */

#include "IPAsupp.h"
#include "Morphology.h"
#include "Morphology.inc"
#include "MorphologySupp.h"

#define bwt_pix(x,n)      (((x) ? 1 : 0)<<(n))

PImage bw8bpp_transform(const char *method,PImage img, const Byte *transtbl,int expandEdges)
{
    PImage oimg;
    int x,y;
    static int Number=0;
    char ImgName[256];
    Byte *bufp,*pu,*p,*pd;
    sprintf(ImgName,"BW8bpp_#%d",++Number);
    oimg=createNamedImage(img->w,img->h,imByte,ImgName);
    if (!oimg) {
        croak("%s: can't create outputimage",method);
    }
    for (y=1,
          pu=(img->data+img->lineSize*2),
          p=(img->data+img->lineSize),
          pd=img->data,
          bufp=oimg->data+oimg->lineSize;
         y<(img->h-1);
         y++,
          pu+=img->lineSize,
          p+=img->lineSize,
          pd+=img->lineSize,
          bufp+=oimg->lineSize) {
        for (x=1; x<(img->w-1); x++) {
            bufp[x]=transtbl[
                     bwt_pix(pu[x-1],4)+bwt_pix(pu[x],3)+bwt_pix(pu[x+1],2)+
                     bwt_pix( p[x-1],5)+bwt_pix( p[x],0)+bwt_pix( p[x+1],1)+
                     bwt_pix(pd[x-1],6)+bwt_pix(pd[x],7)+bwt_pix(pd[x+1],8)
                    ];
        }
    }

    if (expandEdges) {
        pu=(img->data+img->lineSize*2);
        p=(img->data+img->lineSize);
        pd=img->data;
        bufp=oimg->data+oimg->lineSize;
        /* processing bottom left/right corners */
        oimg->data[0]=transtbl[
                       bwt_pix( p[0],4)+bwt_pix( p[0],3)+bwt_pix( p[1],2)+
                       bwt_pix(pd[0],5)+bwt_pix(pd[0],0)+bwt_pix(pd[1],1)+
                       bwt_pix(pd[0],6)+bwt_pix(pd[0],7)+bwt_pix(pd[1],8)
                      ];
        oimg->data[oimg->w-1]=transtbl[
                               bwt_pix( p[img->w-2],4)+bwt_pix( p[img->w-1],3)+bwt_pix( p[img->w-1],2)+
                               bwt_pix(pd[img->w-2],5)+bwt_pix(pd[img->w-1],0)+bwt_pix(pd[img->w-1],1)+
                               bwt_pix(pd[img->w-2],6)+bwt_pix(pd[img->w-1],7)+bwt_pix(pd[img->w-1],8)
                              ];
        /* processing left & right edges */
        for (y=1;
             y<(img->h-1);
             y++,
              pu+=img->lineSize,
              p+=img->lineSize,
              pd+=img->lineSize,
              bufp+=oimg->lineSize) {
            bufp[0]=transtbl[
                     bwt_pix(pu[0],4)+bwt_pix(pu[0],3)+bwt_pix(pu[1],2)+
                     bwt_pix( p[0],5)+bwt_pix( p[0],0)+bwt_pix( p[1],1)+
                     bwt_pix(pd[0],6)+bwt_pix(pd[0],7)+bwt_pix(pd[1],8)
                    ];
            bufp[oimg->w-1]=transtbl[
                             bwt_pix(pu[img->w-2],4)+bwt_pix(pu[img->w-1],3)+bwt_pix(pu[img->w-1],2)+
                             bwt_pix( p[img->w-2],5)+bwt_pix( p[img->w-1],0)+bwt_pix( p[img->w-1],1)+
                             bwt_pix(pd[img->w-2],6)+bwt_pix(pd[img->w-1],7)+bwt_pix(pd[img->w-1],8)
                            ];
        }

        /* processing top left/right corners (note: bufp pointing
         at this point precisely at last image scanline as well
         as p */
        oimg->data[0]=transtbl[
                       bwt_pix( p[0],4)+bwt_pix( p[0],3)+bwt_pix( p[1],2)+
                       bwt_pix( p[0],5)+bwt_pix( p[0],0)+bwt_pix( p[1],1)+
                       bwt_pix(pd[0],6)+bwt_pix(pd[0],7)+bwt_pix(pd[1],8)
                      ];
        oimg->data[oimg->w-1]=transtbl[
                               bwt_pix( p[img->w-2],4)+bwt_pix( p[img->w-1],3)+bwt_pix( p[img->w-1],2)+
                               bwt_pix( p[img->w-2],5)+bwt_pix( p[img->w-1],0)+bwt_pix( p[img->w-1],1)+
                               bwt_pix(pd[img->w-2],6)+bwt_pix(pd[img->w-1],7)+bwt_pix(pd[img->w-1],8)
                              ];

        /* processing top/bottom edges */
        bufp=oimg->data;
        pd=p=img->data;
        pu=img->data+img->lineSize;
        for (x=1; x<(img->w-1); x++) {
            bufp[x]=transtbl[
                     bwt_pix(pu[x-1],4)+bwt_pix(pu[x],3)+bwt_pix(pu[x+1],2)+
                     bwt_pix( p[x-1],5)+bwt_pix( p[x],0)+bwt_pix( p[x+1],1)+
                     bwt_pix(pd[x-1],6)+bwt_pix(pd[x],7)+bwt_pix(pd[x+1],8)
                    ];
        }
        bufp=oimg->data+oimg->lineSize*(oimg->h-1);
        pd=img->data+img->lineSize*(img->h-2);
        pu=p=pd+img->lineSize;
        for (x=1; x<(img->w-1); x++) {
            bufp[x]=transtbl[
                     bwt_pix(pu[x-1],4)+bwt_pix(pu[x],3)+bwt_pix(pu[x+1],2)+
                     bwt_pix( p[x-1],5)+bwt_pix( p[x],0)+bwt_pix( p[x+1],1)+
                     bwt_pix(pd[x-1],6)+bwt_pix(pd[x],7)+bwt_pix(pd[x+1],8)
                    ];
        }

    }
    return oimg;
}

PImage IPA__Morphology_BWTransform(PImage img,HV *profile)
{
    dPROFILE;
    const char *method="IPA::Morphology::BWTransform";
    PImage oimg;
    unsigned char *transtbl = nil;
    
    if ( !img || !kind_of(( Handle) img, CImage))
       croak("%s: not an image passed", "IPA::Morphology::BWTransform");
 
    if (pexist(lookup)) {
        SV *tblstr=pget_sv(lookup);
        if (SvPOK(tblstr)) {
            STRLEN tbllen;
            transtbl=SvPV(tblstr,tbllen);
            if (tbllen!=512) {
                croak("%s: 'lookup' is %d bytes long, must be 512",method,tbllen);
            }
        }
        else {
            croak("%s : 'lookup' is not a string",method);
        }
    } else {
        croak("%s : 'lookup' option missed",method);
    } 

    switch (img->type) {
        case imByte:
            oimg=bw8bpp_transform(method,img,transtbl,1);
            break;
        default:
            croak("%s: support for this type of images isn't realized yet",method);
    }

    return oimg;
}
