/* $Id$ */

#include <stdarg.h>
#include "IPAsupp.h"
#include "Local.h"
#include "Local.inc"
#include "LocalSupp.h"

/* Флаги для быстрого Sobel */
#define SOBEL_COLUMN            0x0001
#define SOBEL_ROW               0x0002
#define SOBEL_NWSE              0x0004
#define SOBEL_NESW              0x0008

typedef enum {
    sobelColumn=0,
    sobelRow=1,
    sobelNWSE=2,
    sobelNESW=3
} OPERATOR_TYPE;

/*******************************************************************
 * Function    : crispeningByte
 * Parameters  : PImage img
 * Description : Applies crispening method to 8bpp grayscale image
 * Returns     : Newly created image with applied crispening.
 *******************************************************************/
PImage crispeningByte(PImage img)
{
    PImage oimg=createNamedImage(img->w,img->h,imByte,"crispening result");
    int x,y;
    unsigned char *p,*pu,*pd,*dst;
    if (oimg) {
        memcpy(oimg->data,img->data,img->lineSize);
        for (y=1,
             pu=img->data,
             p=(img->data+img->lineSize),
             pd=(img->data+img->lineSize*2),
             dst=(oimg->data+oimg->lineSize);
             y<(img->h-1);
             y++,
             pu+=img->lineSize,
             p+=img->lineSize,
             pd+=img->lineSize,
             dst+=oimg->lineSize) {
            dst[0]=p[0];
            dst[oimg->w-1]=p[img->w-1];
            for (x=1; x<(img->w-1); x++) {
                int v=9*(int)p[x]-p[x-1]-p[x+1]-pu[x-1]-pu[x]-pu[x+1]-pd[x-1]-pd[x]-pd[x+1];
                dst[x]=v<0 ? 0 : v>255 ? 255 : v;
            }
        }
        memcpy(dst,p,img->lineSize);
    }
    return oimg;
}

PImage IPA__Local_crispening(PImage img)
{
    PImage oimg;
    const char *method="IPA::Local::crispening";

    if ( !img || !kind_of(( Handle) img, CImage))
        croak("%s: not an image passed", method);

    switch (img->type) {
        case imByte:
            oimg=crispeningByte(img);
            break;
        default:
            croak("%s: unsupported image type: %08x",method,img->type);
    }

    if (!oimg) {
        croak("%s: can't create output image",method);
    }

    return oimg;
}

/****************************************************************************/
/* Быстрый Sobel-фильтр с комбинированием результатов работы разных         */
/* вариантов фильтра (row, column, nwse и nesw).                            */
/* Параметры функции:                                                       */
/* srcimg      - исходный 8bpp image;                                       */
/* jobMask     - комбинация SOBEL_* флагов, задающая, какие именно варианты */
/*               фильтра необходимо использовать при работе;                */
/* combineType - одна из COMBINE_* констант, задающих способ комбинирования */
/*               результатов работы работы разных разнавидностей фильтра;   */
/* conv        - задает способ конверсии общего результата в 8bpp image;    */
/* divisor     - делитель;                                                  */
/* Возвращает  - 8bpp image, если все нормально; иначе - nil                */
/****************************************************************************/

short sobel_combine(short *pixval,unsigned short combinetype)
{
    short comb=0;

    switch (combinetype) {
        case COMBINE_MAXABS:
            comb=max(abs(pixval[sobelColumn]),
                  max(abs(pixval[sobelRow]),
                  max(abs(pixval[sobelNWSE]),
                      abs(pixval[sobelNESW]))));
            break;
        case COMBINE_SIGNEDMAXABS:
            {
                OPERATOR_TYPE pixindex=sobelColumn;
                if (abs(pixval[sobelColumn])>abs(pixval[sobelRow])) {
                    pixindex=sobelColumn;
                } /* endif */
                if (abs(pixval[pixindex])<abs(pixval[sobelNWSE])) {
                    pixindex=sobelNWSE;
                } /* endif */
                if (abs(pixval[pixindex])<abs(pixval[sobelNESW])) {
                    pixindex=sobelNESW;
                } /* endif */
                comb=pixval[pixindex];
            }
            break;
        case COMBINE_SUMABS:
            comb=abs(pixval[sobelColumn])+
                  abs(pixval[sobelRow])+
                  abs(pixval[sobelNWSE])+
                  abs(pixval[sobelNESW]);
            break;
        case COMBINE_SUM:
            comb=pixval[sobelColumn]+
                  pixval[sobelRow]+
                  pixval[sobelNESW]+
                  pixval[sobelNWSE];
            break;
        case COMBINE_SQRT:
            {
                int sqr;
                sqr=pixval[sobelColumn]*pixval[sobelColumn]+
                    pixval[sobelRow]*pixval[sobelRow]+
                    pixval[sobelNESW]*pixval[sobelNESW]+
                    pixval[sobelNWSE]*pixval[sobelNWSE];
                comb=(short)sqrt(sqr);
            }
            break;
        case COMBINE_MULTIPLY:
            comb=pixval[sobelColumn]*
                  pixval[sobelRow]*
                  pixval[sobelNESW]*
                  pixval[sobelNWSE];
            break;
    } /* endswitch */

    return comb;
}

