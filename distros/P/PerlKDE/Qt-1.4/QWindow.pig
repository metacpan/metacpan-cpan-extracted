#include <qwindow.h>

suicidal virtual class QWindow : virtual QWidget {
    QWindow(QWidget * = 0, const char * = 0, WFlags = 0);
    virtual ~QWindow();
} Qt::Window;
