#include <qevent.h>

struct QShowEvent : QEvent {
    QShowEvent(bool);
    bool spontaneous() const;
} Qt::ShowEvent;
