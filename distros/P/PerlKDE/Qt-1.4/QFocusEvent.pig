#include <qevent.h>

struct QFocusEvent : QEvent {
    QFocusEvent(int);
    QFocusEvent(const QFocusEvent &);
    bool gotFocus() const;
    bool lostFocus() const;
} Qt::FocusEvent;
