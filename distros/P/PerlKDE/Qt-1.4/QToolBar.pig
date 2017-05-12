#include <qtoolbar.h>

suicidal virtual class QToolBar : virtual QWidget {
    enum Orientation { Horizontal, Vertical };
    QToolBar(const char *, QMainWindow *, QMainWindow::ToolBarDock = QMainWindow::Top, bool = FALSE, const char * = 0);
    QToolBar(const char *, QMainWindow *, QWidget *, bool = FALSE, const char * = 0, WFlags = 0);
    QToolBar(QMainWindow * = 0, const char * = 0);
    virtual ~QToolBar();
    void addSeparator();
    QMainWindow *mainWindow();
    QToolBar::Orientation orientation() const;
    virtual void setOrientation(QToolBar::Orientation);
    void setStretchableWidget(QWidget *);
    virtual void show();
protected:
    virtual void paintEvent(QPaintEvent *);
} Qt::ToolBar;
