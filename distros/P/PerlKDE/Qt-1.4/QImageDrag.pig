#include <qdragobject.h>

suicidal virtual class QImageDrag : virtual QDragObject {
    QImageDrag(QImage, QWidget * = 0, const char * = 0);
    QImageDrag(QWidget * = 0, const char * = 0);
    virtual ~QImageDrag();
    static bool canDecode(QDragMoveEvent *);
    static bool decode(QDropEvent *, QImage &);
    static bool decode(QDropEvent *, QPixmap &);
    virtual QByteArray encodedData(const char *) const;
    const char *format(int) const;
    void setImage(QImage);
} Qt::ImageDrag;
