#include <qdrawutl.h>
#include <qpainter.h>

enum ArrowType {
    UpArrow,
    DownArrow,
    LeftArrow,
    RightArrow
};

class QPainter {
    QPainter();
    QPainter(const QPaintDevice *);
    QPainter(const QPaintDevice *, const QWidget *);
    ~QPainter();
    const QColor &backgroundColor() const;
    BGMode backgroundMode() const;
    bool begin(const QPaintDevice *);
    bool begin(const QPaintDevice *, const QWidget *);
    QRect boundingRect(const QRect &, int, const char *, int = -1, char **{internal} = 0);
    QRect boundingRect(int, int, int, int, int, const char *, int = -1, char **{internal} = 0);
    const QBrush &brush() const;
    const QPoint &brushOrigin() const;
    const QRegion &clipRegion() const;
    QPaintDevice *device() const;
    void drawArc(const QRect &, int, int);
    void drawArc(int, int, int, int, int, int);
    void drawArrow(ArrowType, GUIStyle, bool, int, int, int, int, const QColorGroup &, bool) : qDrawArrow($this, $1, $2, $3, $4, $5, $6, $7, $8, $9);
    void drawChord(const QRect &, int, int);
    void drawChord(int, int, int, int, int, int);
    void drawEllipse(const QRect &);
    void drawEllipse(int, int, int, int);
    void drawImage(const QPoint &, const QImage &);
    void drawImage(const QPoint &, const QImage &, const QRect &);
    void drawImage(int, int, const QImage &, int = 0, int = 0, int = -1, int = -1);
    void drawItem(GUIStyle, int, int, int, int, int, const QColorGroup &, bool, const QPixmap *, const char *, int = -1) : qDrawItem($this, $1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11);
    void drawLine(const QPoint &, const QPoint &);
    void drawLine(int, int, int, int);
    void drawLineSegments(const QPointArray &, int = 0, int = -1);
    void drawPicture(const QPicture &);
    void drawPie(const QRect &, int, int);
    void drawPie(int, int, int, int, int, int);
    void drawPixmap(const QPoint &, const QPixmap &);
    void drawPixmap(const QPoint &, const QPixmap &, const QRect &);
    void drawPixmap(int, int, const QPixmap &, int = 0, int = 0, int = -1, int = -1);
    void drawPlainRect(int, int, int, int, const QColor &, int = 1, const QBrush * = 0) : qDrawPlainRect($this, $1, $2, $3, $4, $5, $6, $7);
    void drawPlainRect(const QRect &, const QColor &, int = 1, const QBrush * = 0) : qDrawPlainRect($this, $1, $2, $3, $4);
    void drawPoint(const QPoint &);
    void drawPoint(int, int);
    void drawPoints(const QPointArray &, int = 0, int = -1);
    void drawPolyline(const QPointArray &, int = 0, int = -1);
    void drawPolygon(const QPointArray &, bool = FALSE, int = 0, int = -1);
    void drawQuadBezier(const QPointArray &, int = 0);
    void drawRect(const QRect &);
    void drawRect(int, int, int, int);
    void drawRoundRect(const QRect &, int, int);
    void drawRoundRect(int, int, int, int, int, int);
    void drawShadeLine(int, int, int, int, const QColorGroup &, bool = TRUE, int = 1, int = 0) : qDrawShadeLine($this, $1, $2, $3, $4, $5, $6, $7, $8);
    void drawShadeLine(const QPoint &, const QPoint &, const QColorGroup &, bool = TRUE, int = 1, int = 0) : qDrawShadeLine($this, $1, $2, $3, $4, $5, $6);
    void drawShadePanel(int, int, int, int, const QColorGroup &, bool = FALSE, int = 1, const QBrush * = 0) : qDrawShadePanel($this, $1, $2, $3, $4, $5, $6, $7, $8);
    void drawShadePanel(const QRect &, const QColorGroup &, bool = FALSE, int = 1, const QBrush * = 0) : qDrawShadePanel($this, $1, $2, $3, $4, $5);
    void drawShadeRect(int, int, int, int, const QColorGroup &, bool = FALSE, int = 1, int = 0, const QBrush * = 0) : qDrawShadeRect($this, $1, $2, $3, $4, $5, $6, $7, $8, $9);
    void drawShadeRect(const QRect &, const QColorGroup &, bool = FALSE, int = 1, int = 0, const QBrush * = 0) : qDrawShadeRect($this, $1, $2, $3, $4, $5, $6);
    void drawText(const QPoint &, const char *, int = -1);
    void drawText(int, int, const char *, int = -1);
    void drawText(const QRect &, int, const char *, int = -1, QRect * = 0, char **{internal} = 0);
    void drawText(int, int, int, int, int, const char *, int = -1, QRect * = 0, char **{internal} = 0);
    void drawTiledPixmap(const QRect &, const QPixmap &);
    void drawTiledPixmap(const QRect &, const QPixmap &, const QPoint &);
    void drawTiledPixmap(int, int, int, int, const QPixmap &, int = 0, int = 0);
    void drawWinButton(int, int, int, int, const QColorGroup &, bool = FALSE, const QBrush * = 0) : qDrawWinButton($this, $1, $2, $3, $4, $5, $6, $7);
    void drawWinButton(const QRect &, const QColorGroup &, bool = FALSE, const QBrush * = 0) : qDrawWinButton($this, $1, $2, $3, $4);
    void drawWinFocusRect(const QRect &);
    void drawWinFocusRect(const QRect &, const QColor &);
    void drawWinFocusRect(int, int, int, int);
    void drawWinFocusRect(int, int, int, int, const QColor &);
    void drawWinPanel(int, int, int, int, const QColorGroup &, bool = FALSE, const QBrush * = 0) : qDrawWinPanel($this, $1, $2, $3, $4, $5, $6, $7);
    void drawWinPanel(const QRect &, const QColorGroup &, bool = FALSE, const QBrush * = 0) : qDrawWinPanel($this, $1, $2, $3, $4);
    bool end();
    void eraseRect(const QRect &);
    void eraseRect(int, int, int, int);
    void fillRect(const QRect &, const QBrush &);
    void fillRect(int, int, int, int, const QBrush &);
    void flush();
    const QFont &font() const;
    QFontInfo fontInfo() const;
    QFontMetrics fontMetrics() const;
    HANDLE handle() const;
    bool hasClipping() const;
    bool hasViewXForm() const;
    bool hasWorldXForm() const;
    bool isActive() const;
    QRect itemRect(GUIStyle, int, int, int, int, int, bool, const QPixmap *, const char *, int = -1) : qItemRect($this, $1, $2, $3, $4, $5, $6, $7, $8, $9, $10);
    void lineTo(const QPoint &);
    void lineTo(int, int);
    void moveTo(const QPoint &);
    void moveTo(int, int);
    const QPen &pen() const;
    RasterOp rasterOp() const;
    static void redirect(QPaintDevice *, QPaintDevice *);
    void resetXForm();
    void restore();
    void rotate(float);
    void save();
    void scale(float, float);
    void setBackgroundColor(const QColor &);
    void setBackgroundMode(BGMode);
    void setBrush(const QBrush &);
    void setBrush(const QColor &);
    void setBrush(BrushStyle);
    void setBrushOrigin(const QPoint &);
    void setBrushOrigin(int, int);
    void setClipping(bool);
    void setClipRect(const QRect &);
    void setClipRect(int, int, int, int);
    void setClipRegion(const QRegion &);
    void setFont(const QFont &);
    void setPen(const QColor &);
    void setPen(const QPen &);
    void setPen(PenStyle);
    void setRasterOp(RasterOp);
    void setTabArray(int * {intarray});
    void setTabStops(int);
    void setViewport(const QRect &);
    void setViewport(int, int, int, int);
    void setViewXForm(bool);
    void setWindow(const QRect &);
    void setWindow(int, int, int, int);
    void setWorldXForm(bool);
    void setWorldMatrix(const QWMatrix &, bool = FALSE);
    void shear(float, float);
    int * {intarray} tabArray() const;
    void tabStops() const;
    void translate(float, float);
    QRect viewport() const;
    QRect window() const;
    const QWMatrix &worldMatrix() const;
    QPoint xForm(const QPoint &) const;
    QPointArray xForm(const QPointArray &) const;
    QRect xForm(const QRect &) const;
    QPointArray xForm(const QPointArray &, int, int) const;
    QPoint xFormDev(const QPoint &) const;
    QPointArray xFormDev(const QPointArray &) const;
    QRect xFormDev(const QRect &) const;
    QPointArray xFormDev(const QPointArray &, int, int) const;
} Qt::Painter;

