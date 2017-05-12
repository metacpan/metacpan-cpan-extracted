#include <qevent.h>

struct QPaintEvent : QEvent {
    QPaintEvent(const QPaintEvent &);
    QPaintEvent(const QRect &);
    const QRect &rect() const;
} Qt::PaintEvent;
