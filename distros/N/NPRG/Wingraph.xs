/*
 $Id: Wingraph.xs 1.22 1999/01/24 16:53:19 frolcov Exp frolcov $
*/
#include <windows.h>
#include <winspool.h>
#include <string.h>

COLORREF rgbthunk(int r,int g, int b) {return RGB(r,g,b);}

#ifdef __cplusplus
extern "C" {
#endif
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#ifdef __cplusplus
}
#endif

char* GetMessageText(void){
     static char msg[2000];

     FormatMessage(FORMAT_MESSAGE_FROM_SYSTEM,
              NULL,
              GetLastError(),
              0,
              msg,
              2000, NULL);
    return msg;
}


MODULE = Win32::Wingraph         PACKAGE = Win32::Wingraph

PROTOTYPES: DISABLE

HDC
xsCreateEnhMetaFile(hdcref,fn,x1,y1,x2,y2,desc)
        HDC hdcref
        char *fn
        int x1
        int y1
        int x2
        int y2
        char *desc
       CODE:
         RECT rc;
         HDC hdc;
         rc.left=x1;
         rc.top=y1;
         rc.right=x2;
         rc.bottom=y2;
         
         hdc=CreateEnhMetaFile(hdcref,fn,&rc,desc);
         if(hdc==NULL){
            char str[1000];
            sprintf(str,"Cannot create metafile!");
            croak(str);
         }
         RETVAL = hdc;
       OUTPUT:
         RETVAL

HENHMETAFILE
xsCloseEnhMetaFile(hdc)
       HDC hdc;
       CODE:
        HENHMETAFILE hm;
        hm=CloseEnhMetaFile(hdc);
        if(hm==NULL){
            croak("Cannot close metafile!");
         }
        RETVAL=hm;
       OUTPUT:
        RETVAL

BOOL
xsDeleteEnhMetaFile(hdc)
       HDC hdc
       CODE:
        RETVAL=DeleteEnhMetaFile(hdc);
        if(! RETVAL ){
            croak("Cannot delete metafile!");
         }
       OUTPUT:
        RETVAL
        
void 
xsMoveTo(hdc,x,y)
        HDC hdc;
        int x;
        int y;
       CODE:
         if(!MoveToEx(hdc,x,y,NULL)){  
            croak("Cannot movetoex!");
         }

void 
xsLineTo(hdc,x,y)
        HDC hdc;
        int x;
        int y;
       CODE:
         if(!LineTo(hdc,x,y)){
            croak("Cannot LineTo!");
         }

HFONT
xsCreateFont(nHeight,nWidth,nEscapement,nOrientation,fnWeight,fdwItalic,fdwUnderline,fdwStrikeOut,fdwCharset,fdwOutputPrecision,fdwClipPrecision,fdwQuality,fdwPitchAndFamily,Face)
     int nHeight;
     int nWidth;
     int nEscapement;
     int nOrientation;
     int fnWeight;
     long fdwItalic;
     long fdwUnderline;
     long fdwStrikeOut;
     long fdwCharset;
     long fdwOutputPrecision;
     long fdwClipPrecision;
     long fdwQuality;
     long fdwPitchAndFamily;
     char *Face;
   CODE:
    RETVAL=CreateFont(nHeight,nWidth,nEscapement,nOrientation,fnWeight,fdwItalic,fdwUnderline,fdwStrikeOut,fdwCharset,fdwOutputPrecision,fdwClipPrecision,fdwQuality,fdwPitchAndFamily,Face);

     if(RETVAL==NULL){
            char str[1000];
            sprintf(str,"Cannot create font, error: %s", GetMessageText() );
            croak(str);
     }

   OUTPUT:
    RETVAL

HGDIOBJ 
xsSelectObject(dc,ho)
       HDC dc;
       HGDIOBJ ho;
     CODE:
       RETVAL=SelectObject(dc,ho);
       if(RETVAL==NULL){
           croak("Cannot select object!");
       }
     OUTPUT:
       RETVAL

int 
xsDeleteObject(obj)
       HGDIOBJ obj;
     CODE:
       RETVAL=DeleteObject(obj);
       if(RETVAL==NULL){
           croak("Cannot delete object!");
       }
     OUTPUT:
       RETVAL

