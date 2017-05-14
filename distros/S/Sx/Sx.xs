#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "libsx.h"
#include "libsx_private.h"
#include <X11/IntrinsicP.h>
#include <X11/StringDefs.h>
#ifdef XAW3D
#include <X11/Xaw3d/AsciiText.h>
#include <X11/Xaw3d/AsciiSrc.h>
#else
#include <X11/Xaw/AsciiText.h>
#include <X11/Xaw/AsciiSrc.h>
#endif

typedef char **String_Array;
typedef short *RGB_Array;
typedef unsigned char *Byte_Array;

char *		_XawTextGetText();

char *		GetWidgetDat();
Widget		Make3Com(), MakeThreeList();
String_Array	XS_unpack_String_Array();
XPoint *	XS_unpack_XPointPtr();

#define MAXARGS 5

struct Edata
{
    Widget w;
    SV *data;
    SV *mysv;
    CV *fun[MAXARGS];
#define CB_GENFUN 0
#define CB_BU_IDX 1
#define CB_BD_IDX 2
#define CB_KP_IDX 3
#define CB_MM_IDX 4

#define CB_BUTT_1 1
#define CB_BUTT_2 2
#define CB_BUTT_3 3

#define CB_RESFUN 0
#define CB_REAFUN 1
#define CB_EXPFUN 2
};

typedef struct Edata *Rwidget;

String_Array XS_unpack_String_Array(ax, items)
int ax;
int items;
{
    char **argv;
    int i;
    
    New(666, argv, items+1, char *);
    for (i = 0; i < items; i++)
      argv[i] = SvPV(ST(i), na);
    argv[i] = NULL;
    return argv;
}

char *NewString(s)
char *s; {
  char *tmp;

  New(666,tmp,strlen(s)+1,char);
  strcpy(tmp,s);
  return tmp;
}

CV *NewCallback(cb)
SV *cb; {
  register CV *cv;
  GV *gv = Nullgv;
  GV *gvjunk;
  HV *hvjunk;

  if (!SvROK(cb)) {		/* Soft ref to the callback name */
    char *cname = SvPV(cb,na);
    if (*cname) {
      gv = gv_fetchpv(cname, FALSE,SVt_PVCV);
      /* If we haven't found anything, give up */
      if (gv == Nullgv)
	croak("method %s not found for callback",cname);
      if (!(cv = sv_2cv((SV *)gv, &hvjunk, &gvjunk, FALSE)))
	croak("sv_2cv failed on method %s",cname);
    } else {
      cv = NULL;
    }
  } else {			/* Hard ref to the real sub. */
    cv = (CV*)SvRV(cb);
  }
  SvREFCNT_inc((SV*)cv);
  return cv;
}

void button_callback(w, data)
Widget w;
void *data; 
{
  struct Edata *dd = data;
  dSP;

  if (dd->fun[CB_GENFUN]) {
    PUSHMARK(sp);
    SvREFCNT_inc(dd->mysv);
    XPUSHs(dd->mysv);
    XPUSHs(sv_mortalcopy(dd->data));
    PUTBACK;
    perl_call_sv((SV*)dd->fun[CB_GENFUN],G_SCALAR|G_DISCARD);
  }
}

void but1_callback(w, data)
Widget w;
void *data; 
{
  struct Edata *dd = data;
  dSP;

  if (dd->fun[CB_BUTT_1]) {
    PUSHMARK(sp);
    SvREFCNT_inc(dd->mysv);
    XPUSHs(dd->mysv);
    XPUSHs(sv_mortalcopy(dd->data));
    PUTBACK;
    perl_call_sv((SV*)dd->fun[CB_BUTT_1],G_SCALAR|G_DISCARD);
  }
}

void but2_callback(w, data)
Widget w;
void *data; 
{
  struct Edata *dd = data;
  dSP;

  if (dd->fun[CB_BUTT_2]) {
    PUSHMARK(sp);
    SvREFCNT_inc(dd->mysv);
    XPUSHs(dd->mysv);
    XPUSHs(sv_mortalcopy(dd->data));
    PUTBACK;
    perl_call_sv((SV*)dd->fun[CB_BUTT_2],G_SCALAR|G_DISCARD);
  }
}

