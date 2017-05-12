#include <qpaintdevice.h>

class QPaintDevice {
#   QPaintDevice(uint);
    virtual ~QPaintDevice();
    void bitBlt(const QPoint &, const QPaintDevice *, const QRect & = QRect(0,0,-1,-1), RasterOp = CopyROP, bool = FALSE) : bitBlt($this, $1, $2, $3, $4, $5);
    void bitBlt(int, int, const QPaintDevice *, int = 0, int = 0, int = -1, int = -1, RasterOp = CopyROP, bool = FALSE) : bitBlt($this, $1, $2, $3, $4, $5, $6, $7, $8, $9);
    int devType() const;
    HANDLE handle() const;
    bool isExtDev() const;
    bool paintingActive() const;
    static Display *x__Display();
    static int x11Cells();
    static HANDLE x11Colormap();
    static bool x11DefaultColormap();
    static bool x11DefaultVisual();
    static int x11Depth();
    Display *x11Display() const;
    static int x11Screen();
    static void *x11Visual();
} Qt::PaintDevice;

const int PDT_UNDEF;
const int PDT_WIDGET;
const int PDT_PIXMAP;
const int PDT_PRINTER;
const int PDT_PICTURE;
const int PDT_MASK;
const int PDF_EXTDEV;
const int PDF_PAINTACTIVE;