PImage fast_sobel( PImage srcimg,
                   unsigned short jobMask,
                   unsigned short combinetype,
                   unsigned short conv,
                   unsigned short divisor
                 )
{
    PImage dstimg=nil;
    short pixval[4]={0,0,0,0},pixval1[4]={0,0,0,0};
    int ypos,xpos,y;
    unsigned char *p1,*p2,*p3; /* Указатели на строки в image:
                                p1 - на одну выше текущей
                                p2 - текущая
                                p3 - на одну ниже текущей */
    unsigned char *p,*pu,*pd,*pl,*pr,*pur,*pul,*pdr,*pdl;
    short *imgbuf,*imgp,*imgp1;
    short minval=0,maxval=0,range=0;

    if (jobMask==0) {
        return nil;
    } /* endif */

    imgbuf=(short*)malloc(srcimg->w*srcimg->h*sizeof(short));
    if (imgbuf==nil) {
        return nil;
    } /* endif */
    memset(imgbuf,0,srcimg->w*srcimg->h*sizeof(short));

    p1=srcimg->data+(srcimg->lineSize<<1); /* <<1 - чтобы не множить на 2 */ 
    p2=srcimg->data+srcimg->lineSize;
    p3=srcimg->data;
    imgp=imgbuf+srcimg->w;
    for (ypos=srcimg->lineSize,y=1; ypos<(srcimg->dataSize-srcimg->lineSize); ypos+=srcimg->lineSize,y++) {
        for (xpos=1; xpos<(srcimg->w-1); xpos++) {
            imgp++;
            pu=p1+xpos,
            pd=p3+xpos,       /******************/
            pl=p2+xpos-1,     /* p1: pul pu pur */
            pr=p2+xpos+1,     /* p2: pl  X   pr */
            pul=p1+xpos-1,    /* p3: pdl pd pdr */
            pur=p1+xpos+1,    /******************/
            pdl=p3+xpos-1,
            pdr=p3+xpos+1;

            if (jobMask & SOBEL_COLUMN) {
                pixval[sobelColumn]=
                     *pul+*pu*2L+*pur-
                    (*pdl+*pd*2L+*pdr);
            } /* endif */
            if (jobMask & SOBEL_ROW) {
                pixval[sobelRow]=
                     *pul+*pl*2L+*pdl-
                    (*pur+*pr*2L+*pdr);
            } /* endif */
            if (jobMask & SOBEL_NWSE) {
                pixval[sobelNWSE]=
                     *pr+*pdr*2L+*pd-
                    (*pl+*pul*2L+*pu);
            } /* endif */
            if (jobMask & SOBEL_NESW) {
                pixval[sobelNESW]=
                     *pl+*pdl*2L+*pd-
                    (*pr+*pur*2L+*pu);
            } /* endif */

            *imgp=sobel_combine(pixval,combinetype)/divisor;

            if (conv==CONV_SCALEABS) {
                *imgp=abs(*imgp);
            } /* endif */
            if (*imgp<minval) {
                minval=*imgp;
            } /* endif */
            if (*imgp>maxval) {
                maxval=*imgp;
            } /* endif */
        } /* endfor */
        p1+=srcimg->lineSize;
        p2+=srcimg->lineSize;
        p3+=srcimg->lineSize;
        imgp++;
        imgp++;
    } /* endfor */

    /* Обрабатываем горизонтальные границы. */

    pu=srcimg->data+1;                                /* Верхняя граница */
    p1=srcimg->data+srcimg->lineSize+1;
    pd=srcimg->data+srcimg->lineSize*(srcimg->h-1)+1; /* Нижняя граница */
    p2=srcimg->data+srcimg->lineSize*(srcimg->h-2)+1;
    imgp=imgbuf+1;                                    /* Верхняя граница результата */
    imgp1=imgbuf+srcimg->w*(srcimg->h-1)+1;           /* Нижняя граница результата */
    for (xpos=1; xpos<(srcimg->w-1); xpos++) {
        if (jobMask & SOBEL_COLUMN) {
            pixval[sobelColumn]=
                 *(pu-1)+*pu*2L+*(pu+1)-
                (*(p1-1)+*p1*2L+*(p1+1));

            pixval1[sobelColumn]=
                 *(p2-1)+*p2*2L+*(p2+1)-
                (*(pd-1)+*pd*2L+*(pd+1));
        } /* endif */
        if (jobMask & SOBEL_ROW) {
            pixval[sobelRow]=
                 *(pu-1)*2L+*(p1-1)-
                (*(pu+1)*2L+*(p1+1));

            pixval1[sobelRow]=
                 *(p2-1)*2L+*(pd-1)-
                (*(p2+1)*2L+*(pd+1));
        } /* endif */
        if (jobMask & SOBEL_NWSE) {
            pixval[sobelNWSE]=(short)(
                 (*(p1+1)-*(pu-1))*2L);

            pixval1[sobelNWSE]=(short)(
                 (*(pd+1)-*(p2-1))*2L);
        } /* endif */
        if (jobMask & SOBEL_NESW) {
            pixval[sobelNESW]=(short)(
                 (*(p1-1)-*(pu+1))*2L);

            pixval1[sobelNESW]=(short)(
                 (*(pd-1)-*(p2+1))*2L);
        } /* endif */

        *imgp=sobel_combine(pixval,combinetype)/divisor;
        if (conv==CONV_SCALEABS) {
            *imgp=abs(*imgp);
        } /* endif */
        if (*imgp<minval) {
            minval=*imgp;
        } /* endif */
        if (*imgp>maxval) {
            maxval=*imgp;
        } /* endif */

        *imgp1=sobel_combine(pixval1,combinetype)/divisor;
        if (conv==CONV_SCALEABS) {
            *imgp1=abs(*imgp1);
        } /* endif */
        if (*imgp1<minval) {
            minval=*imgp1;
        } /* endif */
        if (*imgp1>maxval) {
            maxval=*imgp1;
        } /* endif */

        pu++;
        p1++;
        pd++;
        p2++;
        imgp++;
        imgp1++;
    } /* endfor */

    /* Обрабатываем вертикальные границы */

    pl=srcimg->data+srcimg->lineSize;       /* Левая граница. */
    pul=pl-srcimg->lineSize;
    pdl=pl+srcimg->lineSize;
    pr=pl+srcimg->w-1;                      /* Правая граница */
    pur=pr-srcimg->lineSize;
    pdr=pr+srcimg->lineSize;
    imgp=imgbuf+srcimg->w;
    imgp1=imgp+srcimg->w-1;
    for (ypos=1; ypos<(srcimg->h-1); ypos++) {
        if (jobMask & SOBEL_COLUMN) {
            pixval[sobelColumn]=
                 *pul*2L+*(pul+1)-
                (*pdl*2L+*(pdl+1));

            pixval1[sobelColumn]=
                 *pur*2L+*(pur-1)-
                (*pdr*2L+*(pdr-1));
        } /* endif */
        if (jobMask & SOBEL_ROW) {
            pixval[sobelRow]=
                 *pul+*pl*2L+*pdl-
                (*(pul+1)+*(pl+1)*2L+*(pdl+1));

            pixval1[sobelRow]=
                 *(pur-1)+*(pr-1)*2L+*(pdr-1)-
                 (*pur+*pr*2L+*pdr);
        } /* endif */
        if (jobMask & SOBEL_NWSE) {
            pixval[sobelNWSE]=(short)(
                 *(pdl+1)*2L-*pl*2L);

            pixval1[sobelNWSE]=(short)(
                 *pr*2L-*(pur-1)*2L);
        } /* endif */
        if (jobMask & SOBEL_NESW) {
            pixval[sobelNESW]=(short)(
                 *pl*2L-*(pul+1)*2L);

            pixval1[sobelNESW]=(short)(
                 *(pdr-1)*2L-*pr*2L);
        } /* endif */

        *imgp=sobel_combine(pixval,combinetype)/divisor;
        if (conv==CONV_SCALEABS) {
            *imgp=abs(*imgp);
        } /* endif */
        if (*imgp<minval) {
            minval=*imgp;
        } /* endif */
        if (*imgp>maxval) {
            maxval=*imgp;
        } /* endif */

        *imgp1=sobel_combine(pixval1,combinetype)/divisor;
        if (conv==CONV_SCALEABS) {
            *imgp1=abs(*imgp1);
        } /* endif */
        if (*imgp1<minval) {
            minval=*imgp1;
        } /* endif */
        if (*imgp1>maxval) {
            maxval=*imgp1;
        } /* endif */

        pl+=srcimg->lineSize;
        pul+=srcimg->lineSize;
        pdl+=srcimg->lineSize;
        pr+=srcimg->lineSize;
        pur+=srcimg->lineSize;
        pdr+=srcimg->lineSize;
        imgp+=srcimg->w;
        imgp1+=srcimg->w;
    } /* endfor */

    /* Производим перенос результатов работы в результирующий image */
    dstimg=createNamedImage(srcimg->w,srcimg->h,imByte,"sobel result");
    if (dstimg==nil) {
        return nil;
    } /* endif */

    imgp=imgbuf;
    p=dstimg->data;
    if (conv==CONV_SCALE || conv==CONV_SCALEABS) {
        range=maxval-minval;
        if (range==0) {
            range=1;
        } /* endif */
    } /* endif */
    for (ypos=0,y=0; ypos<dstimg->dataSize; ypos+=dstimg->lineSize,y++) {
        p1=p;
        for (xpos=0; xpos<dstimg->w; xpos++) {
            switch (conv) {
                case CONV_TRUNC:
                    *p1=max(min(*imgp,255),0);
                    break;
                case CONV_TRUNCABS:
                    *p1=min(abs(*imgp),255);
                    break;
                case CONV_SCALEABS:
                case CONV_SCALE:
                    *p1=(((*imgp-minval)*255L)/range);
                    break;
                default:
                    break;
            } /* endswitch */
            p1++;
            imgp++;
        } /* endfor */
        p+=dstimg->lineSize;
    } /* endfor */

    free(imgbuf);

    return dstimg;
}

PImage IPA__Local_sobel(PImage img,HV *profile)
{
    dPROFILE;
    const char *method="IPA::Local::sobel";
    PImage oimg;
    unsigned short jobMask=SOBEL_NWSE|SOBEL_NESW;
    unsigned short combineType=COMBINE_MAXABS;
    unsigned short conversionType=CONV_SCALEABS;
    unsigned short divisor=1;

    if ( !img || !kind_of(( Handle) img, CImage)) 
       croak("%s: not an image passed", method);

    if (pexist(jobMask)) {
        jobMask=(unsigned short)pget_i(jobMask);
        if ((jobMask & ~(SOBEL_NESW|SOBEL_NWSE|SOBEL_COLUMN|SOBEL_ROW))!=0) {
            croak("%s: illegal job mask defined",method);
        }
    }
    if (pexist(combineType)) {
        combineType=(unsigned short)pget_i(combineType);
        if (combineType<1 || combineType>5) {
            croak("%s: illegal combination type value %d",method,combineType);
        }
    }
    if (pexist(conversionType)) {
        conversionType=(unsigned short)pget_i(conversionType);
        if (conversionType<1 || conversionType>4) {
            croak("%s: illegal conversion type value %d",method,conversionType);
        }
    }
    if (pexist(divisor)) {
        divisor=(unsigned short)pget_i(divisor);
        if (divisor==0) {
            croak("%s: divisor must not be equal to zero",method);
        }
    }

    switch (img->type) {
        case imByte:
            oimg=fast_sobel(img,jobMask,combineType,conversionType,divisor);
            break;
        default:
            croak("%s: unsupported image type",method);
    }

    if (!oimg) {
        croak("%s: can't create output image",method);
    }

    return oimg;
}

