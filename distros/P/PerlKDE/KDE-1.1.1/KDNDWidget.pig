#include <drag.h>

suicidal virtual class KDNDWidget : virtual QWidget {
    KDNDWidget(QWidget * = 0, const char * = 0, WFlags = 0);
    virtual ~KDNDWidget();
    virtual void startDrag(KDNDIcon *, char *, int, int, int, int);
protected:
    virtual void dndMouseMoveEvent(QMouseEvent *);
    virtual void dndMouseReleaseEvent(QMouseEvent *);
    virtual void dragEndEvent();
    virtual Window findRootWindow(QPoint &);
    virtual void mouseMoveEvent(QMouseEvent *);
    virtual void mouseReleaseEvent(QMouseEvent *);
    virtual void rootDropEvent();
    virtual void rootDropEvent(int, int);
} KDE::DNDWidget;

const int DndNotDnd;
const int DndUnknown;
const int DndRawData;
const int DndFile;
const int DndFiles;
const int DndText;
const int DndDir;
const int DndLink;
const int DndExe;
const int DndEND;
const int DndURL;

const int Dnd_X_Precision;
const int Dnd_Y_Precision;
