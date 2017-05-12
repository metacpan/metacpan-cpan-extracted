#include <qevent.h>

struct QResizeEvent : QEvent {
    QResizeEvent(const QResizeEvent &);
    QResizeEvent(const QSize &, const QSize &);
    const QSize &oldSize() const;
    const QSize &size() const;
} Qt::ResizeEvent;
