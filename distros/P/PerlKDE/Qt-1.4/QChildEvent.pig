#include <qevent.h>

struct QChildEvent : QEvent {
    QChildEvent(int, QWidget *);
    QWidget *child() const;
    bool inserted() const;
    bool removed() const;
} Qt::ChildEvent;
