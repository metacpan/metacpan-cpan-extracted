#include <kmenubar.h>

suicidal virtual class KMenuBar : virtual QFrame {
    enum menuPosition { Top, Bottom, Floating, Flat, FloatingSystem };
    KMenuBar(QWidget * = 0, const char * = 0);
    virtual ~KMenuBar();
    virtual int accel(int);
    virtual void changeItem(const char *, int);
    virtual void clear();
    virtual uint count();
    void enableFloating(bool = TRUE);
    void enableMoving(bool = TRUE);
    int heightForWidth (int) const;
    virtual int idAt(int);
    virtual int insertItem(const char *, int = -1, int = -1);
    virtual int insertItem(const char *, QPopupMenu *, int = -1, int = -1);
    virtual int insertItem(const char *, const QObject *{receiver(3)}, const char *{member(2)}, int = 0);
    virtual void insertSeparator(int = -1);
    KMenuBar::menuPosition menuBarPos();
    virtual void removeItem(int);
    virtual void removeItemAt(int);
    virtual void setAccel(int, int);
    void setFlat(bool);
    virtual void setItemChecked(int, bool);
    virtual void setItemEnabled(int, bool);
    void setMenuBarPos(KMenuBar::menuPosition);
    void setTitle(const char *);
    virtual const char *text(int);
protected:
    void activated(int) signal;
    virtual void closeEvent(QCloseEvent *);
    void ContextCallback(int) slot;
    virtual bool eventFilter(QObject *, QEvent *);
    void highlighted(int) signal;
    void init();
    virtual void leaveEvent(QEvent *);
    virtual void mousePressEvent(QMouseEvent *);
    void moved(KMenuBar::menuPosition) signal;
    virtual void paintEvent(QPaintEvent *);
    virtual void resizeEvent(QResizeEvent *);
    void slotActivated(int) slot;
    void slotHighlighted(int) slot;
    void slotHotSpot(int) slot;
    void slotReadConfig() slot;
} KDE::MenuBar;
