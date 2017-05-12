#include <qevent.h>

struct QDragResponseEvent : QEvent {
    QDragResponseEvent(bool);
    bool dragAccepted() const;
} Qt::DragResponseEvent;
