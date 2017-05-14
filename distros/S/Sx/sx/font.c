/*  This file contains routines that manipulate fonts.
 *
 *                     This code is under the GNU Copyleft.
 *
 *  Dominic Giampaolo
 *  dbg@sgi.com
 */
#include <stdio.h>
#include <stdlib.h>
#include "xstuff.h"
#include "libsx.h"
#include "libsx_private.h"




XFont  GetFont(fontname)
char *fontname;
{
  XFontStruct *xfs;

  if (lsx_curwin->display == NULL || fontname == NULL)
    return NULL;

  xfs = XLoadQueryFont(lsx_curwin->display, fontname);

  return xfs;
}



void  SetWidgetFont(w, f)
Widget w;
XFont f;
{
  int    n = 0;
  Arg    wargs[1];		/* Used to set widget resources */
  DrawInfo *di;

  if (lsx_curwin->toplevel == NULL || w == NULL || f == NULL)
    return;

  if ((di=libsx_find_draw_info(w)) != NULL)
   {
     XSetFont(lsx_curwin->display, di->drawgc, f->fid);
     di->font = f;
     return;
   }

  n = 0;
  XtSetArg(wargs[n], XtNfont, f);	 	     n++;  
  XtSetValues(w, wargs, n);

  return;
}



XFont  GetWidgetFont(w)
Widget w;
{
  int    n = 0;
  Arg    wargs[1];		/* Used to set widget resources */
  XFont  f=NULL;
  DrawInfo *di;

  if (lsx_curwin->toplevel == NULL || w == NULL)
    return NULL;


  if ((di=libsx_find_draw_info(w)) != NULL)
   {
     return di->font;
   }

  n = 0;
  XtSetArg(wargs[n], XtNfont, &f);	 	     n++;  
  XtGetValues(w, wargs, n);

  return f;
}



void FreeFont(f)
XFont f;
{
  if (lsx_curwin->display && f)
    XFreeFont(lsx_curwin->display, f);
}



int FontHeight(f)
XFont f;
{
  if (f)
    return (f->ascent+f->descent);
  else
    return -1;
}



int TextWidth(f, txt)
XFont f;
char *txt;
{
  if (f && txt)
    return XTextWidth(f, txt, strlen(txt));
  else
    return -1;
}