static PImage
filter3x3( const char * method, PImage img, 
           double *matrix, double divisor, Bool rawOutput, Bool expandEdges, 
           int conversionType, unsigned short edgecolor)
{
    PImage oimg,bufimg;
    long minval=0,maxval=0,range;
    int x,y;
    long *bufp;
    Byte *p,*pu,*pd;

    switch (img->type) {
        case imByte:
            {
                static int bufNumber=0;
                char bufImgName[256];
                sprintf(bufImgName,"filter3x3_buf#%d",++bufNumber);
                bufimg=createNamedImage(img->w,img->h,imLong,bufImgName);
                if (!bufimg) {
                    croak("%s: can't create intermediate buffer",method);
                }
                for (y=1,
                      pu=(img->data+img->lineSize*2),
                      p=(img->data+img->lineSize),
                      pd=img->data,
                      bufp=(long*)(bufimg->data+bufimg->lineSize);
                     y<(img->h-1);
                     y++,
                      pu+=img->lineSize,
                      p+=img->lineSize,
                      pd+=img->lineSize,
                      (*((Byte**)&bufp))+=bufimg->lineSize) {
                    for (x=1; x<(img->w-1); x++) {
                        bufp[x]=(long)(
			        (matrix[0]*pu[x-1]+matrix[1]*pu[x]+matrix[2]*pu[x+1]+
                                 matrix[3]* p[x-1]+matrix[4]* p[x]+matrix[5]* p[x+1]+
                                 matrix[6]*pd[x-1]+matrix[7]*pd[x]+matrix[8]*pd[x+1])/divisor);
                        if (x==1 && y==1) {
                            minval=maxval=bufp[x];
                        }
                        else if (minval>bufp[x]) {
                            minval=bufp[x];
                        }
                        else if (maxval<bufp[x]) {
                            maxval=bufp[x];
                        }
                    }
                }

                if (expandEdges) {
                    pu=(img->data+img->lineSize*2);
                    p=(img->data+img->lineSize);
                    pd=img->data;
                    bufp=(long*)(bufimg->data+bufimg->lineSize);
                    /* processing bottom left/right corners */
                    ((long*)bufimg->data)[0]=(long)(
		                             (matrix[0]* p[0]+matrix[1]* p[0]+matrix[2]* p[1]+
                                              matrix[3]*pd[0]+matrix[4]*pd[0]+matrix[5]*pd[1]+
                                              matrix[6]*pd[0]+matrix[7]*pd[0]+matrix[8]*pd[1])/divisor);
                    minval=min(minval,((long*)bufimg->data)[0]);
                    maxval=max(maxval,((long*)bufimg->data)[0]);
                    ((long*)bufimg->data)[bufimg->w-1]=(long)(
		                                       (matrix[0]* p[img->w-2]+matrix[1]* p[img->w-1]+matrix[2]* p[img->w-1]+
                                                        matrix[3]*pd[img->w-2]+matrix[4]*pd[img->w-1]+matrix[5]*pd[img->w-1]+
                                                        matrix[6]*pd[img->w-2]+matrix[7]*pd[img->w-1]+matrix[8]*pd[img->w-1])/divisor);
                    minval=min(minval,((long*)bufimg->data)[bufimg->w-1]);
                    maxval=max(maxval,((long*)bufimg->data)[bufimg->w-1]);
                    /* processing left & right edges */
                    for (y=1;
                         y<(img->h-1);
                         y++,
                          pu+=img->lineSize,
                          p+=img->lineSize,
                          pd+=img->lineSize,
                          (*((Byte**)&bufp))+=bufimg->lineSize) {
                        bufp[0]=(long)((matrix[0]*pu[0]+matrix[1]*pu[0]+matrix[2]*pu[1]+
                                 matrix[3]* p[0]+matrix[4]* p[0]+matrix[5]* p[1]+
                                 matrix[6]*pd[0]+matrix[7]*pd[0]+matrix[8]*pd[1])/divisor);
                        if (minval>bufp[0]) {
                            minval=bufp[0];
                        }
                        else if (maxval<bufp[0]) {
                            maxval=bufp[0];
                        }
                        bufp[bufimg->w-1]=(long)(
			                  (matrix[0]*pu[img->w-2]+matrix[1]*pu[img->w-1]+matrix[2]*pu[img->w-1]+
                                           matrix[3]* p[img->w-2]+matrix[4]* p[img->w-1]+matrix[5]* p[img->w-1]+
                                           matrix[6]*pd[img->w-2]+matrix[7]*pd[img->w-1]+matrix[8]*pd[img->w-1])/divisor);
                        if (minval>bufp[bufimg->w-1]) {
                            minval=bufp[bufimg->w-1];
                        }
                        else if (maxval<bufp[bufimg->w-1]) {
                            maxval=bufp[bufimg->w-1];
                        }
                    }

                    /* processing top left/right corners (note: bufp pointing
                    at this point precisely at last image scanline as well
                    as p */
                    ((long*)bufimg->data)[0]=(long)(
		                             (matrix[0]* p[0]+matrix[1]* p[0]+matrix[2]* p[1]+
                                              matrix[3]* p[0]+matrix[4]* p[0]+matrix[5]* p[1]+
                                              matrix[6]*pd[0]+matrix[7]*pd[0]+matrix[8]*pd[1])/divisor);
                    minval=min(minval,((long*)bufimg->data)[0]);
                    maxval=max(maxval,((long*)bufimg->data)[0]);
                    ((long*)bufimg->data)[bufimg->w-1]=(Byte)(
		                                       (matrix[0]* p[img->w-2]+matrix[1]* p[img->w-1]+matrix[2]* p[img->w-1]+
                                                        matrix[3]* p[img->w-2]+matrix[4]* p[img->w-1]+matrix[5]* p[img->w-1]+
                                                        matrix[6]*pd[img->w-2]+matrix[7]*pd[img->w-1]+matrix[8]*pd[img->w-1])/divisor);
                    minval=min(minval,((long*)bufimg->data)[bufimg->w-1]);
                    maxval=max(maxval,((long*)bufimg->data)[bufimg->w-1]);

                    /* processing top/bottom edges */
                    bufp=(long*)bufimg->data;
                    pd=p=img->data;
                    pu=img->data+img->lineSize;
                    for (x=1; x<(img->w-1); x++) {
                        bufp[x]=(long)((matrix[0]*pu[x-1]+matrix[1]*pu[x]+matrix[2]*pu[x+1]+
                                 matrix[3]* p[x-1]+matrix[4]* p[x]+matrix[5]* p[x+1]+
                                 matrix[6]*pd[x-1]+matrix[7]*pd[x]+matrix[8]*pd[x+1])/divisor);
                        if (minval>bufp[x]) {
                            minval=bufp[x];
                        }
                        else if (maxval<bufp[x]) {
                            maxval=bufp[x];
                        }
                    }
                    bufp=(long*)(bufimg->data+bufimg->lineSize*(bufimg->h-1));
                    pd=img->data+img->lineSize*(img->h-2);
                    pu=p=pd+img->lineSize;
                    for (x=1; x<(img->w-1); x++) {
                        bufp[x]=(long)((matrix[0]*pu[x-1]+matrix[1]*pu[x]+matrix[2]*pu[x+1]+
                                 matrix[3]* p[x-1]+matrix[4]* p[x]+matrix[5]* p[x+1]+
                                 matrix[6]*pd[x-1]+matrix[7]*pd[x]+matrix[8]*pd[x+1])/divisor);
                        if (minval>bufp[x]) {
                            minval=bufp[x];
                        }
                        else if (maxval<bufp[x]) {
                            maxval=bufp[x];
                        }
                    }

                }

                range=maxval-minval;
            }
            break;
        default:
            croak("%s: unsupported image type",method);
    }

    if (rawOutput) {
        oimg=bufimg;
        if (!expandEdges) {
            /* Filling edges */
            long edgecol;
            edgecol=(edgecolor*range)/255+minval;
            bufp=(long*)(bufimg->data+bufimg->lineSize*(bufimg->h-1));
            for (x=0; x<bufimg->w; x++) {
                ((int*)bufimg->data)[x]=bufp[x]=edgecol;
            }
            for (y=1,bufp=(long*)(bufimg->data+bufimg->lineSize); y<(bufimg->h-1); y++,(*((Byte**)&bufp))+=bufimg->lineSize) {
                bufp[0]=bufp[bufimg->w-1]=edgecol;
            }
        }
    }
    else {
        if (conversionType==CONV_SCALEABS) {
            maxval=abs(maxval);
            minval=abs(minval);
            if (minval>maxval) {
                long tmp=maxval;
                maxval=minval;
                minval=tmp;
            }
            range=maxval-minval;
            if ( range == 0) range = 1;
        }
        oimg=createNamedImage(img->w,img->h,imByte,"filter3x3 result");
        if (oimg) {
            for (y=0,bufp=(long*)bufimg->data,p=oimg->data; y<oimg->h; y++,(*((Byte**)&bufp))+=bufimg->lineSize,p+=oimg->lineSize) {
                for (x=0; x<oimg->w; x++) {
                    switch (conversionType) {
                        case CONV_SCALE:
                            p[x]=(Byte)(((bufp[x]-minval)*255)/range);
                            break;
                        case CONV_SCALEABS:
                            p[x]=(Byte)(((abs(bufp[x])-minval)*255)/range);
                            break;
                        case CONV_TRUNCABS:
                            p[x]=abs(bufp[x])>255 ? 255 : abs(bufp[x]);
                            break;
                        case CONV_TRUNC:
                            p[x]=bufp[x]>255 ? 255 : (bufp[x]<0 ? 0 : (Byte)bufp[x]);
                            break;
                    }
                }
            }
            if (!expandEdges) {
                /* Filling edges */
                p=oimg->data+oimg->lineSize*(oimg->h-1);
                for (x=0; x<oimg->w; x++) {
                    oimg->data[x]=p[x]=(Byte)edgecolor;
                }
                for (y=1,p=oimg->data+oimg->lineSize; y<(oimg->h-1); y++,p+=oimg->lineSize) {
                    p[0]=p[bufimg->w-1]=(Byte)edgecolor;
                }
            }
        }
        destroyImage(bufimg);
    }

    if (!oimg) {
        croak("%s: can't create output image",method);
    }

    return oimg;
}

