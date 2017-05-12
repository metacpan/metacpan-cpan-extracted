#include <qaccel.h>

suicidal virtual class QAccel : virtual QObject {
    QAccel(QWidget *, const char * = 0);
    virtual ~QAccel();
    void clear();
    bool connectItem(int, const QObject *{receiver(3)}, const char *{member(2)});
    uint count() const;
    bool disconnectItem(int, const QObject *{unreceiver(3)}, const char *{member(2)});
    int findKey(int) const;
    int insertItem(int, int = -1);
    bool isEnabled() const;
    bool isItemEnabled(int) const;
    void key(int);
    void removeItem(int);
    void repairEventFilter();
    void setEnabled(bool);
    void setItemEnabled(int, bool);
protected:
    void activated(int) signal;
    virtual bool eventFilter(QObject *, QEvent *);
} Qt::Accel;
