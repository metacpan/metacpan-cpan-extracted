#include <drag.h>

suicidal virtual class KDNDDropZone : virtual QObject {
    KDNDDropZone(QWidget *, int);
    virtual ~KDNDDropZone();
    virtual bool accepts(int);
    virtual void drop(char *, int, int, int, int);
    virtual void enter(char *, int, int, int, int);
    virtual int getAcceptType();
    virtual const char *getData();
    virtual int getDataSize();
    virtual int getDataType();
    virtual int getMouseX();
    virtual int getMouseY();
    virtual QStrList &getURLList();
    QWidget *getWidget();
    virtual void leave();
protected:
    void dropAction(KDNDDropZone *) signal;
    void dropEnter(KDNDDropZone *) signal;
    void dropLeave(KDNDDropZone *) signal;
    void parseURLList();
} KDE::DNDDropZone;
