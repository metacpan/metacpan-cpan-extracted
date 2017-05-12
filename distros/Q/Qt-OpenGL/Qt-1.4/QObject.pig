#include <qobject.h>

suicidal virtual class QObject {
    QObject(QObject * = 0, const char * = 0);
    virtual ~QObject();
    void blockSignals(bool);
    const QObjectList *children() const;
#   virtual const char *className() const;
    static bool connect(const QObject *{receiver(3)}, const QObject *{sender(2)}, const char *{signal(1)}, const char *{member(0)}) : QObject::connect($1, $2, $0, $3);
    static bool connect(const QObject *{sender(1)}, const char *{signal(0)}, const QObject *{receiver(3)}, const char *{member(2)});
    bool disconnect(const QObject *{unreceiver(2)}, const char *{member(1)} = 0);
    static bool disconnect(const QObject *, const char *{signal(-1)}, const QObject *{unreceiver(3)}, const char *{member(2)});
    void dumpObjectInfo();
    void dumpObjectTree();
    virtual bool event(QEvent *);
    virtual bool eventFilter(QObject *, QEvent *);
    bool highPriority() const;
    void insertChild(QObject *);
    void installEventFilter(const QObject *);
    bool isWidgetType() const;
    void killTimer(int);
    void killTimers();
#   virtual QMetaObject *metaObject() const;
    const char *name() const;
    const char *name(const char *) const;
    QObject *parent() const;
    void removeChild(QObject *);
    void removeEventFilter(const QObject *);
    void setName(const char *);
    bool signalsBlocked() const;
    int startTimer(int);
    const char *tr(const char *) const;
protected:
    virtual void connectNotify(const char *{signal(-1)});
    void destroyed() signal;
    virtual void disconnectNotify(const char *{signal(-1)});
    const QObject *sender();
    virtual void timerEvent(QTimerEvent *);
} Qt::Object;
