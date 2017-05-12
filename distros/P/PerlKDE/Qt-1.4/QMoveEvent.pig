#include <qevent.h>

struct QMoveEvent : QEvent {
    QMoveEvent(const QMoveEvent &);
    QMoveEvent(const QPoint &, const QPoint &);
    const QPoint &oldPos() const;
    const QPoint &pos() const;
} Qt::MoveEvent;