void but3_callback(w, data)
Widget w;
void *data; 
{
  struct Edata *dd = data;
  dSP;

  if (dd->fun[CB_BUTT_3]) {
    PUSHMARK(sp);
    SvREFCNT_inc(dd->mysv);
    XPUSHs(dd->mysv);
    XPUSHs(sv_mortalcopy(dd->data));
    PUTBACK;
    perl_call_sv((SV*)dd->fun[CB_BUTT_3],G_SCALAR|G_DISCARD);
  }
}

void string_callback(w, string, data)
Widget w;
char *string;
void *data; 
{
  struct Edata *dd = data;
  dSP;

  if (dd->fun[CB_GENFUN]) {
    PUSHMARK(sp);
    XPUSHs(SvREFCNT_inc(dd->mysv));
    XPUSHs(sv_2mortal(newSVpv(string,strlen(string))));
    XPUSHs(sv_mortalcopy(dd->data));
    PUTBACK;
    perl_call_sv((SV*)dd->fun[CB_GENFUN],G_SCALAR|G_DISCARD);
  }
}

void scroll_callback(w, new_val, data)
Widget w;
float new_val;
void *data; 
{
  struct Edata *dd = data;
  dSP;

  dd->fun[0]; new_val;
  if (dd->fun[CB_GENFUN]) {
    PUSHMARK(sp);
    XPUSHs(SvREFCNT_inc(dd->mysv));
    XPUSHs(sv_2mortal(newSVnv((double)new_val)));
    XPUSHs(sv_mortalcopy(dd->data));
    PUTBACK;
    perl_call_sv((SV*)dd->fun[CB_GENFUN],G_SCALAR|G_DISCARD);
  }
}

void list_callback(w, string, index, data)
Widget w;
char *string;
int index;
void *data; 
{
  struct Edata *dd = data;
  dSP;

  if (dd->fun[CB_GENFUN]) {
    PUSHMARK(sp);
    XPUSHs(SvREFCNT_inc(dd->mysv));
    XPUSHs(sv_2mortal(newSVpv(string,strlen(string))));
    XPUSHs(sv_2mortal(newSViv(index)));
    XPUSHs(sv_mortalcopy(dd->data));
    PUTBACK;
    perl_call_sv((SV*)dd->fun[CB_GENFUN],G_SCALAR|G_DISCARD);
  }
}

void threelist_callback(w, string, index, event_mask, data)
Widget w;
char *string;
int index;
unsigned int event_mask;
void *data; 
{
  struct Edata *dd = data;
  dSP;

  if (dd->fun[CB_GENFUN]) {
    PUSHMARK(sp);
    XPUSHs(SvREFCNT_inc(dd->mysv));
    XPUSHs(sv_2mortal(newSVpv(string,strlen(string))));
    XPUSHs(sv_2mortal(newSViv(index)));
    XPUSHs(sv_2mortal(newSViv(event_mask)));
    XPUSHs(sv_mortalcopy(dd->data));
    PUTBACK;
    perl_call_sv((SV*)dd->fun[CB_GENFUN],G_SCALAR|G_DISCARD);
  }
}

void general_callback(data)
void *data; 
{
  struct Edata *dd = data;
  dSP;

  if (dd->fun[CB_GENFUN]) {
    PUSHMARK(sp);
    XPUSHs(sv_mortalcopy(dd->data));
    PUTBACK;
    perl_call_sv((SV*)dd->fun[CB_GENFUN],G_SCALAR|G_DISCARD);
  }
  Safefree(dd);  /* Timeout callback are called only once */
}

void io_callback(data, fd)
void *data;
int *fd; 
{
  struct Edata *dd = data;
  dSP;

  if (dd->fun[CB_GENFUN]) {
    PUSHMARK(sp);
    XPUSHs(sv_2mortal(newSViv(*fd)));
    XPUSHs(sv_mortalcopy(dd->data));
    PUTBACK;
    perl_call_sv((SV*)dd->fun[CB_GENFUN],G_SCALAR|G_DISCARD);
  }
}

