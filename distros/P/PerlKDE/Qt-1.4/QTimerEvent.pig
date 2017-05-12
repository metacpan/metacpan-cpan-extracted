#include <qevent.h>

struct QTimerEvent : QEvent {
    QTimerEvent(int);
    QTimerEvent(const QTimerEvent &);
    int timerId() const;
} Qt::TimerEvent;
