#include <qevent.h>

struct QDragMoveEvent : QEvent {
    QDragMoveEvent(const QPoint &);
    void accept();
    void accept(const QRect &);
    QRect answerRect() const;
    QByteArray data(const char *);
    const char *format(int = 0);
    void ignore();
    void ignore(const QRect &);
    bool isAccepted() const;
    const QPoint &pos() const;
    bool provides(const char *);
} Qt::DragMoveEvent;
