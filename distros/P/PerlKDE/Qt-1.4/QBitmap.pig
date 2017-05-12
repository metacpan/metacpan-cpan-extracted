#include <qbitmap.h>

struct QBitmap : QPixmap {
    QBitmap();
    QBitmap(const QBitmap &);
    QBitmap(const char *, const char * = 0);
    QBitmap(const QSize &, bool = FALSE);
    QBitmap(const QSize &, const uchar *{qt_ubits(1)}, bool = FALSE);
    QBitmap(int, int, bool = FALSE);
    QBitmap(int, int, const uchar *{qt_ubits(1,2)}, bool = FALSE);
    QBitmap &operator =(const QBitmap &);
    QBitmap &operator =(const QImage &);
    QBitmap &operator =(const QPixmap &);
    QBitmap xForm(const QWMatrix &) const;
} Qt::Bitmap;