PImage IPA__Local_filter3x3(PImage img,HV *profile)
{
    dPROFILE;
    const char *method="IPA::Local::filter3x3";
    int conversionType=CONV_SCALEABS;
    unsigned short edgecolor=0;
    Bool rawOutput=false,expandEdges=false;
    double matrix[9];
    double divisor=1;

    if ( !img || !kind_of(( Handle) img, CImage)) 
       croak("%s: not an image passed", method);

    if (pexist(conversionType)) {
        conversionType=pget_i(conversionType);
        if (conversionType<1 || conversionType>4) {
            croak("%s: conversion type value %d is not valid",method,conversionType);
        }
    }
    if (pexist(rawOutput)) {
        rawOutput=pget_B(rawOutput);
    }
    if (pexist(expandEdges)) {
        expandEdges=pget_B(expandEdges);
    }
    if (pexist(edgecolor)) {
        edgecolor=(unsigned short)pget_i(edgecolor);
        if (edgecolor>255) {
            croak("%s: edge color value %d is not valid",method,edgecolor);
        }
    }
    if (pexist(divisor)) {
        divisor=pget_f(divisor);
        if (divisor==0) {
            croak("%s: divisor cannot be equal to 0",method);
        }
    }
    if (pexist(matrix)) {
        SV *sv=pget_sv(matrix);
        SV **mItem;
        AV *av;
        int i;
        if (!SvROK(sv) || (SvTYPE(SvRV(sv))!=SVt_PVAV)) {
            croak("%s: matrix is not an array",method);
        }
        av=(AV*)SvRV(sv);
        if (av_len(av)!=8) {
            croak("%s: incorrect length of matrix array",method);
        }
        for (i=0; i<9; i++) {
            mItem=av_fetch(av,i,0);
            if (!mItem) {
                croak("%s: empty matrix element #%d",method,i);
            }
            if (SvNOK(*mItem) || looks_like_number(*mItem)) {
                matrix[i]=SvNV(*mItem);
            }
            else {
                croak("%s: matrix's element #%d are not of type double or int",method,i);
            }
        }
    }
    else {
        croak("%s: matrix required",method);
    }
    return filter3x3( method, img, matrix, divisor, rawOutput, expandEdges, conversionType, edgecolor);
}    

PImage fast_median(PImage srcimg, int wx, int wy)
{
    PImage dstimg,mimg,msrcimg;
    int xpos,ypos,y,i,ltmdn=0,mdn=0;
    int wx2,wy2,w2,wh,pelshift,inshift,outshift;
    int dx=1; /* Hапpавление сдвига по гоpизонтали */
    int histogram[256];
    unsigned char *p,*baseline,*dstpos;
    Bool need_turn=false; /* необходимо ли pазвеpнуть напpавление движения окна */

    if (srcimg==nil) {
        return nil;
    } /* endif */
    if ((wx>srcimg->w) || (wy>srcimg->h)) {
        return nil;
    } /* endif */

    msrcimg=createNamedImage(srcimg->w+wx-1,srcimg->h+wy-1,imByte,"msrcimg");
    if (!msrcimg) {
        return nil;
    }

    y=0;
    wx2=(wx/2);
    wy2=(wy/2)*msrcimg->lineSize;
    for (ypos=0; ypos<msrcimg->dataSize; ypos+=msrcimg->lineSize) {
        memset(msrcimg->data+ypos,srcimg->data[y],wx2);
        memcpy(msrcimg->data+ypos+wx2,srcimg->data+y,srcimg->w);
        memset(msrcimg->data+ypos+wx2+srcimg->w,srcimg->data[y+srcimg->w-1],wx2);
        if ((ypos>=wy2) && (ypos<(msrcimg->dataSize-wy2-msrcimg->lineSize))) {
            y+=srcimg->lineSize;
        } /* endif */
    } /* endfor */

    mimg=createNamedImage(msrcimg->w,msrcimg->h,imByte,"mimg");
    if (!mimg) {
        destroyImage(msrcimg);
        return nil;
    }
    memcpy(mimg->data,msrcimg->data,msrcimg->dataSize);

    memset(histogram,0,sizeof(int)*256);

    w2=(wx*wy)/2; /* Количество точек в половине окна. */

    /* Пеpвый пpоход - вычисляем медиану пеpвого окна. */
    p=msrcimg->data;
    for (ypos=0; ypos<wy; ypos++) {
        for (xpos=0; xpos<wx; xpos++) {
            histogram[p[xpos]]++;
        } /* endfor */
        p+=msrcimg->lineSize;
    } /* endfor */
    for (i=0; i<256; i++) {
        if ((ltmdn+histogram[i])>=w2) {
            mdn=i; /* Вот это медиана и есть. ltmdn к этому моменту содеpжит
                    количество точек, с уpовнем меньше медианного */
            break;
        } /* endif */
        ltmdn+=histogram[i]; /* У нас еще есть запас для сдвижки медианы - сдвигаемся. */
    } /* endfor */
    mimg->data[(wy/2)*mimg->lineSize+wx/2]=mdn;

    /* Имеем первое окно и его медиану. Тепеpь надо двигаться. */
    baseline=msrcimg->data; /* базовая линия - самая нижняя в окне.
                            Будем сдвигать ее по меpе пеpемещения по Y-кооpдинате. */
    xpos=0;                /* смещение левого кpая окна */
    wh=msrcimg->lineSize*wy; /* Общий pазмеp сканстpок, покpываемых окном. */
    inshift=wx;            /* Смещение относительно левого кpая включаемой колонки */
    outshift=0;            /* Смещение относительно левого кpая исключаемой колонки */
    pelshift=(wy/2)*msrcimg->lineSize+wx/2; /* Смещение вычисляемой точки относительно
                                               левого нижнего кpая окна. */
    dstpos=mimg->data+pelshift+dx;
    for (; ; ) {
        unsigned char *pin,*pout;

        /* Пpоходим по высоте окна, выбpасываем уходящую колонку, включаем пpиходящую */
        if (!need_turn) {
            pin=baseline+xpos+inshift;
            pout=baseline+xpos+outshift;
            for (ypos=0; ypos<wy; ypos++, pin+=msrcimg->lineSize, pout+=msrcimg->lineSize) {
                if (*pout<mdn) {
                    ltmdn--;
                } /* endif */
                if (*pin<mdn) {
                    ltmdn++;
                } /* endif */
                histogram[*pout]--;
                histogram[*pin]++;
            } /* endfor */
        } /* endif */

        if (ltmdn>w2) { /* Это значит, что медиана _несомненно_ сместилась, пpичем - вниз. */
            /* Понижаем медиану */
            for (i=mdn-1; ; i--) {
                /* Конец цикла можно не пpовеpять: pано или поздно ltmdn все же
                 станет меньше w2; в "худшем" случае это пpоизойдет на 0-м
                 цвете, тогда ltmdn пpосто станет нулем.
                 Единственный ваpиант вылететь - ошибка пpи подсчете
                 гистогpаммы, поскольку сумма всех значений в ней всегда
                 должна быть pавна wx*wy */
                ltmdn-=histogram[i];
                if (ltmdn<=w2) { /* только что исключили медиану */
                    mdn=i;
                    break;
                } /* endif */
            } /* endfor */
        } /* endif */
        else {
            /* А тут надо пpовеpить - а не "ушла"-ли медиана ввеpх? */
            for (i=mdn; ; i++) {
                /* Здесь также конец цикла можно не пpовеpять по той же
                пpичине, что и для случая понижения гистогpаммы.
                Ваpиант "вылететь" - то же тот же. */
                if ((ltmdn+histogram[i])>w2) { /* Если истина - значит i - значение медианы */
                    mdn=i;
                    break;
                } /* endif */
                ltmdn+=histogram[i];
            } /* endfor */
        } /* endelse */
        *dstpos=mdn;

        if (need_turn) {
            need_turn=false;
            dstpos+=dx;
            continue;
        } /* endif */

        xpos+=dx; /* Сдвигаемся к следующему пикселу по X. */
        if (dx>0) {
            if ((xpos+wx)>=msrcimg->w) { /* Если двинемся еще pаз - пpавым кpаем
                                         окна вылезем за пpавый кpай image */
                need_turn=true;
            } /* endif */
        } /* endif */
        else { /* dx<0; тpетьего не дано */
            if (xpos==0) { /* Следующий шаг вынесет нас за левый кpай */
                need_turn=true;
            } /* endif */
        } /* endelse */
        if (need_turn) { /* Hадо сдвинуть окно ввеpх по image, посчитать медиану */
                         /* и двигаться дальше. */
            pout=baseline+xpos;
            baseline+=msrcimg->lineSize;
            dstpos+=mimg->lineSize;
            if ((baseline+wh)>(msrcimg->data+msrcimg->dataSize)) { /* Все, выше двигаться уже некуда */
                break;
            } /* endif */
            pin=baseline+wh-msrcimg->lineSize+xpos;
            for (i=0; i<wx; i++,pout++,pin++) { /* потопали по стpокам - включаемой и исключаемой */
                if (*pout<mdn) {
                    ltmdn--;
                } /* endif */
                if (*pin<mdn) {
                    ltmdn++;
                } /* endif */
                histogram[*pout]--;
                histogram[*pin]++;
            } /* endfor */
            /* Пеpесчет медианы будет пpоизведен на следующем пpоходе цикла. */

            /* Далее - пеpещилкиваем все значения, котоpые должны поменяться пpи 
            pазвоpоте. */
            dx=-dx;
            if (dx>0) {
                inshift=wx;
                outshift=0;
            } /* endif */
            else {
                inshift=-1;
                outshift=wx-1;
            } /* endelse */
        } /* endif */
        else {
            dstpos+=dx;
        } /* endelse */
    } /* endfor */

    dstimg=createNamedImage(srcimg->w,srcimg->h,imByte,"median result");
    if (dstimg) {
        for (ypos=0,y=wy2+wx2; ypos<dstimg->dataSize; ypos+=dstimg->lineSize,y+=mimg->lineSize) {
            memcpy(dstimg->data+ypos,mimg->data+y,dstimg->w);
        } /* endfor */
    }

    destroyImage(msrcimg);
    destroyImage(mimg);

    return dstimg;
}

