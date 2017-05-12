#include <qpopupmenu.h>

suicidal virtual class QPopupMenu : virtual QTableView, virtual QMenuData {
    QPopupMenu(QWidget * = 0, const char * = 0);
    virtual ~QPopupMenu();
    int exec();
    int exec(const QPoint &, int = 0);
    virtual void hide();
    bool isCheckable() const;
    void popup(const QPoint &, int = 0);
    void setActiveItem(int);
    void setCheckable(bool);
    virtual void setFont(const QFont &);
    virtual void show();
    virtual void updateItem(int);
protected:
    void aboutToShow() signal;
    void activated(int) signal;
    void activatedRedirect(int) signal;
    virtual int cellHeight(int);
    virtual int cellWidth(int);
    void highlighted(int) signal;
    void highlightedRedirect(int) signal;
    virtual void keyPressEvent(QKeyEvent *);
    virtual void mouseMoveEvent(QMouseEvent *);
    virtual void mousePressEvent(QMouseEvent *);
    virtual void mouseReleaseEvent(QMouseEvent *);
    virtual void paintCell(QPainter *, int, int);
    virtual void paintEvent(QPaintEvent *);
    virtual void timerEvent(QTimerEvent *);
} Qt::PopupMenu;