void 
xsTextOut(dc,x,y,s)
      HDC dc;
      int x;
      int y;
      char *s;
    CODE:
      if(!TextOut(dc,x,y,s,strlen(s))){
            char str[1000];
            sprintf(str,"Cannot textout, error: %s", GetMessageText() );
            croak(str);
      }

void 
xsSetBkMode(dc,mode)
      HDC dc;
      int mode;
     CODE:
      SetBkMode(dc,mode);

HDC
xsCreateDC(drv,dev)
      char *drv;
      char *dev;
    CODE:
      RETVAL=CreateDC(drv,dev,NULL,NULL);
    OUTPUT:
      RETVAL

int
xsDeleteDC(dc)
      HDC dc
    CODE:
     RETVAL=DeleteDC(dc);
    OUTPUT:
     RETVAL

int
xsGetDeviceCaps(dc,index)
        HDC dc;
        int index;
      CODE:
       RETVAL=GetDeviceCaps(dc,index);
      OUTPUT:
       RETVAL

int
xsStartDoc(dc,DocName)
       HDC dc;
       char *DocName;
      CODE:
        DOCINFO di;
        di.cbSize=sizeof(di);
        di.lpszDocName=DocName;
        di.lpszOutput=NULL;
        di.lpszDatatype=NULL;
        di.fwType=0;
        RETVAL=StartDoc(dc,&di);
      OUTPUT:
        RETVAL

int
xsEndDoc(dc)
      HDC dc;
     CODE:
      RETVAL=EndDoc(dc);
     OUTPUT:
      RETVAL

int 
xsStartPage(dc)
      HDC dc;
     CODE:
      RETVAL=StartPage(dc);
     OUTPUT:
      RETVAL

int
xsEndPage(dc)
      HDC dc;
     CODE:
      RETVAL=EndPage(dc);
      if(RETVAL<=0){
            char str[1000];
            sprintf(str,"Cannot do end of page, error: %s", GetMessageText() );
            croak(str);
         }
     OUTPUT:
      RETVAL

HPEN 
xsCreatePen(style,w,clr)
     int style;
     int w;
     COLORREF clr;
    CODE:
     RETVAL=CreatePen(style,w,clr);
    OUTPUT:
     RETVAL

HBRUSH 
xsCreateSolidBrush(clr)
    COLORREF clr;
  CODE:
   RETVAL=CreateSolidBrush(clr);
  OUTPUT:
   RETVAL

HBRUSH
xsCreateHatchBrush(style,clr)
     int style;
     COLORREF clr;
   CODE:
     RETVAL=CreateHatchBrush(style,clr);
   OUTPUT:
     RETVAL


HGDIOBJ
xsGetStockObject(index)
    int index;
   CODE:
    RETVAL=GetStockObject(index);
   OUTPUT:
    RETVAL

int 
xsFillRect(dc,x1,y1,x2,y2,br)
    HDC dc;
    int x1;
    int y1;
    int x2;
    int y2;
    HBRUSH br;
  CODE:
         RECT rc;
         HDC hdc;
         rc.left=x1;
         rc.top=y1;
         rc.right=x2;
         rc.bottom=y2;
         RETVAL=FillRect(dc,&rc,br);
   OUTPUT:
     RETVAL

int 
xsGetTextExtentPoint32(dc,s,cx,cy)
         HDC dc;
         char *s;
         int cx;
         int cy;
      CODE:
       SIZE sz;
       int rv;
       rv=GetTextExtentPoint32(dc,s,strlen(s),&sz);
       RETVAL=rv;
       if(rv){
          cx=sz.cx;
          cy=sz.cy;
       }
     OUTPUT:
       cx
       cy
       RETVAL

int
xsGetTextExtent(dc,s)
    HDC dc;
    char *s;
  PREINIT:
   SIZE sz;
   int rv;
   long x,y;
  PPCODE:
   rv=GetTextExtentPoint32(dc,s,strlen(s),&sz);
   EXTEND(sp,2);
   PUSHs(sv_2mortal(newSViv(sz.cx)));
   PUSHs(sv_2mortal(newSViv(sz.cy)));

COLORREF
xsRGB(r,g,b)
     int r;
     int g;
     int b;
    CODE:
      long rgb;
      rgb =rgbthunk(r,g,b);
      RETVAL=rgb;
    OUTPUT:
      RETVAL