void redisplay_callback(w, new_width, new_height, data)
Widget w;
int new_width, new_height;
void *data; 
{
  struct Edata *dd = data;
  dSP;

  if (dd->fun[CB_GENFUN]) {
    PUSHMARK(sp);
    XPUSHs(SvREFCNT_inc(dd->mysv));
    XPUSHs(sv_2mortal(newSViv(new_width)));
    XPUSHs(sv_2mortal(newSViv(new_height)));
    XPUSHs(sv_mortalcopy(dd->data));
    PUTBACK;
    perl_call_sv((SV*)dd->fun[CB_GENFUN],G_SCALAR|G_DISCARD);
  }
}

void button_down_callback(w, button, x, y, data)
Widget w;
int button, x, y;
void *data; 
{
  struct Edata *dd = data;
  dSP;

  if (dd->fun[CB_BD_IDX]) {
    PUSHMARK(sp);
    XPUSHs(SvREFCNT_inc(dd->mysv));
    XPUSHs(sv_2mortal(newSViv(button)));
    XPUSHs(sv_2mortal(newSViv(x)));
    XPUSHs(sv_2mortal(newSViv(y)));
    XPUSHs(sv_mortalcopy(dd->data));
    PUTBACK;
    perl_call_sv((SV*)dd->fun[CB_BD_IDX],G_SCALAR|G_DISCARD);
  }
}

void button_up_callback(w, button, x, y, data)
Widget w;
int button, x, y;
void *data; 
{
  struct Edata *dd = data;
  dSP;

  if (dd->fun[CB_BU_IDX]) {
    PUSHMARK(sp);
    XPUSHs(SvREFCNT_inc(dd->mysv));
    XPUSHs(sv_2mortal(newSViv(button)));
    XPUSHs(sv_2mortal(newSViv(x)));
    XPUSHs(sv_2mortal(newSViv(y)));
    XPUSHs(sv_mortalcopy(dd->data));
    PUTBACK;
    perl_call_sv((SV*)dd->fun[CB_BU_IDX],G_SCALAR|G_DISCARD);
  }
}

void keypress_callback(w, input, up_or_down, data)
Widget w;
char *input;
int up_or_down;
void *data; 
{
  struct Edata *dd = data;
  dSP;

  if (dd->fun[CB_KP_IDX]) {
    PUSHMARK(sp);
    XPUSHs(SvREFCNT_inc(dd->mysv));
    XPUSHs(sv_2mortal(newSVpv(input,strlen(input))));
    XPUSHs(sv_2mortal(newSViv(up_or_down)));
    XPUSHs(sv_mortalcopy(dd->data));
    PUTBACK;
    perl_call_sv((SV*)dd->fun[CB_KP_IDX],G_SCALAR|G_DISCARD);
  }
}

void motion_callback(w, x, y, data)
Widget w;
int x, y;
void *data; 
{
  struct Edata *dd = data;
  dSP;

  if (dd->fun[CB_MM_IDX]) {
    PUSHMARK(sp);
    XPUSHs(SvREFCNT_inc(dd->mysv));
    XPUSHs(sv_2mortal(newSViv(x)));
    XPUSHs(sv_2mortal(newSViv(y)));
    XPUSHs(sv_mortalcopy(dd->data));
    PUTBACK;
    perl_call_sv((SV*)dd->fun[CB_MM_IDX],G_SCALAR|G_DISCARD);
  }
}

void expose_callback(w, event, region, data)
Widget w;
XExposeEvent *event;
Region region;
void *data; 
{
  struct Edata *dd = data;
  dSP;

  printf("Expose CB call (%x %x %x %x)\n",w, event, region, data);
  return;
  if (dd->fun[CB_EXPFUN]) {
    PUSHMARK(sp);
    XPUSHs(SvREFCNT_inc(dd->mysv));
    XPUSHs(sv_mortalcopy(dd->data));
    PUTBACK;
    perl_call_sv((SV*)dd->fun[CB_EXPFUN],G_SCALAR|G_DISCARD);
  }
}

void resize_callback(w, data)
Widget w;
void *data; 
{
  struct Edata *dd = data;
  dSP;

  printf("Resize CB call (%x %x)\n",w, data);
  return;
  if (dd->fun[CB_RESFUN]) {
    PUSHMARK(sp);
    XPUSHs(SvREFCNT_inc(dd->mysv));
    XPUSHs(sv_mortalcopy(dd->data));
    PUTBACK;
    perl_call_sv((SV*)dd->fun[CB_RESFUN],G_SCALAR|G_DISCARD);
  }
}

