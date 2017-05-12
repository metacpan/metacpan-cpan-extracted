/* What will I use my programming skill for? */

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "caca.h"

#include <sys/types.h>

/* ref($object) eq 'HASH' && $object->{__address} */
void *
address_of(SV *object)
{
  /* make sure object is a hashref */
  if (SvTYPE(SvRV(object)) != SVt_PVHV) {
    return NULL;
  }
  return (void *)
    SvIV(*hv_fetch((HV *) SvRV(object), "__address", 9, 0));
}

/* lookup value of key in hashref - value must be an integer
 * ref($object) eq 'HASH' && $object->{$key} */
int
hashref_lookup(SV *object, char *key)
{
  /* make sure object is a hashref */
  if (SvTYPE(SvRV(object)) != SVt_PVHV) {
    return 0;
  }
  return SvIV(*hv_fetch((HV *) SvRV(object), key, strlen(key), 0));
}

/* turn a perl array of numbers into a c array of 8 bit integers */
void *
c_array_8(SV *p_array_ref)
{
  int i;
  int len;
  I8 *c_array;
  AV *p_array = (AV *) SvRV(p_array_ref);

  /* len = scalar(p_array) */
  len = av_len(p_array);

  /* malloc */
  c_array = malloc(len * sizeof(I8));

  /* for (;;) { } */
  for (i = 0; i < len; i++) {
    SV **integer;
    integer = av_fetch(p_array, i, 0);
    c_array[i] = SvIV(*integer);
  }

  /* return */
  return c_array;
}

/* turn a perl array of numbers into a c array of 16 bit integers */
void *
c_array_16(SV *p_array_ref)
{
  int i;
  int len;
  I16 *c_array;
  AV *p_array = (AV *) SvRV(p_array_ref);

  /* len = scalar(p_array) */
  len = av_len(p_array);

  /* malloc */
  c_array = malloc(len * sizeof(I16));

  /* for (;;) { } */
  for (i = 0; i < len; i++) {
    SV **integer;
    integer = av_fetch(p_array, i, 0);
    c_array[i] = SvIV(*integer);
  }

  /* return */
  return c_array;
}

/* turn a perl array of numbers into a c array of 32 bit integers */
void *
c_array_32(SV *p_array_ref)
{
  int i;
  int len;
  I32 *c_array;
  AV *p_array = (AV *) SvRV(p_array_ref);

  /* len = scalar(p_array) */
  len = av_len(p_array);

  /* malloc */
  c_array = malloc(len * sizeof(I32));

  /* for (;;) { } */
  for (i = 0; i < len; i++) {
    SV **integer;
    integer = av_fetch(p_array, i, 0);
    c_array[i] = SvIV(*integer);
  }

  /* return */
  return c_array;
}

MODULE = Term::Caca   PACKAGE = Term::Caca

# import/export

SV *
_export( canvas, format ) 
        void * canvas;
        char * format;
    CODE:
        size_t size;
        SV *export;
        char *string;

        string = caca_export_canvas_to_memory( canvas, format, &size );
        export = newSVpv( string, size );
        RETVAL = export;
    OUTPUT:
        RETVAL


# -==[- Basic functions -]==--------------------------------------------------

void
_set_delay(display,usec)
    void *display;
    unsigned int usec;
  CODE:
    caca_set_display_time(display,usec);

int
_get_delay(display)
    void *display;
  CODE:
    RETVAL = caca_get_display_time(display);
  OUTPUT:
    RETVAL

void *
_create_display_with_driver(driver)
        char *driver;
    CODE:
        RETVAL = caca_create_display_with_driver( NULL, driver );
    OUTPUT:
        RETVAL

void *
_create_display()
    CODE:
        RETVAL = caca_create_display(NULL);
    OUTPUT:
        RETVAL

void *
_get_canvas(display)
    void *display
    CODE:
        RETVAL = caca_get_canvas(display);
    OUTPUT:
        RETVAL
        


unsigned int
_get_width(canvas)
    void *canvas;
  CODE:
    RETVAL = caca_get_canvas_width(canvas);
  OUTPUT:
    RETVAL

unsigned int
_get_height(canvas)
    void *canvas;
  CODE:
    RETVAL = caca_get_canvas_height(canvas);
  OUTPUT:
    RETVAL

int
_set_display_title(display,title)
    void *display;
    const char *title;
  CODE:
    RETVAL = caca_set_display_title(display, title);
  OUTPUT:
    RETVAL

void
_refresh(display)
    void *display;
  CODE:
    caca_refresh_display(display);

void
_free_display(display)
        void *display;
    CODE:
        caca_free_display(display);

# -==[- Event handling -]==---------------------------------------------------

