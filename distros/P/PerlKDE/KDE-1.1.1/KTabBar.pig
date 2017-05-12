#include <ktabbar.h>

suicidal virtual class KTabBar : virtual QWidget {
    KTabBar(QWidget * = 0, const char * = 0);
    virtual ~KTabBar();
    int addTab(QTab *);
    int currentTab();
    QTabBar *getQTab();
    bool isTabEnabled(int);
    int keyboardFocusTab();
    void setCurrentTab(int) slot;
    void setCurrentTab(QTab *) slot;
    void setTabEnabled(int, bool);
    virtual QSize sizeHint();
    QTab *tab(int);
protected:
    void emitSelected(int) slot;
    void init();
    void leftClicked() slot;
    virtual void paintEvent(QPaintEvent *);
    virtual void resizeEvent(QResizeEvent *);
    void rightClicked() slot;
    void selected(int) signal;
    void setSizes();
    void scrolled(ArrowType) signal;
} KDE::TabBar;