PImage IPA__Local_median(PImage img,HV *profile)
{
    dPROFILE;
    const char *method="IPA::Local::median";
    PImage oimg;
    int wx=0,wy=0;

    if ( !img || !kind_of(( Handle) img, CImage))
      croak("%s: not an image passed", method);

    if (img->type!=imByte) {
        croak("%s: unsupported image type",method);
    }

    if (pexist(w)) {
        wx=pget_i(w);
    }
    if (pexist(h)) {
        wy=pget_i(h);
    }
    if (wx==0) {
        wx=wy;
    }
    if (wy==0) {
        wy=wx;
    }
    if (wx==0 && wy==0) {
        wx=wy=3;
    }
    if (wx<1 || (wx%2)==0) {
        croak("%s: %d is incorrect value for window width",method,wx);
    }
    if (wy<1 || (wy%2)==0) {
        croak("%s: %d is incorrect value for window height",method,wy);
    }
    if (wx>img->w) {
        croak("%s: window width more than image width",method);
    }
    if (wy>img->h) {
        croak("%s: window height more than image height",method);
    }

    if (!(oimg=fast_median(img,wx,wy))) {
        croak("%s: can't create output image",method);
    }

    return oimg;
}

/*
 * Union Related
 */
static int
find_compress( int *p, int node)
{
   if ( p[node] < 0)
      return node;
   else
      return p[node] = find_compress( p, p[ node]);
}

PImage union_find_ave( PImage in, int threshold)
{
   /* Input:*/
   /*    image*/
   /*    threshold value*/

   /* Output:  image with pixel values set to region's average*/
   PImage out;

   /* Data:    pointer image     <- basic structure*/
   int *p;

   /* Data:    sums image        <- Oracle()-related structure*/
   int *sums;

   /* Data:    sizes image       <- Oracle()-related structure*/
   int *sizes;

   /* Control variables:*/
   int x, y, w, h;
   int left, up, focus;

   /* Initialize: set sums to individual values,*/
   /*             sizes to one and pointers to -1*/
   w = in-> w;    h = in-> h;
   p = malloc( sizeof( int) * w * h);
   sums = malloc( sizeof( int) * w * h);
   sizes = malloc( sizeof( int) * w * h);
   for ( y = 0; y < h; y++)
      for ( x = 0; x < w; x++)
      {
         p[ y*w + x] = -1;
         sums[ y*w + x] = in-> data[ y * in-> lineSize + x];
         sizes[ y*w + x] = 1;
      }

   /* Special treatment of the first line:*/
   for ( x = 1; x < w; x++)
   {
      /* left <- FindCompress(0,x-1);*/
      left = find_compress( p, x - 1);
      /* focus <- FindCompress(0,x);*/
      focus = find_compress( p, x);
      /* if Oracle(left,focus) then Union(left,focus);*/
      if ( fabs(sums[ left] / (float) sizes[ left] - sums[ focus] / (float) sizes[ focus]) < threshold)
      {
         sums[left] += sums[focus];
         sizes[left] += sizes[focus];
         p[focus] = left;
      }
   }
   /* Flatten(0);*/
   for ( x = 0; x < w; x++) find_compress( p, x);

   /* Main loop*/
   for ( y = 1; y < h; y++)
   {
      /* Special treatment of the first pixel on every line:*/
      /* up <- FindCompress(y-1, 0);*/
      up = find_compress( p, w*(y-1));
      /* focus <- FindCompress(y,0);*/
      focus = find_compress( p, w*y);
      /* if Oracle(up,focus) then Union(up,focus);*/
      if ( fabs(sums[ up] / (float) sizes[ up] - sums[ focus] / (float) sizes[ focus]) < threshold)
      {
         sums[up] += sums[focus];
         sizes[up] += sizes[focus];
         p[focus] = up;
      }

      /* Line processing*/
      for ( x = 1; x < w; x++)
      {
         /* left <- FindCompress(y,x-1);*/
         left = find_compress( p, w*y+x-1);
         /* up <- FindCompress(y-1, x);*/
         up = find_compress( p, w*(y-1)+x);
         /* focus <- FindCompress(y,x);*/
         focus = find_compress( p, w*y+x);
         /* if Oracle(left,focus) then focus <- Union(left,focus);*/
         if ( fabs(sums[ left] / (float) sizes[ left] - sums[ focus] / (float) sizes[ focus]) < threshold)
         {
            sums[left] += sums[focus];
            sizes[left] += sizes[focus];
            p[focus] = left;
            focus = left;
         }
         /* if Oracle(up,focus) then Union(up,focus);*/
         if ((focus != up) && ( fabs(sums[ up] / (float) sizes[ up] - sums[ focus] / (float) sizes[ focus]) < threshold))
         {
            sums[up] += sums[focus];
            sizes[up] += sizes[focus];
            p[focus] = up;
         }
      }
      /* Flatten(y);*/
      for ( x = 0; x < w; x++) find_compress( p, w*y+x);
   }

   /* Finalize: create output image and color it*/
   out = createImage( in-> w, in-> h, in-> type);
   for ( y = 0; y < h; y++)
      for ( x = 0; x < w; x++)
      {
         focus = y*w+x;
         while ( p[ focus] >= 0) focus = p[ focus];   /* Only one or zero steps, no more, actually*/
         out-> data[ y*out-> lineSize + x] = (unsigned char)(sums[ focus] / (float) sizes[ focus] + 0.5);
      }
   /* Calculate the number of regions*/
   {
      int n = 0;
      for ( y = 0; y < h; y++)
         for ( x = 0; x < w; x++)
            if ( p[ y*w+x] < 0)
               n++;
   }
   /* Finalize: destroy temporary matrices*/
   free( p); free( sums); free( sizes);
   return out;
}

PImage IPA__Local_unionFind(PImage img,HV *profile)
{
    dPROFILE;
    typedef enum {
        UAve, Unknown=-1
    } UMethod;

    const char *method="IPA::Local::unionFind";
    PImage oimg;
    UMethod umethod=Unknown;
    struct {
        UMethod umethod;
        const char *name;
    } UnionMethods[] = {
            {UAve, "Ave"},
            {Unknown, NULL}
        };

    if ( !img || !kind_of(( Handle) img, CImage))
      croak("%s: not an image passed", method);

    if (img->type!=imByte) {
        croak("%s: unsupported image type",method);
    }

    if (pexist(method)) {
        char *mname=pget_c(method);
        int i;

        for (i=0; UnionMethods[i].name; i++) {
            if (stricmp(mname,UnionMethods[i].name)==0) {
                umethod=UnionMethods[i].umethod;
                break;
            }
        }
        if (umethod==Unknown) {
            croak("%s: unknown method",method);
        }
    }
    switch (umethod) {
        case UAve:
            {
                int threshold;

                if (pexist(threshold)) {
                    threshold=pget_i(threshold);
                }
                else {
                    croak("%s: threshold must be specified",method);
                }
                oimg=union_find_ave(img,threshold);
            }
            break;
        default:
            croak("%s: (internal) method unknown",method);
            break;
    }

    return oimg;
}

PImage IPA__Local_deriche(PImage img,HV *profile)
{
    dPROFILE;
    const char *method="IPA::Local::deriche";
    float alpha;

    if ( !img || !kind_of(( Handle) img, CImage))
      croak("%s: not an image passed", method);

    if (img->type!=imByte) {
        croak("%s: incorrect image type",method);
    }

    if (pexist(alpha)) {
        alpha=(float)pget_f(alpha);
    }
    else {
        croak("%s: alpha must be defined",method);
    }

    return deriche(method,img,alpha);
}

static PImage
hysteresis( PImage img, int thr0, int thr1, int conn8)
{
   PImage out;
   int x, y, changed, ls;
   Byte * src, * dst;

   
   out = create_compatible_image( img, false);
   ls = out-> lineSize;
   dst = out-> data;
   memset( dst, 0, out-> dataSize);
   changed = 1;
   while ( changed) {
      changed = 0;
      src = img-> data;
      dst = out-> data;
      for ( y = 0; y < img-> h; y++, src += img-> lineSize, dst += ls) {
	 for ( x = 0; x < img-> w; x++) {
	    if ( !dst[x]) {
	       if ( src[x] >= thr1) {
		  dst[x] = 255;
		  changed = 1;
	       } else if ( src[x] >= thr0) {
		  if (
		 	       dst[x]   || 
			       ( y > 0 && dst[x-ls])   || 
			       ( y < img->h && dst[x+ls]) || 
		        (x > 0 && 
			      (dst[x-1] || 
			      ( conn8 && y > 0 && dst[x-1-ls]) || 
			      ( conn8 && y < img->h && dst[x-1+ls]))
			) || 
			( x < img-> w && 
			      (dst[x+1] || 
			       ( conn8 && y > 0 && dst[x+1-ls]) || 
			       ( conn8 && y < img->h && dst[x+1+ls]))
			) 
		     ) {
		     dst[x] = 255;
		     changed = 1;
		  }
	       }
	    }
	 }
      }
   }
   return out;
}

