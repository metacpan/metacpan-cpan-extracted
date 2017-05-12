#include <qevent.h>

struct QHideEvent : QEvent {
    QHideEvent(bool);
    bool spontaneous() const;
} Qt::HideEvent;
