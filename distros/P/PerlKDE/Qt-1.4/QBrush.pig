#include <qbrush.h>

struct QBrush {
    QBrush();
    QBrush(BrushStyle);
    QBrush(const QBrush &);
    QBrush(const QColor &, BrushStyle = SolidPattern);
    QBrush(const QColor &, const QPixmap &);
    ~QBrush();
    QBrush &operator = (const QBrush &);
    bool operator == (const QBrush &) const;
    bool operator != (const QBrush &) const;
    const char *{serial} operator << () const : pig_serialize($this);
    void operator >> (const char *{serial}) : pig_deserialize($this, $1);
    const QColor &color() const;
    QPixmap *pixmap() const;
    void setColor(const QColor &);
    void setPixmap(const QPixmap &);
    void setStyle(BrushStyle);
    BrushStyle style() const;
} Qt::Brush;

enum BrushStyle {
    NoBrush,
    SolidPattern,
    Dense1Pattern,
    Dense2Pattern,
    Dense3Pattern,
    Dense4Pattern,
    Dense5Pattern,
    Dense6Pattern,
    Dense7Pattern,
    HorPattern,
    VerPattern,
    CrossPattern,
    BDiagPattern,
    FDiagPattern,
    DiagCrossPattern,
    CustomPattern
};
