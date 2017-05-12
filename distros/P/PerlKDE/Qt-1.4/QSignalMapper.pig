#include <qsignalmapper.h>

suicidal virtual class QSignalMapper : virtual QObject {
    QSignalMapper(QObject *, const char * = 0);
    virtual ~QSignalMapper();
    void map() slot;
    void setMapping(const QObject *, int);
    void setMapping(const QObject *, const char *);
    void removeMappings(const QObject *);
protected:
    void mapped(int) signal;
    void mapped(const char *) signal;
} Qt::SignalMapper;