void realize_callback(w, data)
Widget w;
void *data; 
{
  struct Edata *dd = data;
  dSP;

  printf("Realize CB call (%x %x)\n",w, data);
  return;
  if (dd->fun[CB_REAFUN]) {
    PUSHMARK(sp);
    XPUSHs(SvREFCNT_inc(dd->mysv));
    XPUSHs(sv_mortalcopy(dd->data));
    PUTBACK;
    perl_call_sv((SV*)dd->fun[CB_REAFUN],G_SCALAR|G_DISCARD);
  }
}



struct Edata	*tmp;

MODULE = Sx	PACKAGE = Sx	PREFIX = Sx_

PROTOTYPES: ENABLED


void
OpenDisplay(args,...)
	String_Array	args = NO_INIT
	PROTOTYPE:	@
	PPCODE: 
	{
	    int i;
	    args = XS_unpack_String_Array(ax,items);
	    if (!items) {
	      *args = "Main Sx Window"; items = 1;
	    }
	    if (i = OpenDisplay(items,args)) {
		int j;
		for (j = 0; j != i; j++) 
		    PUSHs(sv_2mortal(newSVpv(args[j],strlen(args[j]))));
	    }
	}

void
ShowDisplay()

void
MainLoop()

void
SyncDisplay()

Widget
MakeWindow(window_name, display_name, exclusive)
	char *		window_name
	char *		display_name = NO_INIT
	int		exclusive
	CODE:

	Newz(666, tmp , 1, struct Edata);
	display_name = ((ST(1) == &sv_undef) ? SAME_DISPLAY : SvPV(ST(1),na));
	RETVAL = MakeWindow(window_name,display_name,exclusive);

	OUTPUT:
	RETVAL

void
SetCurrentWindow(window)
	Widget		window

void
CloseWindow()

Widget
MakeForm(parent, where1, from1, where2, from2, name = "form")
	Widget		parent
	int		where1
	Widget		from1
	int		where2
	Widget		from2
	char *		name
	CODE:

	Newz(666, tmp , 1, struct Edata);
	RETVAL = MakeForm(parent, where1, from1, where2, from2, name);

	OUTPUT:
	RETVAL

void
SetForm(form)
	Widget		form


Widget
MakeButton(label, callback, data, name = "button")
	char *		label
	SV *		callback
	SV *		data
	char *		name
	CODE:

	Newz(666, tmp, 1, struct Edata);
	tmp->data = newSVsv(data);
	tmp->fun[CB_GENFUN] = NewCallback(callback); 
	RETVAL = MakeButton(label, button_callback, tmp, name);

	OUTPUT:
	RETVAL

Widget
Make3Button(label, callback1, callback2, callback3, data, name = "ThreeCom")
	char *		label
	SV *		callback1
	SV *		callback2
	SV *		callback3
	SV *		data
	char *		name
	CODE:

	Newz(666, tmp, 1, struct Edata);
	tmp->data = newSVsv(data);
	tmp->fun[CB_BUTT_1] = NewCallback(callback1);
	tmp->fun[CB_BUTT_2] = NewCallback(callback2);
	tmp->fun[CB_BUTT_3] = NewCallback(callback3);
	RETVAL = Make3Com(label, but1_callback, but2_callback, but3_callback, tmp, name);

	OUTPUT:
	RETVAL

Widget
MakeLabel(txt,name = "label")
	char *		txt
	char *		name
	CODE:

	Newz(666, tmp, 1, struct Edata);
	RETVAL = MakeLabel(txt,name);

	OUTPUT:
	RETVAL

Widget
MakeToggle(txt, state, widget, callback, data, name = "toggle")
	char *		txt
	int		state
	Widget		widget
	SV *		callback
	SV *		data
	char *		name
	CODE:

	Newz(666, tmp, 1, struct Edata);
	tmp->data = newSVsv(data);
	tmp->fun[CB_GENFUN] = NewCallback(callback);
	RETVAL = MakeToggle(txt, state, widget, button_callback, tmp, name);

	OUTPUT:
	RETVAL

void
SetToggleState(widget, state)
	Widget		widget
	int		state