enum ArrowType {
    UpArrow,
    DownArrow,
    LeftArrow,
    RightArrow
};

enum BGMode {
    TransparentMode,
    OpaqueMode
};

enum PaintUnit {
    PixelUnit,
    LoMetricUnit,
    HiMetricUnit,
    LoEnglishUnit,
    HiEnglishUnit,
    TwipsUnit
};

enum RasterOp {
    CopyROP,
    OrROP,
    XorROP,
    EraseROP,
    NotCopyROP,
    NotOrROP,
    NotXorROP,
    NotEraseROP,
    NotROP
};

extern const int AlignLeft;
extern const int AlignRight;
extern const int AlignHCenter;
extern const int AlignTop;
extern const int AlignBottom;
extern const int AlignVCenter;
extern const int AlignCenter;
extern const int SingleLine;
extern const int DontClip;
extern const int ExpandTabs;
extern const int ShowPrefix;
extern const int WordBreak;
extern const int GrayText;
extern const int DontPrint;

extern const int ColorMode_Mask;
extern const int AutoColor;
extern const int ColorOnly;
extern const int MonoOnly;
extern const int AlphaDither_Mask;
extern const int ThresholdAlphaDither;
extern const int OrderedAlphaDither;
extern const int DiffuseAlphaDither;
extern const int Dither_Mask;
extern const int DiffuseDither;
extern const int OrderedDither;
extern const int ThresholdDither;
extern const int DitherMode_Mask;
extern const int AutoDither;
extern const int PreferDither;
extern const int AvoidDither;
