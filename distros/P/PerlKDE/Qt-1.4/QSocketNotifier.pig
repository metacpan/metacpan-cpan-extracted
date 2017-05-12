#include <qsocketnotifier.h>

suicidal virtual class QSocketNotifier : virtual QObject {
    enum Type { Read, Write, Exception };
    QSocketNotifier(int, QSocketNotifier::Type, QObject * = 0, const char * = 0);
    virtual ~QSocketNotifier();
    bool isEnabled() const;
    void setEnabled(bool);
    int socket() const;
    QSocketNotifier::Type type() const;
protected:
    void activated(int) signal;
    virtual bool event(QEvent *);
} Qt::SocketNotifier;
