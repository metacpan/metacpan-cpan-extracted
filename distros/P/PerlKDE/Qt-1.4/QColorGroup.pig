#include <qpalette.h>

struct QColorGroup {
    QColorGroup();
    QColorGroup(const QColorGroup &);
    QColorGroup(const QColor &, const QColor &, const QColor &, const QColor &, const QColor &, const QColor &, const QColor &);
    ~QColorGroup();
    bool operator == (const QColorGroup &) const;
    bool operator != (const QColorGroup &) const;
    const char *{serial} operator << () const : pig_serialize($this);
    void operator >> (const char *{serial}) : pig_deserialize($this, $1);
    const QColor &background() const;
    const QColor &base() const;
    const QColor &dark() const;
    const QColor &foreground() const;
    const QColor &light() const;
    const QColor &mid() const;
    QColor midlight() const;
    const QColor &text() const;
} Qt::ColorGroup;
