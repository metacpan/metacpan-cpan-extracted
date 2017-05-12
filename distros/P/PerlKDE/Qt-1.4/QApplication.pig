#include <qapplication.h>

suicidal virtual class QApplication : virtual QObject {
    enum ColorSpec {
	CustomColor, ManyColor, NormalColor, PrivateColor, TrueColor
    };

    QApplication(int &{@argc(1)}, char **{argv});
    virtual ~QApplication();
    static QWidget *activeModalWidget();
    static QWidget *activePopupWidget();
    static QWidgetList *allWidgets();
    static void beep();
    static QClipboard *clipboard();
    static bool closingDown();
    static int colorSpec();
    static QWidget *desktop();
    static int doubleClickInterval();
    int enter_loop();
    int exec();
    static void exit(int = 0);
    void exit_loop();
    static void flushX();
    QWidget *focusWidget() const;
    static QFont *font();
    static QFontMetrics fontMetrics();
    static bool hasGlobalMouseTracking();
    QWidget *mainWidget() const;
    virtual bool notify(QObject *, QEvent *);
    static QCursor *overrideCursor();
    static QPalette *palette();
    static void postEvent(QObject *, QEvent *);
    void processEvents();
    void processEvents(int);
    void processOneEvent();
    void quit() slot;
    static void restoreOverrideCursor();
    static bool sendEvent(QObject *, QEvent *);
    static void sendPostedEvents(QObject *, int);
    static void setColorSpec(int);
    static void setDoubleClickInterval(int);
    static void setFont(const QFont &, bool = FALSE);
    static void setGlobalMouseTracking(bool);
    void setMainWidget(QWidget *);
    static void setOverrideCursor(const QCursor &, bool = FALSE);
    static void setPalette(const QPalette &, bool = FALSE);
    static void setStyle(GUIStyle);
    static void setWinStyleHighlightColor(const QColor &);
    static bool startingUp();
    static GUIStyle style();
    static void syncX();
    static QWidgetList *topLevelWidgets();
    static QWidget *widgetAt(const QPoint &, bool = FALSE);
    static QWidget *widgetAt(int, int, bool = FALSE);
    static const QColor &winStyleHighlightColor();
protected:
    void lastWindowClosed() signal;
} Qt::Application;
