#include <qdropsite.h>

suicidal virtual class QDropSite {
    QDropSite(QWidget *);
    virtual ~QDropSite();
    virtual void dragEnterEvent(QDragEnterEvent *);
    virtual void dropEvent(QDropEvent *);
    virtual void dragLeaveEvent(QDragLeaveEvent *);
    virtual void dragMoveEvent(QDragMoveEvent *);
} Qt::DropSite;