void
xsClipBSize(dc,x,y)
      HDC dc;
      int x;
      int y;
     CODE:
       RECT rc;
       GetClipBox(dc,&rc);
       x=rc.right-rc.left;
       y=rc.bottom-rc.top;
     OUTPUT:
       x
       y

int
PointToSize(dc,PointSize)
          HDC dc;
          int PointSize;
       CODE:
          RETVAL = -MulDiv(PointSize, GetDeviceCaps(dc, LOGPIXELSY), 72);
       OUTPUT:
          RETVAL

HBRUSH
xsGetCurrentBrush(dc)
          HDC dc;
        CODE:
          RETVAL=GetCurrentObject(dc,OBJ_BRUSH);
        OUTPUT:
          RETVAL

HDC
xsSetDocumetProperties(device, orient, papersize)
          char *device;
          int orient;
          int papersize;
        PREINIT:
         DEVMODE *dm;
         int dmsize;
         HANDLE printer;

        CODE:
         if(!OpenPrinter(device, &printer, NULL)){
            char str[1000];
            sprintf(str,"Cannot open printer: %s, error: %s", device, GetMessageText() );
            croak(str);
         }
         dmsize=DocumentProperties(0,printer,device,0,0,0);
         if (dmsize<0){
            char str[1000];
            sprintf(str,"Cannot get DocumentProperties size: %d", dmsize);
            croak(str);
         }
         dm=(struct _devicemodeA *)malloc(dmsize);
         if(!dm){
            char str[1000];
            sprintf(str,"Cannot allocate enought memory (%d bytes )for DEVMODE structure!", dmsize);
            croak(str);
         }
         DocumentProperties(0,0,device,dm,0,DM_OUT_BUFFER);

         dm->dmFields|=DM_PAPERSIZE|DM_ORIENTATION;
         dm->dmOrientation=orient;
         dm->dmPaperSize=papersize;

         DocumentProperties(0,0,device,dm,dm, DM_IN_BUFFER|DM_OUT_BUFFER);

         RETVAL=CreateDC("WINSPOOL", device, NULL, dm);
         ClosePrinter(printer);
         free(dm);
        OUTPUT:
         RETVAL

BOOL
xsArc(hdc,nLeftRect,nTopRect,nRightRect,nBottomRect,nXRadial1,nYRadial1,nXRadial2,nYRadial2)
    HDC hdc        ;          
    int nLeftRect  ;   
    int nTopRect   ;   
    int nRightRect ;   
    int nBottomRect;   
    int nXRadial1  ;   
    int nYRadial1  ;   
    int nXRadial2  ;   
    int nYRadial2  ;   
  CODE:
    RETVAL=Arc(hdc,nLeftRect,nTopRect,nRightRect,nBottomRect,nXRadial1,nYRadial1,nXRadial2,nYRadial2);
  OUTPUT:
    RETVAL

BOOL
xsEllipse(hdc,nLeftRect,nTopRect,nRightRect,nBottomRect)
    HDC hdc         ;   
    int nLeftRect   ;   
    int nTopRect    ;   
    int nRightRect  ;    
    int nBottomRect ;   
 CODE:
   RETVAL=Ellipse(hdc,nLeftRect,nTopRect,nRightRect,nBottomRect);
 OUTPUT:
   RETVAL

int
xsSetArcDirection(hdc,dir)
    HDC hdc;
    int dir;
  CODE:
    RETVAL=SetArcDirection(hdc,dir);
  OUTPUT:
    RETVAL

int
xsPolyBezier(hdc,...)
     HDC hdc;
   PREINIT:
     POINT *pp;
     int i,j;
   CODE:
     if(items<8){
            char str[1000];
            sprintf(str,"Must be at least eight values, having only:%d",items);
            croak(str);
     }

     pp=(POINT*)calloc(items,sizeof(POINT));
     i=1;j=0;

     while(i<items){
       pp[j].x=SvIV(ST(i));
       i++;
       pp[j].y=SvIV(ST(i));
       i++;j++;
     }
     RETVAL=PolyBezier(hdc,pp,(items-1)/2);
     free(pp);
    OUTPUT:
     RETVAL