void *
_get_event(display,event_mask,timeout, want_event )
    void *display;
    int event_mask;
    int timeout;
    int want_event;
  CODE:
    caca_event_t * ev;
    ev = want_event ? malloc( sizeof( caca_event_t ) ) : NULL;
    caca_get_event(display, event_mask,ev,timeout);
    RETVAL = ev;
  OUTPUT:
    RETVAL

int
_get_event_type(event)
        void *event;
    CODE:
        RETVAL = caca_get_event_type(event);
    OUTPUT:
        RETVAL

char
_get_event_key_ch(event)
        void *event;
    CODE:
        RETVAL = caca_get_event_key_ch(event);
    OUTPUT:
        RETVAL

void
_free_event(event)
        void *event;
    CODE:
        free(event);

unsigned int
_get_mouse_x(display)
    void *display;
  CODE:
    RETVAL = caca_get_mouse_x(display);
  OUTPUT:
    RETVAL

unsigned int
_get_mouse_y(display)
    void *display;
  CODE:
    RETVAL = caca_get_mouse_y(display);
  OUTPUT:
    RETVAL

unsigned int
_get_event_mouse_x(event)
    void *event;
  CODE:
    RETVAL = caca_get_event_mouse_x(event);
  OUTPUT:
    RETVAL

unsigned int
_get_event_mouse_y(event)
    void *event;
  CODE:
    RETVAL = caca_get_event_mouse_y(event);
  OUTPUT:
    RETVAL

int
_get_event_mouse_button(event)
    void *event;
  CODE:
    RETVAL = caca_get_event_mouse_button(event);
  OUTPUT:
    RETVAL

int
_get_event_resize_width(event)
    void *event;
  CODE:
    RETVAL = caca_get_event_resize_width(event);
  OUTPUT:
    RETVAL

int
_get_event_resize_height(event)
    void *event;
  CODE:
    RETVAL = caca_get_event_resize_height(event);
  OUTPUT:
    RETVAL

# -==[- Character printing -]==-----------------------------------------------

void
_set_color(canvas, fgcolor, bgcolor)
    void *canvas;
    unsigned int fgcolor;
    unsigned int bgcolor;
  CODE:
    caca_set_color_argb(canvas,fgcolor, bgcolor);

void
_set_ansi_color(canvas, fgcolor, bgcolor)
    void *canvas;
    unsigned int fgcolor;
    unsigned int bgcolor;
  CODE:
    caca_set_color_ansi(canvas,fgcolor, bgcolor);

void
_putchar(canvas,x, y, c)
    void *canvas;
    int  x;
    int  y;
    char c;
  CODE:
    caca_put_char(canvas,x, y, c);

void
_putstr(canvas, x, y, s)
    void* canvas;
    int        x;
    int        y;
    const char *s;
  CODE:
    caca_put_str(canvas, x, y, s);

# skip caca_printf for now.
# handle va_args on perl side.

void
_clear(canvas)
    void *canvas;
  CODE:
    caca_clear_canvas(canvas);

# -==[- Primitives drawing -]==-----------------------------------------------

void
_draw_line(canvas,x1, y1, x2, y2, c)
    void * canvas;
    int x1;
    int y1;
    int x2;
    int y2;
    char c;
  CODE:
    caca_draw_line(canvas,x1, y1, x2, y2, c);

void
_draw_polyline(canvas,x, y, n, c)
    void * canvas;
    SV *x;
    SV *y;
    int n;
    char c;
  INIT:
    int *xc;
    int *yc;
    int i;
    /* make sure x and y are perl arrayrefs */
    if ( (SvTYPE(SvRV(x)) != SVt_PVAV)
      || (SvTYPE(SvRV(y)) != SVt_PVAV) )
    {
      XSRETURN_UNDEF;
    }

    /* create a C int array out of x and y */
    xc = (int *) malloc((n+1) * sizeof(int *));
    if (!xc) {
      XSRETURN_UNDEF;
    }
    yc = (int *) malloc((n+1) * sizeof(int *));
    if (!yc) {
      XSRETURN_UNDEF;
    }
    for (i = 0; i <= n; i++) {
      SV **integer;

      integer = av_fetch((AV *) SvRV(x), i, 0);
      if (integer) {
        xc[i] = SvIV(*integer);
      } else {
        xc[i] = 0;
      }

      integer = av_fetch((AV *) SvRV(y), i, 0);
      if (integer) {
        yc[i] = SvIV(*integer);
      } else {
        yc[i] = 0;
      }
    }
  CODE:
    caca_draw_polyline(canvas,xc, yc, n, c);
    free(yc);
    free(xc);

