#include <ktoolboxmgr.h>

suicidal virtual class KToolBoxManager : virtual QObject {
    KToolBoxManager(QWidget *, bool = true);
    virtual ~KToolBoxManager();
    int addHotSpot(const QRect &, bool = false);
    int addHotSpot(int, int, int, int);
    void doMove(bool = false, bool = false, bool = false);
    void doResize(bool = false, bool = false);
    void doXResize(bool = false, bool = false);
    void doYResize(bool = false, bool = false);
    int height();
    int mouseX();
    int mouseY();
    void removeHotSpot(int);
    void resize(int, int);
    void setGeometry(int);
    void setGeometry(int, int, int, int);
    void stop() slot;
    int width();
    int x();
    int y();
protected:
    void deleteLastRectangle();
    void doMoveInternal() slot;
    void doResizeInternal() slot;
    void drawRectangle(int, int, int, int);
    void onHotSpot(int) signal;
    void posChanged(int, int) signal;
    void sizeChanged(int, int) signal;
} KDE::ToolBoxManager;