int
GetToggleState(widget)
	Widget		widget

Widget
MakeDrawArea(width, height, callback, data, name = "drawing_area")
	int		width
	int		height
	SV *		callback
	SV *		data
	char *		name
	CODE:

	Newz(666, tmp, 1, struct Edata);
	tmp->data = newSVsv(data);
	tmp->fun[CB_GENFUN] = NewCallback(callback);
	RETVAL = MakeDrawArea(width, height, redisplay_callback, tmp, name);

	OUTPUT:
	RETVAL

void
SetButtonDownCB(widget, callback)
	Rwidget		widget
	SV *		callback
	CODE:
	if (SvTRUE(callback)) {
	  widget->fun[CB_BD_IDX] = NewCallback(callback);
	  SetButtonDownCB(widget->w, button_down_callback);
	} else {
	  SetButtonDownCB(widget->w, NULL);
	}

void
SetButtonUpCB(widget, callback)
	Rwidget		widget
	SV *		callback
	CODE:
        if (SvTRUE(callback)) {
	  widget->fun[CB_BU_IDX] = NewCallback(callback);
	  SetButtonUpCB(widget->w, button_up_callback);
	} else {
	  SetButtonUpCB(widget->w, NULL);
	}

void
SetKeypressCB(widget, callback)
	Rwidget		widget
	SV *		callback
	CODE:
	if (SvTRUE(callback)) {
	  widget->fun[CB_KP_IDX] = NewCallback(callback);
	  SetKeypressCB(widget->w, keypress_callback);
	} else {
	  SetKeypressCB(widget->w, NULL);
	}

void
SetMouseMotionCB(widget, callback)
	Rwidget		widget
	SV *		callback
	CODE:
	if (SvTRUE(callback)) {
	  widget->fun[CB_MM_IDX] = NewCallback(callback);
	  SetMouseMotionCB(widget->w, motion_callback);
	} else {
	  SetMouseMotionCB(widget->w, NULL);
	}

void
SetColor(color)
	int		color

void
SetDrawMode(mode)
	int		mode

void
SetLineWidth(width)
	int		width

void
SetDrawArea(widget)
	Widget		widget

void
GetDrawAreaSize(width, height)
	int		&width
	int		&height
	OUTPUT:
	width
	height

void
ClearDrawArea()

void
DrawPixel(x1, y1)
	int		x1
	int		y1

int
GetPixel(x1, y1)
	int		x1
	int		y1

void
DrawLine(x1, y1, x2, y2)
	int		x1
	int		y1
	int		x2
	int		y2

void
DrawPolyline(points, ...)
	XPoint *	points = NO_INIT
	PROTOTYPE:	@
	CODE:
	{
		int n, i;

		i = items / 2;
		New(666,points,i,XPoint);
		for (n = 0; n < i; n++) {
			points[n].x = SvIV(ST(0+(2*n)));
		  	points[n].y = SvIV(ST(1+(2*n)));
		}
		DrawPolyline(points, n);
		Safefree(points);
	}


void
DrawFilledPolygon(points, ...)
	XPoint *	points = NO_INIT
	PROTOTYPE:	@
	CODE:
	{
		int n, i;

		i = items / 2;
		New(666,points,i,XPoint);
		for (n = 0; n < i; n++) {
			points[n].x = SvIV(ST(0+(2*n)));
		  	points[n].y = SvIV(ST(1+(2*n)));
		}
		DrawFilledPolygon(points, n);
		Safefree(points);
	}

void
DrawFilledBox(x, y, width, height)
	int		x
	int		y
	int		width
	int		height

void
DrawBox(x, y, width, height)
	int		x
	int		y
	int		width
	int		height

void
DrawText(string, x, y)
	char *		string
	int		x
	int		y

void
DrawArc(x, y, width, height, angle1, angle2)
	int		x
	int		y
	int		width
	int		height
	int		angle1
	int		angle2

void
DrawFilledArc(x, y, width, height, angle1, angle2)
	int		x
	int		y
	int		width
	int		height
	int		angle1
	int		angle2

void
DrawImage(data, x, y, width, height)
	Byte_Array	data
	int		x
	int		y
	int		width
	int		height