PImage IPA__Local_hysteresis(PImage img,HV *profile)
{
    dPROFILE;
    const char *method="IPA::Local::hysteresis";
    int thr1, thr0, neighborhood = 8;

    if ( !img || !kind_of(( Handle) img, CImage))
      croak("%s: not an image passed", method);

    if ( img-> type != imByte)
       croak("%s: image is not 8-bit grayscale", method);

    if (pexist(threshold)) {
        SV * sv = pget_sv(threshold), **ssv;
	AV * av;
	if ( !SvOK(sv) || !SvROK(sv) || SvTYPE(SvRV(sv)) != SVt_PVAV)
	   croak("%s: threshold must be an array of two integer values",method);
	av = (AV*)SvRV(sv);
	if ( av_len(av) != 1)
	   croak("%s: threshold must be an array of two integer values",method);
	if ( !( ssv = av_fetch( av, 0, 0)))
	   croak("%s: threshold[0] array panic",method);
	thr0 = SvIV( *ssv);
	if ( !( ssv = av_fetch( av, 0, 0)))
	   croak("%s: threshold[1] array panic",method);
	thr1 = SvIV( *ssv);
	if ( thr0 < 0 || thr0 > 255 || thr1 < 0 || thr1 > 255)
	   croak("%s: treshold values must be from %d to %d", 0, 255);
	if ( thr0 > thr1) {
	   int x = thr0;
	   thr0 = thr1;
	   thr1 = x;
	}
	   
    }
    else {
        croak("%s: threshold must be defined",method);
    }

    if ( pexist( neighborhood)) {
       neighborhood = pget_i( neighborhood);
       if ( neighborhood != 4 && neighborhood != 8)
          croak( "%s: cannot handle neighborhoods other than 4 and 8", method);
    }
       
    return hysteresis(img,thr0,thr1,neighborhood==8);
}

static PImage
gaussian( const char * method, int size, double sigma, Bool laplacian, int mx, int my)
{
   register int j, k;
   double x, *e=0;
   int ls,s=size/2;
   PImage out;
   double *dst;
   Byte * data;
   double sigma2 = sigma * sigma;
   double sigma4 = - sigma2 * sigma2;
   /* check parameters */
   if (size < 2 || size % 2 == 0) 
       croak("%s: size of gaussian must be an odd number greater than two", method);
   if (sigma <= 0.0) 
       croak("%s: standard deviation of gaussian must be positive", method);
   if (!(e = (double *)malloc(((size/2)+1)*sizeof(double)))) {
      croak("%s: not enough memory\n", method);
   }
   out = createImage( size, size, imDouble);
   data = out-> data;
   ls = out-> lineSize / sizeof(double);
   sigma = 2*sigma*sigma;


   /* store one dimensional components */
   for (k=0; k<=size/2; k++) {
       x = ((double)(k-s)*(double)(k-s))/sigma;
       e[k] = exp(-x);
   }

   dst = (double*)data;
   for (j=0;j<size;j++, data += out->lineSize, dst = (double*)data){
      for (k=0;k<size;k++){
         double y = s - j, x = s - k;
         int ay = (j < s) ? j : 2 * s - j, ax = (k < s) ? k : 2 * s - k;
         *(dst++)=
            ( laplacian ? ((x*x/16 + y*y - sigma2)/sigma4) : 1) * e[ax*mx] * e[ay*my];
      }
   }

   if ( laplacian) {
      /* normalize to sum = 0 */
      double sum = out-> self-> get_stats(( Handle)out, isSum);
      out-> statsCache = 0;
      if ( sum != 0) {
         double * s = ( double*)(out-> data),
                  sub = sum / (out->w * out-> h);
         int sz = out-> dataSize / sizeof(double);
         while ( sz--) {
            *s = *s - sub;
             s++;
         }
      }
   }
   free(e);
   return out;
}

PImage IPA__Local_gaussian( int size, double sigma)
{
   return gaussian( "IPA::Local::gaussian", size, sigma, 0, 1, 1);
}

PImage IPA__Local_laplacian( int size, double sigma)
{
   return gaussian( "IPA::Local::laplacian", size, sigma, 1, 1, 1);
}

static PImage 
convolution( const char * method, PImage in, PImage kernel_img)
{ 
   register int j, k, l, m, n;
   double sum, ksum;
   int size = kernel_img-> w;
   int kls;
   int dls, sls, marg = size/2;
   double * dst, *src, *kernel, kill_kernel = 0, kill_img = 0;
   PImage out;

   if ( kernel_img-> type != imDouble) {
      kernel_img = (PImage)kernel_img-> self-> dup(( Handle) kernel_img);
      kernel_img-> self-> set_type(( Handle) kernel_img, imDouble);
      kill_kernel = 1;
   }
   if ( in-> type != imDouble) {
      in = (PImage)in-> self-> dup(( Handle) in);
      in-> self-> set_type(( Handle) in, imDouble);
      kill_img = 1;
   }
   if ( kernel_img-> w != kernel_img-> h) 
      croak("%s: kernel sides must be equal", method);
   kernel = ( double*)kernel_img-> data;
   if ( size % 2 == 0) 
      croak("%s: kernel size (%d) must be odd", method, size);
   if ( in-> w < size || in-> h < size) 
      croak("%s: kernel size (%d) must be smaller than dimensions of image (%d %d)", 
            method, size, in-> w, in-> h);
   
   out = create_compatible_image(in,false);
   dst = ( double*)out-> data;
   dls = out-> lineSize / sizeof(double);
   src = ( double*)in-> data;
   sls = in-> lineSize / sizeof(double);
   ksum = kernel_img-> self-> get_stats(( Handle) kernel_img, isSum);
   if ( ksum == 0) ksum = 1;
   kls  = kernel_img-> lineSize / sizeof(double) - size;
   ksum=1;
 
   for (j=marg; j<in->h-marg; j++) {
       for (k=marg; k<in->w-marg; k++) {
           for (sum=0.0,n=0,l=0; l<size; l++, n += kls) {
               for (m=0; m<size; m++) {
                   sum += src[(j-marg+l)*sls+k-marg+m]*kernel[n++];
               }
           }
           dst[j*dls+k] = sum/ksum;
       }
   }
   /* top and bottom margins */
   for (j=0; j<marg; j++) {
       for (k=0; k<in->w-marg; k++) {
           dst[j*dls+k] = dst[marg*dls+k];
           dst[(in->h-j-1)*dls+k] = dst[(in->h-marg-1)*dls+k];
       }
   }
 
   /* left and right margins */
   for (j=0; j<in->h; j++) {
       for (k=0; k<marg; k++) {
           dst[j*dls+k]=dst[j*dls+marg];
           dst[j*dls+in->w-k-1] = dst[j*dls+in->w-marg-1];
       }
   }

   if ( kill_kernel) Object_destroy((Handle) kernel_img);
   if ( kill_img)    Object_destroy((Handle) in);
   return out;
}

PImage 
IPA__Local_convolution( PImage img, PImage kernel_img)
{
   const char *method="IPA::Local::convolution";
   if ( !img || !kind_of(( Handle) img, CImage))
      croak("%s: not an image passed", method);
   if ( !kernel_img || !kind_of(( Handle) kernel_img, CImage))
      croak("%s: not an image passed", method);
   return convolution( method, img, kernel_img);
}

