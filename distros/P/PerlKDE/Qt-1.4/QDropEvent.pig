#include <qevent.h>

struct QDropEvent : QEvent {
    QDropEvent(const QPoint &);
    void accept();
    QByteArray data(const char *);
    void ignore();
    bool isAccepted() const;
    const QPoint &pos() const;
} Qt::DropEvent;