void
GetImage(x, y, width, height, result)
	int		x
	int		y
	int		width
	int		height
	Byte_Array	result = NO_INIT
	CODE:
	{

		New(666,result,width*height,unsigned char);
		GetImage(result,x,y,width,height);
	}
	OUTPUT:
	result	sv_setpvn(ST(4), (char *)result, width*height);

void
ScrollDrawArea(dx, dy, x1, y1, x2, y2)
	int		dx
	int		dy
	int		x1
	int		y1
	int		x2
	int		y2

Widget
MakeStringEntry(txt, size, callback, data = &sv_undef, name = "string")
	char *		txt
	int		size
	SV *		callback
	SV *		data
	char *		name
	CODE:

	Newz(666, tmp, 1, struct Edata);
	tmp->data = newSVsv(data);
	tmp->fun[CB_GENFUN] = NewCallback(callback);
	RETVAL = MakeStringEntry(txt, size, string_callback, tmp, name);

	OUTPUT:
	RETVAL

void
SetStringEntry(widget, new_text)
	Widget		widget
	char *		new_text

char *
GetStringEntry(widget)
	Widget		widget

Widget
MakeTextWidget(txt, is_file, editable, width, height, name = "text")
	char *		txt
	int		is_file
	int		editable
	int		width
	int		height
	char *		name
	CODE:

	Newz(666, tmp, 1, struct Edata);
	RETVAL = MakeTextWidget(txt, is_file, editable, width, height, name);

	OUTPUT:
	RETVAL

void
SetTextWidgetText(widget, txt, is_file)
	Widget		widget
	char *		txt
	int		is_file

char *
GetTextWidgetText(widget)
	Widget		widget

Widget
MakeHorizScrollbar(len, callback, data, name = "scrollbar")
	int		len
	SV *		callback
	SV *		data
	char *		name
	CODE:

	Newz(666, tmp, 1, struct Edata);
	tmp->data = newSVsv(data);
	tmp->fun[CB_GENFUN] = NewCallback(callback);
	RETVAL = MakeHorizScrollbar(len, scroll_callback, tmp, name);

	OUTPUT:
	RETVAL

Widget
MakeVertScrollbar(height, callback, data, name = "scrollbar")
	int		height
	SV *		callback
	SV *		data
	char *		name
	CODE:

	Newz(666, tmp, 1, struct Edata);
	tmp->data = newSVsv(data);
	tmp->fun[CB_GENFUN] = NewCallback(callback);
	RETVAL = MakeVertScrollbar(height, scroll_callback, tmp, name);

	OUTPUT:
	RETVAL

void
SetScrollbar(widget, where, max, size_shown)
	Widget		widget
	float		where
	float		max
	float		size_shown

Widget
MakeScrollList(width, height, callback, data, list, ...)
	int		width
	int		height
	SV *		callback
	SV *		data
	char **		list = NO_INIT
	PROTOTYPE:	$$$$@
	CODE:

	list = XS_unpack_String_Array(ax+4,items-4);
	Newz(666, tmp, 1, struct Edata);
	tmp->data = newSVsv(data);
	tmp->fun[CB_GENFUN] = NewCallback(callback);
	RETVAL = MakeScrollList(list, width, height, list_callback, tmp);

	OUTPUT:
	RETVAL

Widget
Make3List(width, height, callback, data, list, ...)
	int		width
	int		height
	SV *		callback
	SV *		data
	char **		list = NO_INIT
	PROTOTYPE:	$$$$@
	CODE:

	list = XS_unpack_String_Array(ax+4,items-4);
	Newz(666, tmp, 1, struct Edata);
	tmp->data = newSVsv(data);
	tmp->fun[CB_GENFUN] = NewCallback(callback);
	RETVAL = MakeThreeList(list, width, height, threelist_callback, tmp);

	OUTPUT:
	RETVAL

void
SetCurrentListItem(widget, list_index)
	Widget		widget
	int		list_index

int
GetCurrentListItem(widget)
	Widget		widget

void
ChangeScrollList(widget, new_list, ...)
	Widget		widget
	char **		new_list = NO_INIT
	PROTOTYPE:	$@
	CODE:
	new_list = XS_unpack_String_Array(ax+1,items-1);
	ChangeScrollList(widget,new_list);

