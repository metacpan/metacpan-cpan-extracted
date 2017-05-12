#undef invert
#include <qwmatrix.h>

struct QWMatrix {
    QWMatrix();
    QWMatrix(const QWMatrix &);
    QWMatrix(float, float, float, float, float, float);
    bool operator == (const QWMatrix &) const;
    bool operator != (const QWMatrix &) const;
    QWMatrix &operator *= (const QWMatrix &);
    static QWMatrix operator * (const QWMatrix &, const QWMatrix &) : operator * ($0, $1);
    const char *{serial} operator << () const : pig_serialize($this);
    void operator >> (const char *{serial}) : pig_deserialize($this, $1);
    float dx() const;
    float dy() const;
    QWMatrix invert(bool * = 0);
    float m11() const;
    float m12() const;
    float m21() const;
    float m22() const;
    QPoint map(const QPoint &) const;
    QPointArray map(const QPointArray &) const;
    QRect map(const QRect &) const;
    void map(int, int, int *, int *) const;
    void map(float, float, float *, float *) const;
    void reset();
    QWMatrix &rotate(float);
    QWMatrix &scale(float, float);
    void setMatrix(float, float, float, float, float, float);
    QWMatrix &shear(float, float);
    QWMatrix &translate(float, float);
} Qt::WMatrix, Matrix;