void
_draw_thin_line(canvas,x1, y1, x2, y2)
    void * canvas;
    int x1;
    int y1;
    int x2;
    int y2;
  CODE:
    caca_draw_thin_line(canvas,x1, y1, x2, y2);

void
_draw_thin_polyline(canvas,x, y, n)
    void * canvas;
    SV  *x;
    SV  *y;
    int n;
  INIT:
    int *xc;
    int *yc;
    int i;
    /* make sure x and y are perl arrayrefs */
    if ( (SvTYPE(SvRV(x)) != SVt_PVAV)
      || (SvTYPE(SvRV(y)) != SVt_PVAV) )
    {
      XSRETURN_UNDEF;
    }

    /* create a C int array out of x and y */
    xc = (int *) malloc((n+1) * sizeof(int *));
    if (!xc) {
      croak( "could not allocate memory" );
      XSRETURN_UNDEF;
    }
    yc = (int *) malloc((n+1) * sizeof(int *));
    if (!yc) {
      free(xc);
      croak( "could not allocate memory" );
      XSRETURN_UNDEF;
    }
    for (i = 0; i <= n; i++) {
      SV **integer;

      integer = av_fetch((AV *) SvRV(x), i, 0);
      if (integer) {
        xc[i] = SvIV(*integer);
      } else {
        xc[i] = 0;
      }

      integer = av_fetch((AV *) SvRV(y), i, 0);
      if (integer) {
        yc[i] = SvIV(*integer);
      } else {
        yc[i] = 0;
      }
    }
  CODE:
    caca_draw_thin_polyline(canvas,xc, yc, n);
    free(yc);
    free(xc);

void
_draw_circle(canvas,x, y, r, c)
    void * canvas;
    int  x;
    int  y;
    int  r;
    char c;
  CODE:
    caca_draw_circle(canvas,x, y, r, c);

void
_draw_ellipse(canvas,x0, y0, a, b, c)
    void * canvas;
    int  x0;
    int  y0;
    int  a;
    int  b;
    char c;
  CODE:
    caca_draw_ellipse(canvas,x0, y0, a, b, c);

void
_draw_thin_ellipse(canvas,x0, y0, a, b)
    void * canvas;
    int x0;
    int y0;
    int a;
    int b;
  CODE:
    caca_draw_thin_ellipse(canvas,x0, y0, a, b);

void
_fill_ellipse(canvas,x0, y0, a, b, c)
    void * canvas;
    int  x0;
    int  y0;
    int  a;
    int  b;
    char c;
  CODE:
    caca_fill_ellipse(canvas,x0, y0, a, b, c);

void
_draw_box(canvas,x0, y0, x1, y1, c)
    void * canvas;
    int  x0;
    int  y0;
    int  x1;
    int  y1;
    char c;
  CODE:
    caca_draw_box(canvas,x0, y0, x1, y1, c);

void
_draw_thin_box(canvas,x0, y0, x1, y1)
    void * canvas;
    int x0;
    int y0;
    int x1;
    int y1;
  CODE:
    caca_draw_thin_box(canvas,x0, y0, x1, y1);

void
_fill_box(canvas,x0, y0, x1, y1, c)
    void * canvas;
    int  x0;
    int  y0;
    int  x1;
    int  y1;
    char c;
  CODE:
    caca_fill_box(canvas,x0, y0, x1, y1, c);

void
_draw_triangle(canvas, x0, y0, x1, y1, x2, y2, c)
    void * canvas;
    int  x0;
    int  y0;
    int  x1;
    int  y1;
    int  x2;
    int  y2;
    char c;
  CODE:
    caca_draw_triangle(canvas,x0, y0, x1, y1, x2, y2, c);

void
_draw_thin_triangle(canvas,x0, y0, x1, y1, x2, y2)
    void * canvas;
    int x0;
    int y0;
    int x1;
    int y1;
    int x2;
    int y2;
  CODE:
    caca_draw_thin_triangle(canvas,x0, y0, x1, y1, x2, y2);

void
_fill_triangle(canvas, x0, y0, x1, y1, x2, y2, c)
    void * canvas;
    int  x0;
    int  y0;
    int  x1;
    int  y1;
    int  x2;
    int  y2;
    char c;
  CODE:
    caca_fill_triangle(canvas, x0, y0, x1, y1, x2, y2, c);

AV *
_caca_get_display_driver_list() 
  CODE:
    char **drivers;
    int i;
    char *d;
    drivers = (char **)caca_get_display_driver_list();
    RETVAL = newAV();
    i = 0;
    while ( d = (char *)drivers[i++] ) {
        av_push( RETVAL, newSVpv( d, strlen(d) ) );
    }
  OUTPUT:
    RETVAL