Widget
MakeMenu(title, name = "menuButton")
	char *		title
	char *		name
	CODE:

	Newz(666, tmp, 1, struct Edata);
	RETVAL = MakeMenu(title,name);

	OUTPUT:
	RETVAL

Widget
MakeMenuItem(menu, title, callback, data, name = "menu_item")
	Widget		menu
	char *		title
	SV *		callback
	SV *		data
	char *		name
	CODE:

	Newz(666, tmp, 1, struct Edata);
	tmp->data = newSVsv(data);
	tmp->fun[CB_GENFUN] = NewCallback(callback);
	RETVAL = MakeMenuItem(menu, title, button_callback, tmp, name);

	OUTPUT:
	RETVAL

void
SetMenuItemChecked(widget, state)
	Widget		widget
	int		state

int
GetMenuItemChecked(widget)
	Widget		widget

void
SetWidgetPos(parent, where1, from1, where2, from2)
	Widget		parent
	int		where1
	Widget		from1
	int		where2
	Widget		from2

void
AttachEdge(widget, edge, attach_to)
	Widget		widget
	int		edge
	int		attach_to

void
SetFgColor(widget, color)
	Widget		widget
	int		color

void
SetBgColor(widget, color)
	Widget		widget
	int		color

void
SetBorderColor(widget, color)
	Widget		widget
	int		color

int
GetFgColor(widget)
	Widget		widget

int
GetBgColor(widget)
	Widget		widget

void
SetLabel(widget, txt)
	Widget		widget
	char *		txt

void
SetWidgetState(widget, state)
	Widget		widget
	int		state

int
GetWidgetState(widget)
	Widget		widget

void
SetWidgetBitmap(widget, data, width, height)
	Widget		widget
	Byte_Array	data
	int		width
	int		height

void
Beep()

XFont
GetFont(fontname)
	char *		fontname

void
SetWidgetFont(widget, font)
	Widget		widget
	XFont		font

XFont
GetWidgetFont(widget)
	Widget		widget

void
FreeFont(font)
	XFont		font

int
FontHeight(font)
	XFont		font

int
TextWidth(font, txt)
	XFont		font
	char *		txt

unsigned long
AddTimeOut(interval, callback, data)
	unsigned long	interval
	SV *		callback
	SV *		data
	CODE:
	Newz(666, tmp, 1, struct Edata);
	tmp->data = newSVsv(data);
	tmp->fun[CB_GENFUN] = NewCallback(callback);
	RETVAL = AddTimeOut(interval, general_callback, tmp);

	OUTPUT:
	RETVAL

void
RemoveTimeOut(id)
	unsigned long	id

unsigned long
AddReadCallback(fd, callback, data)
	int		fd
	SV *		callback
	SV *		data
	CODE:

	Newz(666, tmp, 1, struct Edata);
	tmp->data = newSVsv(data);
	tmp->fun[CB_GENFUN] = NewCallback(callback);
	RETVAL = AddReadCallback(fd, io_callback, tmp);

	OUTPUT:
	RETVAL

unsigned long
AddWriteCallback(fd, callback, data)
	int		fd
	SV *		callback
	SV *		data
	CODE:

	Newz(666, tmp, 1, struct Edata);
	tmp->data = newSVsv(data);
	tmp->fun[CB_GENFUN] = NewCallback(callback);
	RETVAL = AddWriteCallback(fd, io_callback, tmp);

	OUTPUT:
	RETVAL

void
RemoveReadWriteCallback(id)
	unsigned long	id

char *
GetString(blurb, default_string)
	char *		blurb
	char *		default_string

int
GetYesNo(question)
	char *		question

void
GetStandardColors()

int
GetNamedColor(name)
	char *		name

int
GetRGBColor(red, green, blue)
	int		red
	int		green
	int		blue

void
FreeStandardColors()

int
GetPrivateColor()

void
SetPrivateColor(which, red, green, blue)
	int		which
	int		red
	int		green
	int		blue

void
FreePrivateColor(which)
	int		which

int
GetAllColors()

void
SetColorMap(num)
	int		num

