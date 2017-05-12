#include <qfiledialog.h>

suicidal virtual class QFileIconProvider : virtual QObject {
    QFileIconProvider(QObject * = 0, const char * = 0);
    virtual const QPixmap *pixmap(const QFileInfo &);
} Qt::FileIconProvider;
