#include <qpointarray.h>

struct QPointArray {
    QPointArray();
    QPointArray(int);
    QPointArray(const QPointArray &);
    QPointArray(const QRect &, bool = FALSE);
    QPointArray(int {@qt_pointarrayitems(1)}, const QCOORD *{shortarray});
    ~QPointArray();
    QPointArray &operator = (const QPointArray &);
    bool operator == (const QPointArray &) const;
    bool operator != (const QPointArray &) const;
    const char *{serial} operator << () const : pig_serialize($this);
    void operator >> (const char *{serial}) : pig_deserialize($this, $1);
    QPoint at(uint) const;
    QRect boundingRect() const;
    int contains(const QPoint &) const;
    QPointArray copy() const;
    void detach();
    bool fill(const QPoint &, int = -1);
    int find(const QPoint &, uint = 0) const;
    bool isEmpty() const;
    bool isNull() const;
    void makeArc(int, int, int, int, int, int);
    void makeEllipse(int, int, int, int);
    uint nrefs() const;
    QPoint point(uint) const;
    void point(uint, int *, int *) const;
    void putPoints(int, int {@qt_pointarrayitems(2)}, const QCOORD *{shortarray});
    QPointArray quadBezier() const;
    bool resize(uint);
    void setPoint(uint, const QPoint &);
    void setPoint(uint, int, int);
    void setPoints(int {@qt_pointarrayitems(1)}, const QCOORD *{shortarray});
    uint size() const;
    void translate(int, int);
    bool truncate(uint);
} Qt::PointArray;