/*-General Information--------------------------------------------------------*/
/*                                                                            */
/*   This function computes a two-dimensional gradient (magnitude and         */
/*   direction) of an image, using two user-supplied convolution kernels.     */
/*   The magnitude is computed as the vector magnitude of the output          */
/*   of the two kernels, and the direction is computed as the angle           */
/*   between the two orthogonal gradient vectors.                             */
/*                                                                            */
/*----------------------------------------------------------------------------*/
/*-Background Information-----------------------------------------------------*/
/*                                                                            */
/*   Robinson, G.S.:                                                          */
/*   "Detection and Coding of Edges Using Directional Masks."                 */
/*   Optical Engineering, Vol. 16, No. 6 (Nov/Dec 1977), pp. 580-585          */
/*                                                                            */
/*----------------------------------------------------------------------------*/
/* Copyright (c) 1988 by the University of Arizona Digital Image Analysis Lab */
/*-Interface Information------------------------------------------------------*/
#define PI 3.14159265358979323846264338327950288419716939937510
static TwoImages 
gradients(
const char * method,          
PImage in,      /*  I   Pointer to the input image.                           */
double *vert,      /*  I   Pointer to a square convolution kernel[size][size] for*/
                /*      the y-derivative. It should return positive values    */
                /*      for gradients increasing to the "top" of the image.   */
double *horz,      /*  I   Pointer to a square convolution kernel[size][size] for*/
                /*      the x-derivative. It should return positive values    */
                /*      for gradients increasing to the "right" of the image. */
int size       /*  I   Kernel size in lines and pixels/line.                 */
/*----------------------------------------------------------------------------*/
) { register int j, k, l, m;
    double dv, dh;
    int sls, dls, n=size/2;
    Byte * src, *dst1, *dst2;
    TwoImages out;
    
    if ( in-> type != imByte)
       croak("%s: image is not 8-bit grayscale", method);
    if (size < 2 ||size%2 == 0)
        croak("%s: size of convolution mask must be an odd number greater than two", method);
    if (size > in->h ||  size > in->w) 
        croak("%s: image size must be equal to or greater than convolution mask size", method);

    /* create images of appropriate size */
    out. magnitude = ( Handle) create_compatible_image( in, false);
    out. direction = ( Handle) create_compatible_image( in, false);
    src = in-> data;
    dst1 = PImage(out.magnitude)->data;
    dst2 = PImage(out.direction)->data;
    sls = in-> lineSize;
    dls = PImage(out.magnitude)-> lineSize;

    /* compute convolution */
    for (j=n; j<in->h-n; j++) {
        for (k=n; k<in->w-n; k++) {
            int v;
            dv = dh = 0.0;
            for (l=0; l<size; l++) {
                for (m=0; m<size; m++) {
                    dv += (double)vert[l*size+m]*(double)src[(j-n+l)*sls+k-n+m];
                    dh += (double)horz[l*size+m]*(double)src[(j-n+l)*sls+k-n+m];
                }
            }
            v = (int)(sqrt(dv*dv+dh*dh)+.5);
            if ( v > 255) v = 255;
            dst1[j*dls+k] = (Byte)v;
            if (dh == 0.0) {
                if (dv > 0.0) {
                    dst2[j*dls+k] = (Byte)(128+PI*80.0/2.0+.5);
                } else if (dv < 0.0) {
                    dst2[j*dls+k] = (Byte)(128-PI*80.0/2.0+.5);
                } else {
                    dst2[j*dls+k] = 128;
                }
            } else {
                dst2[j*dls+k] = (Byte)(128+atan2(dv,dh)*80.0+.5);
            }
            /*
            dv *= dv; 
            dh *= dh; 
            v = (dv-dh)*(dv-dh);
            if ( v > 255) v = 255;
            dst2[j*dls+k] = v; 
            */
        }
    }

    /* fill top and bottom margins */
    for (j=0; j<n; j++) {
        for (k=n; k<in->w-n; k++) {
            dst1[j*dls+k] = dst1[n*dls+k];
            dst1[(in->h-j-1)*dls+k] = dst1[(in->h-n-1)*dls+k];
            dst2[j*dls+k] = dst2[n*dls+k];
            dst2[(in->h-j-1)*dls+k] = dst2[(in->h-n-1)*dls+k];
        }
    }

    /* fill left and right margins */
    for (j=0; j<in->h; j++) {
        for (k=0; k<n; k++) {
            dst1[j*dls+k] = dst1[j*dls+n];
            dst1[j*dls+in->w-k-1] = dst1[j*dls+in->w-n-1];
            dst2[j*dls+k] = dst2[j*dls+n];
            dst2[j*dls+in->w-k-1] = dst2[j*dls+in->w-n-1];
        }
    }
    return out;
}

static double firstdiff_y[3][3] = { { 0.0,  0.0,  0.0 }, 
                                    { 0.0,  1.0,  1.0 }, 
                                    { 0.0, -1.0, -1.0 } };
 
static double firstdiff_x[3][3] = { { 0.0,  0.0,  0.0 }, 
                                    { 0.0, -1.0,  1.0 }, 
                                    { 0.0, -1.0,  1.0 } };

TwoImages 
IPA__Local_gradients( PImage img)
{
   const char *method="IPA::Local::gradients";
   if ( !img || !kind_of(( Handle) img, CImage))
      croak("%s: not an image passed", method);
   if ( img-> type != imByte)
      croak("%s: image is not 8-bit grayscale", method);
   return gradients( method, img, (double*)firstdiff_y, (double*)firstdiff_x, 3);
}   

/* converts byte-coded angle into sector code */
static int 
angle2sector( Byte theta)
{    
    static Byte initialized = false;
    static Byte lut[256];

    if ( !initialized) {
       int i, v, sectornum; 
       for ( i = 0; i < 255; i++) {
          v = (int)((i - 128) / 80.0);
          /* Convert to positive angle */
          if ( v < 0) v += (int)(2.0 * PI);
          
          if (v < (PI / 8.0)  && 0 <= v) {
              sectornum = 0;
          } else if (v <= (2*PI)  && ((15.0*PI)/8.0) <= v) {
              sectornum = 0;
          } else if (v < ((3.0*PI)/8.0)  && (PI/8.0) <= v) {
              sectornum = 1;
          } else if (v < ((5.0*PI)/8.0)  && ((3.0*PI)/8.0) <= v) {
              sectornum = 2;
          } else if (v < ((7.0*PI)/8.0)  && ((5.0*PI)/8.0) <= v) {
              sectornum = 3;
          } else if (v < ((9.0*PI)/8.0)  && ((7.0*PI)/8.0) <= v) {
              sectornum = 0;
          } else if (v < ((11.0*PI)/8.0)  && ((9.0*PI)/8.0) <= v) {
              sectornum = 1;
          } else if (v < ((13.0*PI)/8.0)  && ((11.0*PI)/8.0) <= v) {
              sectornum = 2;
          } else {  /* if (v < ((15.0*PI)/8.0)  && ((13.0*PI)/8.0) <= v) */
              sectornum = 3;
          }
          lut[i] = sectornum;
       }
       initialized = true;
    }
    return lut[theta];
}

/* Canny edge detector  */
static PImage
canny( const char * method,
       PImage in, 
       int size,      /*  Size of gaussian smoothing filter.                   */
       double sigma /*  Std. deviation of gaussian smoothing filter.         */,
       Bool derivative
       )
{ 
   register int j, k;
   PImage g, smoothed, out;
   TwoImages FoG;
   Byte *mag, *dir, *dst;
   int ls, dls;

   /* create gaussian smoothing filter */
   g = gaussian( method, size, sigma, 0, 1, 1);
   out = create_compatible_image( in, false);
   dst = out-> data;
   dls = out-> lineSize;

   /* convolve with the gaussian */
   smoothed = convolution( method, in, g);
   smoothed-> self-> set_type(( Handle) smoothed, imByte);
   Object_destroy(( Handle) g);
   /* return smoothed */
   /* create the First Order Gaussian filtered image */
   FoG = gradients(method,smoothed,(double*)firstdiff_y, (double*)firstdiff_x, 3);
   Object_destroy(( Handle) smoothed);
   mag = PImage(FoG.magnitude)->data;
   dir = PImage(FoG.direction)->data;
   ls  = PImage(FoG.magnitude)->lineSize;

   if ( !derivative) mag = in-> data;
   
   /* perform gradient-based non-maxima supression */
   for (j=0; j<in->h; j++) {
       for (k=0; k<in->w; k++) {
           switch ( angle2sector(dir[j*ls+k])) {
           case 0:
               if (((k>0)&&(mag[j*ls+k-1] > mag[j*ls+k]))
                   || ((k<in->w-1)&&(mag[j*ls+k+1] > mag[j*ls+k]))) {
                       dst[j*dls+k] = 0;
               } else {
                   dst[j*dls+k] = mag[j*ls+k];
               }
               break;
           case 1: 
               if (((j>0 && k<in->w-1)&&(mag[ls*(j-1)+k+1] > mag[j*ls+k]))
                   || ((j<in->w-1 && k>0)&&(mag[ls*(j+1)+k-1] > mag[ls*j+k]))) {
                       dst[dls*j+k] = 0;
               } else {
                   dst[dls*j+k] = mag[dls*j+k];
               }
               break; 
           case 2:
               if (((j>0)&&(mag[ls*(j-1)+k] > mag[ls*j+k]))
                   || ((j<in->w-1)&&(mag[ls*(j+1)+k] > mag[ls*j+k]))) {
                       dst[j*dls+k] = 0;
               } else {
                   dst[j*dls+k] = mag[j*ls+k];
               }
               break;
           default:
               /*if (sectorval == 3)*/
               if (((j>0 && k>0)&&(mag[ls*(j-1)+k-1] > mag[ls*j+k]))
                   || ((j<in->w-1 && k<in->w-1)&&(mag[ls*(j+1)+k+1] > mag[ls*j+k]))) {
                       dst[j*dls+k] = 0;
               } else {
                   dst[j*dls+k] = mag[j*ls+k];
               }
           }
       }
   }
   return out;       
}


PImage IPA__Local_canny(PImage img,HV *profile)
{
    dPROFILE;
    const char *method="IPA::Local::canny";
    int size = 3;
    double sigma = 2;
    Bool ridge = 0;

    if ( !img || !kind_of(( Handle) img, CImage))
      croak("%s: not an image passed", method);

    if ( img-> type != imByte)
       croak("%s: image is not 8-bit grayscale", method);

    if (pexist(size)) size = pget_i( size);
    if (pexist(sigma)) sigma = pget_f( sigma);
    if (pexist(ridge)) ridge = pget_B(ridge);

    return canny(method,img,size,sigma,!ridge);
}

