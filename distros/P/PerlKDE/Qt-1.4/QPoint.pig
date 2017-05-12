#include <qpoint.h>

struct QPoint {
    QPoint();
    QPoint(const QPoint &);
    QPoint(int, int);
    QPoint &operator += (const QPoint &);
    QPoint &operator -= (const QPoint &);
    QPoint &operator *= (int);
    QPoint &operator *= (double);
    QPoint &operator /= (int);
    QPoint &operator /= (double);
    static bool operator == (const QPoint &, const QPoint &) : operator == ($0, $1);
    static bool operator != (const QPoint &, const QPoint &) : operator != ($0, $1);
    static QPoint operator + (const QPoint &, const QPoint &) : operator + ($0, $1);
    static QPoint operator - (const QPoint &, const QPoint &) : operator - ($0, $1);
    static QPoint operator * (const QPoint &, int) : operator * ($0, $1);
    static QPoint operator * (const QPoint &, double) : operator * ($0, $1);
    static QPoint operator / (const QPoint &, int) : operator / ($0, $1);
    static QPoint operator / (const QPoint &, double) : operator / ($0, $1);
    static QPoint operator neg (const QPoint &) : operator - ($0);
    const char *{serial} operator << () const : pig_serialize($this);
    void operator >> (const char *{serial}) : pig_deserialize($this, $1);
    bool isNull() const;
    QCOORD rx();
    QCOORD ry();
    void setX(int);
    void setY(int);
    int x() const;
    int y() const;
} Qt::Point;
