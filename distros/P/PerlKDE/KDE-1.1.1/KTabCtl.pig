#include <ktabctl.h>

suicidal virtual class KTabCtl : virtual QWidget {
    KTabCtl(QWidget * = 0, const char * = 0);
    virtual ~KTabCtl();
    void addTab(QWidget *, const char *);
    bool isTabEnabled(const char *);
    void setBorder(bool);
    virtual void setFont(const QFont &);
    void setShape(QTabBar::Shape);
    void setTabEnabled(const char *, bool);
    void setTabFont(const QFont &);
    virtual void show();
protected:
    QRect getChildRect() const;
    virtual void paintEvent(QPaintEvent *);
    virtual void resizeEvent(QResizeEvent *);
    void setSizes();
    void showTab(int) slot;
    void tabSelected(int) signal;
} KDE::TabCtl;
