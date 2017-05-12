#include <qregion.h>

struct QRegion {
    enum RegionType { Rectangle, Ellipse };
    QRegion();
    QRegion(const QRegion &);
    QRegion(const QRect &, QRegion::RegionType = QRegion::Rectangle);
    QRegion(const QPointArray &, bool = FALSE);
    QRegion(int, int, int, int, QRegion::RegionType = QRegion::Rectangle);
    ~QRegion();
    QRegion &operator = (const QRegion &);
    bool operator == (const QRegion &) const;
    bool operator != (const QRegion &) const;
    const char *{serial} operator << () const : pig_serialize($this);
    void operator >> (const char *{serial}) : pig_deserialize($this, $1);
    QRect boundingRect() const;
    bool contains(const QPoint &) const;
    bool contains(const QRect &) const;
    QRegion eor(const QRegion &) const;
    QRegion intersect(const QRegion &) const;
    bool isEmpty() const;
    bool isNull() const;
    QArray<QRect> rects() const;
    QRegion subtract(const QRegion &) const;
    void translate(int, int);
    QRegion unite(const QRegion &) const;
    QRegion xor(const QRegion &) const : $this->eor($1);
} Qt::Region;
