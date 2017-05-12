#include <qevent.h>

struct QDragEnterEvent : QEvent {
    QDragEnterEvent(const QPoint &);
} Qt::DragEnterEvent;
