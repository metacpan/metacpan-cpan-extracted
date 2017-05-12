#include <kstatusbar.h>

suicidal virtual class KStatusBar : virtual QFrame {
    enum BarStatus { Toggle, Show, Hide };
    enum Position { Top, Left, Bottom, Right, Floating };
    enum InsertOrder { LeftToRight, RightToLeft };
    KStatusBar(QWidget * = 0L, const char * = 0L);
    virtual ~KStatusBar();
    void changeItem(const char *, int);
    void clear() slot;
    bool enable(KStatusBar::BarStatus);
    int insertItem(const char *, int);
    int insertWidget(QWidget *, int, int);
    void message(const char *, int = 0);
    void message(QWidget *, int = 0);
    void removeItem(int);
    void replaceItem(int, const char *);
    void replaceItem(int, QWidget *);
    void setAlignment(int, int);
    void setBorderWidth(int);
    void setHeight(int);
    void setInsertOrder(KStatusBar::InsertOrder);
    virtual QSize sizeHint();
protected:
    virtual void drawContents(QPainter *);
    void init();
    void pressed(int) signal;
    void released(int) signal;
    virtual void resizeEvent(QResizeEvent *);
    void slotPressed(int) slot;
    void slotReleased(int) slot;
    void updateRects(bool = FALSE);
} KDE::StatusBar;
