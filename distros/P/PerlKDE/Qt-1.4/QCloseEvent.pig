#include <qevent.h>

struct QCloseEvent : QEvent {
    QCloseEvent();
    QCloseEvent(const QCloseEvent &);
    void accept();
    void ignore();
    bool isAccepted() const;
} Qt::CloseEvent;
