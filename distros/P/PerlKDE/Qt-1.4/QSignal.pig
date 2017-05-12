#include <qsignal.h>

suicidal virtual class QSignal {
    QSignal(QObject * = 0, const char * = 0);
    void activate();
    void block(bool);
    bool connect(const QObject *{receiver(2)}, const char *{member(1)});
    bool disconnect(const QObject *{unreceiver(2)}, const char *{member(1)} = 0);
    bool isBlocked() const;
    const char *name() const;
    void setName(const char *);
} Qt::Signal;
