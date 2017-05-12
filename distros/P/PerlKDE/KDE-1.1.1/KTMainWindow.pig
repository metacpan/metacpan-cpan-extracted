#include <ktmainwindow.h>

suicidal virtual class KTMainWindow : virtual QWidget {
    KTMainWindow(const char * = 0L);
    virtual ~KTMainWindow();
    int addToolBar(KToolBar *, int = -1);
    static bool canBeRestored(int);
    static const QString classNameOfToplevel(int);
    static void deleteAll();
    void enableStatusBar(KStatusBar::BarStatus = KStatusBar::Toggle);
    void enableToolBar(KToolBar::BarStatus = KToolBar::Toggle, int = 0);
    bool hasMenuBar();
    bool hasStatusBar();
    bool hasToolBar(int = 0);
    KMenuBar *menuBar();
    bool restore(int);
    void setFrameBorderWidth(int);
    void setMenu(KMenuBar *);
    void setStatusBar(KStatusBar *);
    void setUnsavedData(bool);
    void setView(QWidget *, bool = TRUE);
    virtual void show();
    KStatusBar *statusBar();
    KToolBar *toolBar(int = 0);
protected:
    virtual void closeEvent(QCloseEvent *);
    virtual void focusInEvent(QFocusEvent *);
    virtual void focusOutEvent(QFocusEvent *);
    virtual bool queryClose();
    virtual bool queryExit();
    virtual void readProperties(KConfig *);
    virtual void resizeEvent(QResizeEvent *);
    virtual void saveData(KConfig *);
    virtual void saveProperties(KConfig *);
    virtual void updateRects() slot;
} KDE::TMainWindow;
