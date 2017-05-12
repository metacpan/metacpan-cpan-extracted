#include <qtabbar.h>

suicidal virtual class QTabBar : virtual QWidget {
    enum Shape {
	RoundedAbove,
	RoundedBelow,
	TriangularAbove,
	TriangularBelow
    };
    QTabBar(QWidget * = 0, const char * = 0);
    virtual ~QTabBar();
    virtual int addTab(QTab *);
    int currentTab() const;
    bool isTabEnabled(int) const;
    int keyboardFocusTab() const;
    void setCurrentTab(int) slot;
    void setCurrentTab(QTab *) slot;
    void setShape(QTabBar::Shape);
    void setTabEnabled(int, bool);
    QTabBar::Shape shape() const;
    virtual void show();
    virtual QSize sizeHint() const;
    QTab *tab(int);
protected:
    virtual void keyPressEvent(QKeyEvent *);
    virtual void mouseMoveEvent(QMouseEvent *);
    virtual void mousePressEvent(QMouseEvent *);
    virtual void mouseReleaseEvent(QMouseEvent *);
    virtual void paint(QPainter *, QTab *, bool) const;
    virtual void paintEvent(QPaintEvent *);
    void selected(int) signal;
    virtual QTab *selectTab(const QPoint &) const;
    QListT<QTab>* tabList();
} Qt::TabBar;
