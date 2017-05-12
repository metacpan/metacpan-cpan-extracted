#include <qevent.h>

struct QMouseEvent : QEvent {
    QMouseEvent(const QMouseEvent &);
    QMouseEvent(int, const QPoint &, int, int);
    int button() const;
    const QPoint &pos() const;
    int state() const;
    int x() const;
    int y() const;
} Qt::MouseEvent;
