#include <qmainwindow.h>

suicidal virtual class QMainWindow : virtual QWidget {
    enum ToolBarDock {
	Unmanaged,
	TornOff,
	Top,
	Bottom,
	Right,
	Left
    };
    QMainWindow(QWidget * = 0, const char * = 0, WFlags = 0);
    virtual ~QMainWindow();
    void addToolBar(QToolBar *, const char *, QMainWindow::ToolBarDock = QMainWindow::Top, bool = FALSE);
    QWidget *centralWidget() const;
    virtual bool eventFilter(QObject *, QEvent *);
    bool isDockEnabled(QMainWindow::ToolBarDock) const;
    QMenuBar *menuBar() const;
    void removeToolBar(QToolBar *);
    bool rightJustification() const;
    virtual void setCentralWidget(QWidget *);
    void setDockEnabled(QMainWindow::ToolBarDock, bool);
    void setRightJustification(bool) slot;
    void setUsesBigPixmaps(bool) slot;
    virtual void show();
    QStatusBar *statusBar() const;
    QToolTipGroup *toolTipGroup() const;
    bool usesBigPixmaps() const;
protected:
    virtual bool event(QEvent *);
    virtual void paintEvent(QPaintEvent *);
    void pixmapSizeChanged(bool) signal;
    void setUpLayout() slot;
} Qt::MainWindow;
