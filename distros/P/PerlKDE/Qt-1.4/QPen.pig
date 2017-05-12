#include <qpen.h>

struct QPen {
    QPen();
    QPen(PenStyle);
    QPen(const QPen &);
    QPen(const QColor &, uint = 0, PenStyle = SolidLine);
    ~QPen();
    QPen &operator = (const QPen &);
    bool operator == (const QPen &) const;
    bool operator != (const QPen &) const;
    const char *{serial} operator << () const : pig_serialize($this);
    void operator >> (const char *{serial}) : pig_deserialize($this, $1);
    const QColor &color() const;
    void setColor(const QColor &);
    void setStyle(PenStyle);
    void setWidth(uint);
    PenStyle style() const;
    uint width() const;
} Qt::Pen;

enum PenStyle {
    NoPen,
    SolidLine,
    DashLine,
    DotLine,
    DashDotLine,
    DashDotDotLine
};
