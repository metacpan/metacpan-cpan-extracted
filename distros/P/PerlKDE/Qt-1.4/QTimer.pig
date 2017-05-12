#include <qtimer.h>

suicidal virtual class QTimer : virtual QObject {
    QTimer(QObject * = 0, const char * = 0);
    virtual ~QTimer();
    void changeInterval(int);
    bool isActive() const;
    static void singleShot(int, QObject *{receiver(2)}, const char *{member(1)});
    int start(int, bool = FALSE);
    void stop();
protected:
    virtual bool event(QEvent *);
    void timeout() signal;
} Qt::Timer;
