#include "EXTERN.h"
#include "perl.h"
#include "libsx.h"

#include "libsx_private.h"
#include <X11/StringDefs.h>
#ifdef XAW3D
#include <X11/Xaw3d/AsciiText.h>
#include <X11/Xaw3d/AsciiSrc.h>
#else
#include <X11/Xaw/AsciiText.h>
#include <X11/Xaw/AsciiSrc.h>
#endif

extern WindowState *lsx_curwin;   /* global handle to the current window */

AddTrans(w, text)
Widget w;
char *text;
{
  XtTranslations table;
  char * buf[2];
  buf[0] = text; buf[1] = NULL;
  table = XtParseTranslationTable(text);
  XtOverrideTranslations(w,table);
}


#define MAXARGS 5

struct Edata
{
    Widget w;
    SV *data;
    SV *mysv;
    char *fun[MAXARGS];
    CV *cvcache[MAXARGS];
#define CB_GENFUN 0
#define CB_BU_IDX 1
#define CB_BUTT_1 1
#define CB_BD_IDX 2
#define CB_BUTT_2 2
#define CB_KP_IDX 3
#define CB_BUTT_3 3
#define CB_MM_IDX 4
};

void test_trback(w, xev, parms,num_parms) 
Widget w;
union _XEvent *xev;
String *parms;
Cardinal *num_parms;
{
  struct Edata *tmp; SV *sv;
  int n; 
  register CV *cv;
  GV *gv = Nullgv;
  GV *gvjunk;
  HV *hvjunk;
  dSP;


  /* find the corresponding SX widget */

  

  Newz(666,tmp,1,struct Edata);
  PUSHMARK(sp);
  tmp->w = w;
  sv = sv_newmortal();
  sv_setptrobj(sv, tmp, "SxWidget");
  XPUSHs(sv);
  XPUSHs(sv_2mortal(newSVpv((char *)xev,sizeof(union _XEvent))));

  for (n = 1; n < *num_parms; n++) 
    XPUSHs(sv_2mortal(newSVpv(parms[n],strlen(parms[n]))));
  PUTBACK;
  gv = gv_fetchpv(*parms, FALSE,SVt_PVCV);

  /* If we haven't found anything, give up */
  if (gv == Nullgv)
    croak("method %s not found for translation callback",*parms);

  if (!(cv = sv_2cv(gv, &hvjunk, &gvjunk, FALSE)))
    croak("sv_2cv failed on method");
  perl_call_sv((SV*)cv, G_SCALAR);
  Safefree(tmp);
}

SetWidgetInt(w, resource, value)
Widget w;
char *resource;
int value;
{
  Arg    wargs[1];		/* Used to set widget resources */

  if (lsx_curwin->toplevel == NULL || w == NULL)
    return;

  XtSetArg(wargs[0], resource, value);
  XtSetValues(w, wargs, 1);
}

SetWidgetDat(w, resource, value)
Widget w;
char *resource;
void *value;
{
  Arg    wargs[1];		/* Used to set widget resources */

  if (lsx_curwin->toplevel == NULL || w == NULL)
    return;

  XtSetArg(wargs[0], resource, value);
  XtSetValues(w, wargs, 1);
}

GetWidgetInt(w, resource)
Widget w;
char *resource;
{
  int value;
  Arg    wargs[2];		/* Used to set widget resources */

  if (lsx_curwin->toplevel == NULL || w == NULL)
    return -1;

  XtSetArg(wargs[0], resource, &value);
  XtGetValues(w, wargs, 1);
  return value;
}

char *GetWidgetDat(w, resource)
Widget w;
char *resource;
{
  char *value;
  Arg    wargs[2];		/* Used to set widget resources */

  if (lsx_curwin->toplevel == NULL || w == NULL)
    return "";

  XtSetArg(wargs[0], resource, &value);
  XtGetValues(w, wargs, 1);
  return value;
}

AppendText(w, text)
Widget w; 
char *text;
{
    Widget          Source;
    XawTextPosition Pos1, Pos2;
    XawTextBlock    block;
    XawTextEditType type;

    XtVaGetValues(w,
                  XtNeditType,       (XtArgVal) &type,
                  XtNtextSource,     (XtArgVal) &Source,
                  XtNinsertPosition, (XtArgVal) &Pos2,
                  NULL);
    XtVaSetValues(w, XtNeditType, (XtArgVal) XawtextEdit, NULL);

    Pos1 = XawTextSourceScan(Source, 0, XawstAll, XawsdRight, 1, True);
    block.firstPos = 0;
    block.length   = strlen(text);
    block.ptr      = text;
/*
    block.format   = FMT8BIT;
*/
    if (XawEditDone == XawTextReplace(w, Pos1, Pos1, &block) && 
        Pos2 >= Pos1) Pos2 = Pos1+block.length;

    XtVaSetValues(w,
                  XtNeditType,       (XtArgVal) type,
                  XtNinsertPosition, (XtArgVal) Pos2,
                  NULL);
}

  
InsertText(w, text)
Widget w;
char *text;
{
    XawTextPosition Pos;
    XawTextBlock    block;
    XawTextEditType type;

    XtVaGetValues(w,
                  XtNeditType,       (XtArgVal) &type,
                  XtNinsertPosition, (XtArgVal) &Pos,
                  NULL);
    XtVaSetValues(w, XtNeditType, (XtArgVal) XawtextEdit, NULL);

    block.firstPos = 0;
    block.length   = strlen(text);
    block.ptr      = text;
/*
    block.format   = FMT8BIT;
*/
    if (XawEditDone == XawTextReplace(w, Pos, Pos, &block))
      Pos += block.length;

    XtVaSetValues(w,
                  XtNeditType,       (XtArgVal) type,
                  XtNinsertPosition, (XtArgVal) Pos,
                  NULL);
}

ReplaceText(w, start, end, text)
Widget w;
XawTextPosition start, end;
char *text;
{
    XawTextBlock    block;
    XawTextEditType type;
    int ret;

    XtVaGetValues(w,
                  XtNeditType,       (XtArgVal) &type,
                  NULL);
    XtVaSetValues(w, XtNeditType, (XtArgVal) XawtextEdit, NULL);

    block.firstPos = 0;
    block.length   = strlen(text);
    block.ptr      = text;
/*
    block.format   = FMT8BIT;
*/
    ret = XawTextReplace(w, start, end, &block);

    XtVaSetValues(w,
                  XtNeditType,       (XtArgVal) type,
                  NULL);
    return ret;
}
