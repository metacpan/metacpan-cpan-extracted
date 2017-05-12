#include <qlayout.h>

class QLayout : QObject {
    enum { unlimited };
    virtual ~QLayout();
    virtual bool activate();
    int defaultBorder() const;
    void freeze();
    void freeze(int, int);
    QWidget *mainWidget();
    void setMenuBar(QMenuBar *);
} Qt::Layout;