/* non-maxima suppression */
PImage IPA__Local_nms(PImage img,HV *profile)
{
    dPROFILE;
    double set   = 0xFF;
    double clear = 0;
    const char *method="IPA::Local::nms";
    PImage out;

    if ( !img || !kind_of(( Handle) img, CImage))
      croak("%s: not an image passed", method);

    if ( pexist(set))   set   = pget_f(set);
    if ( pexist(clear)) clear = pget_f(clear);
    out = create_compatible_image( img, true);
    PIX_SRC_DST( img, out, 
              (
                (y > 0 && (
                   (x > 0 && src[-src_ls-1] > *src) || (x < w - 1 && src[-src_ls+1] > *src) || (src[-src_ls] > *src)
                )) || 
                (y < h-1 && (
                   (x > 0 && src[src_ls-1] > *src) || (x < w - 1 && src[src_ls+1] > *src) || (src[src_ls] > *src)
                )) || 
                (x > 0 && src[-1] > *src) || (x < w - 1 && src[1] > *src)
              ) ? clear : set
    ); 
    return out;
}

static PImage
scale( const char * method,
       PImage in, 
       int size,      /*  Size of gaussian smoothing filter.                   */
       double t       /*  scale */
       )
{ 
   PImage g, smoothed;
   /* create gaussian smoothing filter */
   if ( t < 0) croak("%s: 't' must be positive", method);
   g = gaussian( method, size, sqrt(t), 0, 1, 1);
   /* normalize the gaussian */

   /* convolve with the gaussian */
   smoothed = convolution( method, in, g); 
   Object_destroy(( Handle) g);
   /* return smoothed */
   return smoothed;
}

PImage IPA__Local_scale(PImage img,HV *profile)
{
    dPROFILE;
    const char *method="IPA::Local::scale";
    int size = 3;
    double t = 4;

    if ( !img || !kind_of(( Handle) img, CImage))
      croak("%s: not an image passed", method);

    if ( img-> type != imByte)
       croak("%s: image is not 8-bit grayscale", method);

    if (pexist(size)) size = pget_i( size);
    if (pexist(t)) t = pget_f( t);

    return scale(method,img,size,t);
}

static PImage
d_rotate( PImage in, double alpha)
{
   int x, y, ls = in-> lineSize, ols = in-> lineSize / sizeof(double), nx, ny, sx, sy;
   double * src, * dst;
   Byte * bdst;
   PImage out = create_compatible_image(in,false);
   double sina = sin( alpha), cosa = cos( alpha);

   sx = in-> w/2;
   sy = in-> h/2;
   bdst = out-> data;
   dst = ( double*) bdst;
   src = (double*) in-> data;
   for ( y = 0; y < in-> h; y++, bdst += ls, dst = (double*) bdst) {
      for ( x = 0; x < in-> w; x++) {
         nx = (int)((x-sx) * cosa - (y-sy) * sina + sx);
         ny = (int)((x-sx) * sina + (y-sy) * cosa + sy);
         if ( nx >= 0 && nx < in-> w &&
              ny >= 0 && ny < in-> h)
             dst[x] = src[ny * ols + nx];
      }
   }
   return out;
}

static PImage
d_rotate90( PImage in)
{
   int x, y, max, ls = in-> lineSize, ols = in-> lineSize / sizeof(double);
   double * src, * dst;
   Byte * bdst;
   PImage out = create_compatible_image(in,false);

   max = ( in-> h < in-> w) ? in-> h : in-> w;
   bdst = out-> data;
   dst = ( double*) bdst;
   src = (double*) in-> data;
   for ( y = 0; y < max; y++, bdst += ls, dst = (double*) bdst) {
      for ( x = 0; x < max; x++) 
          dst[x] = src[y * ols + x];
   }
   return out;
}
                        
/* 
   Lindeberg ridge detector
   N= t^(4y)   (Lxx+Lyy)^2((Lxx-Lyy)^2 + 4Lxy^2). 
   A= t^(2y) ((Lxx-Lyy)^2 + 4Lxy^2). 
   Lindeberg 1994. 

   t ( scale ) and y ( gamma-normalizer ) 
   Don't know exactly, but suppose Lxy^2 == Lxy*Lyx 
 */
PImage IPA__Local_ridge(PImage img,HV *profile)
{
    dPROFILE;
    PImage xx, yy, xy, yx, lxx, lyy, lxy, lyx, l, tmp;
    Bool anorm = false;
    const char *method="IPA::Local::ridge";
    double mul = 1, scale = 2, gamma = 1;
    int ls, y, x, yls, size = 3, msize;
    double *xxd, *yyd, *xyd, *yxd, *res, texp;

    if ( !img || !kind_of(( Handle) img, CImage))
      croak("%s: not an image passed", method);

    if ( img-> type != imByte)
       croak("%s: image is not 8-bit grayscale", method);

    if ( pexist(a)) anorm = pget_B(a);
    if ( pexist(mul)) mul = pget_f(mul);
    if ( pexist(scale)) scale = pget_f(scale);
    if ( pexist(size)) 
       size = pget_i(size);
    else
       size = (int)sqrt(scale);
    if ( size < 3) size = 3;
    if (( size % 2) == 0) size++;
    if ( pexist(gamma)) gamma = pget_f(gamma);

    /* XXX gamma */
    texp = scale * scale;
    if ( !anorm) texp *= texp;

    /* prepare second derivative masks */
    msize = (int)(size * 1.5);
    if (( msize % 2) == 0) msize++;
    l = gaussian( method, msize, sqrt(scale), 1, 0, 1);
    tmp = d_rotate( l, PI/4);
    lxy = ( PImage) tmp-> self-> extract(( Handle) tmp, tmp-> w - size, tmp-> h - size, size, size);
    lxx = ( PImage) l-> self-> extract(( Handle) l, l-> w - size, l-> h - size, size, size);
    lyy = d_rotate90( lxx);
    Object_destroy(( Handle)tmp);
    Object_destroy(( Handle)l);
    /* normalize skewed sums = 0 */
    {
       double sum = lxy-> self-> get_stats(( Handle)lxy, isSum);
       if ( sum != 0) {
          double * s = ( double*)(lxy-> data),
                   sub = sum / (lxy->w * lxy-> h);
          int sz = lxy-> dataSize / sizeof(double);
          while ( sz--) {
             *s = *s - sub;
              s++;
          }
       }
    }
    lyx = d_rotate90( lxy);

    /* convolute the image with them */
    xx = convolution( method, img, lxx);
    Object_destroy(( Handle)lxx);
    yy = convolution( method, img, lyy);
    Object_destroy(( Handle)lyy);
    xy = convolution( method, img, lxy);
    Object_destroy(( Handle)lxy);
    yx = convolution( method, img, lyx);
    Object_destroy(( Handle)lyx);

    xxd = ( double*) xx-> data;
    yyd = ( double*) yy-> data;
    xyd = ( double*) xy-> data;
    yxd = ( double*) yx-> data;

    tmp = create_compatible_image( xx, false);
    res = ( double*) tmp-> data;
    for ( y = 0, ls = xx-> lineSize / sizeof(double), yls = 0; y < img-> h; y++, yls += ls) {
       for ( x = 0; x < xx-> w; x++) {
          double 
             Lxx = xxd[ yls + x],
             Lyy = yyd[ yls + x],
             Lxy = xyd[ yls + x],
             Lyx = yxd[ yls + x];
          double A = mul * ((Lxx - Lyy) * (Lxx - Lyy) + 4 * Lxy * Lyx);
          if ( !anorm) A = ( A * ( Lxx + Lyy) * ( Lxx + Lyy));
          res[ yls + x] = A;
       }
    }
    Object_destroy(( Handle)xx);
    Object_destroy(( Handle)yy);
    Object_destroy(( Handle)xy);
    Object_destroy(( Handle)yx);
    return tmp;
}

PImage 
IPA__Local_zerocross(PImage img,HV *profile)
{
    dPROFILE;
    const char *method="IPA::Local::zerocross";
    double cmp = 0;
    int p, n;
    PImage out;
    dPIX_ARGS;

    if ( !img || !kind_of(( Handle) img, CImage))
       croak("%s: not an image passed", method);
    if ( pexist(cmp)) cmp = pget_f(cmp);
    out = create_compatible_image( img, false);

    PIX_INITARGS(img,out);
    h--; w--;
    PIX_SWITCH
    PIX_BODY(( *src == cmp) ? 0xff : 
             (
                p = n = 0,
                p += ( src[0] > cmp) ? 1 : 0,
                n += ( src[0] < cmp) ? 1 : 0,
                p += ( src[1] > cmp) ? 1 : 0,
                n += ( src[1] < cmp) ? 1 : 0,
                p += ( src[src_ls] > cmp) ? 1 : 0,
                n += ( src[src_ls] < cmp) ? 1 : 0,
                p += ( src[src_ls + 1] > cmp) ? 1 : 0,
                n += ( src[src_ls + 1] < cmp) ? 1 : 0,
                ( n && p) ? 0xff : 0
             )
    );
    PIX_END_SWITCH;
    return out;
}