void
SetMyColorMap(color_array, ...)
	RGB_Array	color_array = NO_INIT
	PROTOTYPE:	@
	CODE:
	{
		unsigned char *red, *green, *blue;
		int n, i;
		
		i = items / 3;
		New(666,red,i,unsigned char);
		New(666,green,i,unsigned char);
		New(666,blue,i,unsigned char);
		for (n = 0; n < i; n++) {
			red[n] = (unsigned char) 	SvIV(ST(0+(n*3)));
			green[n] = (unsigned char)	SvIV(ST(1+(n*3)));
			blue[n] = (unsigned char)	SvIV(ST(2+(n*3)));
		}
		SetMyColorMap(i,red,green,blue);
		Safefree(red); Safefree(green); Safefree(blue); 
	}		

void
FreeAllColors()

# Add on (C code is in suplibsx.c)

long
WTA(widget)
	Widget		widget
	CODE:
	RETVAL = (long) widget;
	OUTPUT:
	RETVAL

void
DestroyWidget(widget)
	Widget		widget
	CODE:
	if (widget)
	  XtDestroyWidget(widget);


void
WarpPointer(widget, dx, dy)
	Widget		widget
	int		dx
	int		dy
	CODE:
	XWarpPointer(lsx_curwin->display,None,widget->core.window,0,0,0,0,dx,dy);

void
SetWidgetInt(widget, resource, value)
	Widget		widget
	char *		resource
	int		value

void
SetWidgetDat(widget, resource, value)
	Widget		widget
	char *		resource
	char *		value

int
GetWidgetInt(widget, resource)
	Widget		widget
	char *		resource

char *
GetWidgetDat(widget, resource)
	Widget		widget
	char *		resource

void
AppendText(widget, text)
	Widget		widget
	char *		text

void
InsertText(widget, text)
	Widget		widget
	char *		text


void
AddTrans(widget, text)
	Widget		widget
	char *		text

Widget
MakeCanvas(width, height, expose, realize, resize, data, name = "canvas")
	int		width
	int		height
	SV *		expose
	SV *		realize
	SV *		resize
	SV *		data
	CODE:

	Newz(666, tmp, 1, struct Edata);
	tmp->data = newSVsv(data);
	tmp->fun[CB_REAFUN] = NewCallback(realize);
	tmp->fun[CB_RESFUN] = NewCallback(resize);
	tmp->fun[CB_EXPFUN] = NewCallback(expose);
	RETVAL = MakeCanvas(width, height, realize_callback, resize_callback,
					   expose_callback, tmp);
	OUTPUT:
	RETVAL




# Completion for various widget. Here are some Text widget functions
# This is temporary, there'll be a complete rewrite to get every 'standard'
# Athena widget public functions.

void
GetTextSelectionPos(widget, begin, end)
	Widget		widget
	long		&begin
	long		&end
	CODE:
	XawTextGetSelectionPos(widget, &begin, &end);
	OUTPUT:
	begin
	end

int
ReplaceText(w, start, end, text)
	Widget		w
	long		start
	long		end
	char *		text

void
UnsetTextSelection(widget)
	Widget		widget
	CODE:
	XawTextUnsetSelection(widget);

void
SetTextSelection(widget, left, right)
	Widget		widget
	long		left
	long		right
	CODE:
	XawTextSetSelection(widget,left,right);

void
GetSelection(widget, buf)
	Widget		widget
	char *		buf = NO_INIT
	CODE:
	{
	long x, y;
	XawTextGetSelectionPos(widget,&x,&y);
	buf = (char *) _XawTextGetText(widget,x,y);
	}
	OUTPUT:
	buf	sv_setpvn(ST(1), (char *)buf, strlen(buf));



# Variable/Constants to function call...

int
WHITE()
	CODE:
	RETVAL = WHITE;
	OUTPUT:
	RETVAL

int
BLACK()
	CODE:
	RETVAL = BLACK;
	OUTPUT:
	RETVAL

int
RED()
	CODE:
	RETVAL = RED;
	OUTPUT:
	RETVAL

int
GREEN()
	CODE:
	RETVAL = GREEN;
	OUTPUT:
	RETVAL

int
BLUE()
	CODE:
	RETVAL = BLUE;
	OUTPUT:
	RETVAL

int
YELLOW()
	CODE:
	RETVAL = YELLOW;
	OUTPUT:
	RETVAL



