
/* This is an unprototyped version. It can generate baaad bugs */

/* This file contains all the header definitions for working with this
 * library of functions that make X stuff a lot easier to swallow.
 *
 *              --  This code under the GNU copyleft --
 * 
 *   Dominic Giampaolo
 *   dbg@sgi.com
 */

#ifndef _LIBSX_H_    /* prevent accidental re-inclusions */
#define _LIBSX_H_  

#include <X11/Intrinsic.h>


/*
 * General prototypes for the setup functions
 */
int    OpenDisplay ();
int    GLOpenDisplay ();
void   ShowDisplay ();

void   MainLoop ();
void   SyncDisplay ();


Widget MakeWindow ();
void   SetCurrentWindow ();
void   CloseWindow ();

/* #define's for use with MakeWindow() */
#define SAME_DISPLAY         NULL
#define NONEXCLUSIVE_WINDOW  0
#define EXCLUSIVE_WINDOW     1

  
/* #define for use with SetCurrentWindow() */
#define ORIGINAL_WINDOW  NULL


Widget MakeForm ();
void   SetForm ();

/* for use w/MakeForm() and SetForm() */
#define TOP_LEVEL_FORM  NULL


/*
 * These are typedef's for the various styles of callback functions.
 */
typedef void (*ButtonCB) ();
typedef void (*StringCB) ();
typedef void (*ScrollCB) ();
typedef void (*ListCB) ();

/*
 * These typedef's are for drawing area callbacks only.
 */
typedef void (*RedisplayCB) ();
typedef void (*MouseButtonCB) ();
typedef void (*KeyCB) ();
typedef void (*MotionCB) ();



/*
 * Prototypes for the widget creation functions.  General functions
 * that apply to any widget (such as setting its color or position) follow
 * after these.
 */


/*
 * Button and Label Widget routines.
 */
Widget MakeButton (); 
Widget MakeLabel ();

/*
 * Toggle Widget routines.
 */
Widget MakeToggle ();
void   SetToggleState ();
int    GetToggleState ();



/*
 * Drawing Area and drawing functions.
 */

Widget MakeDrawArea ();

void   SetButtonDownCB ();
void   SetButtonUpCB ();
void   SetKeypressCB ();
void   SetMouseMotionCB ();

void   SetColor ();
void   SetDrawMode ();

#define SANE_XOR  0x7f  /* A sane mode for drawing XOR lines and stuff */

void   SetLineWidth ();
void   SetDrawArea ();
void   GetDrawAreaSize ();

void   ClearDrawArea ();

void   DrawPixel ();
int    GetPixel ();
void   DrawLine ();
void   DrawPolyline ();
void   DrawFilledPolygon ();
void   DrawFilledBox ();
void   DrawBox ();
void   DrawText ();
void   DrawArc ();
void   DrawFilledArc ();
void   DrawImage ();
void   GetImage ();

void   ScrollDrawArea ();

void   SwapBuffers ();  /* only if libsx compiled with -DOPENGL_SUPPORT */



/*
 * String Entry routines.
 */
Widget  MakeStringEntry ();
void    SetStringEntry ();
char   *GetStringEntry ();


/*
 * Ascii Text display widget routines.
 */
Widget  MakeTextWidget ();
void    SetTextWidgetText ();
char   *GetTextWidgetText ();




/*
 * Scrollbar routines.
 */
Widget MakeHorizScrollbar ();
Widget MakeVertScrollbar ();
void   SetScrollbar ();



/*
 * Scrolled list routines.
 */
Widget MakeScrollList ();
void   SetCurrentListItem ();
int    GetCurrentListItem ();
void   ChangeScrollList ();



/*
 * Menu and MenuItem routines.
 */
Widget MakeMenu ();
Widget MakeMenuItem ();

void   SetMenuItemChecked ();
int    GetMenuItemChecked ();




/*
 * Widget position setting functions (used to do algorithmic layout).
 */
void  SetWidgetPos ();

/*
 * define's for button/gadget placement, used to call SetWidgetPos()
 */
#define NO_CARE       0x00 /* don't care where the gadget is placed */
#define PLACE_RIGHT   0x01 /* place me to the right of specified gadget */
#define PLACE_UNDER   0x02 /* place me under the specified gadget */



void AttachEdge();

#define LEFT_EDGE      0x00
#define RIGHT_EDGE     0x01
#define TOP_EDGE       0x02
#define BOTTOM_EDGE    0x03


#define ATTACH_LEFT    0x00   /* attach widget to the left side of form */
#define ATTACH_RIGHT   0x01   /* attach widget to the right side of form */
#define ATTACH_TOP     0x02   /* attach widget to the top of the form */
#define ATTACH_BOTTOM  0x03   /* attach widget to the bottom of the form */



/*
 * General Setting/Getting of Widget attributes.  These apply to any
 * type of widget.
 */
void  SetFgColor ();
void  SetBgColor ();
void  SetBorderColor ();

int   GetFgColor ();
int   GetBgColor ();

void  SetLabel ();

void  SetWidgetState ();    /* turn widgets on and off */
int   GetWidgetState ();

void  SetWidgetBitmap ();

void  Beep ();


/*
 * Font things.
 */
typedef XFontStruct *XFont;     /* make it a little easier to read */

XFont GetFont ();
void  SetWidgetFont ();
XFont GetWidgetFont ();
void  FreeFont ();
int   FontHeight ();
int   TextWidth ();



/*
 * Miscellaneous functions.
 */
typedef void (*GeneralCB) ();
typedef void (*IOCallback) ();
     
unsigned long   AddTimeOut ();
void            RemoveTimeOut ();
unsigned long   AddReadCallback ();
unsigned long   AddWriteCallback ();
void            RemoveReadWriteCallback ();


/*
 * User-input functions 
 */
char *GetString ();
int   GetYesNo ();




/*
 * Colormap things.
 */

extern int WHITE,        /* Global color values to use for drawing in color */
           BLACK,
           RED, 
           GREEN, 
           BLUE,
           YELLOW;


/*
 * Getting/Setting/Freeing Color and Colormap function prototypes
 */
void GetStandardColors ();
int  GetNamedColor ();
int  GetRGBColor ();
void FreeStandardColors ();


int  GetPrivateColor ();
void SetPrivateColor ();
void FreePrivateColor ();


/*
 * The following functions completely take over the display colormap.
 *                       ** Use with caution **
 */
int  GetAllColors ();
void SetColorMap ();
void SetMyColorMap ();
void FreeAllColors ();


/*
 * define's for use in calling SetColorMap()
 */
#define GREY_SCALE_1    0   /* grey-scale with a few other colors */
#define GREY_SCALE_2    1   /* pure grey-scale (0-255) */
#define RAINBOW_1       2   /* different types of rainbows/bands of colors */
#define RAINBOW_2       3



/*
 * define's for Canvas
 */

Widget MakeCanvas();


#endif /* _LIBSX_H_ */
