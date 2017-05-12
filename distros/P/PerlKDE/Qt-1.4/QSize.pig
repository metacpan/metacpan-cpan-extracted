#include <qsize.h>

struct QSize {
    QSize();
    QSize(const QSize &);
    QSize(int, int);
    QSize &operator = (const QSize &);
    QSize &operator += (const QSize &);
    QSize &operator -= (const QSize &);
    QSize &operator *= (int);
    QSize &operator *= (float);
    QSize &operator /= (int);
    QSize &operator /= (float);
    static bool operator == (const QSize &, const QSize &) : operator == ($0, $1);
    static bool operator != (const QSize &, const QSize &) : operator != ($0, $1);
    static QSize operator + (const QSize &, const QSize &) : operator + ($0, $1);
    static QSize operator - (const QSize &, const QSize &) : operator - ($0, $1);
    static QSize operator * (const QSize &, int) : operator * ($0, $1);
    static QSize operator * (const QSize &, float) : operator * ($0, $1);
    static QSize operator / (const QSize &, int) : operator / ($0, $1);
    static QSize operator / (const QSize &, float) : operator / ($0, $1);
    const char *{serial} operator << () const : pig_serialize($this);
    void operator >> (const char *{serial}) : pig_deserialize($this, $1);
    QSize boundedTo(const QSize &) const;
    QSize expandedTo(const QSize &) const;
    int height() const;
    bool isEmpty() const;
    bool isNull() const;
    bool isValid() const;
    QCOORD rheight();
    QCOORD rwidth();
    void setHeight(int);
    void setWidth(int);
    void transpose();
    int width() const;
} Qt::Size;
