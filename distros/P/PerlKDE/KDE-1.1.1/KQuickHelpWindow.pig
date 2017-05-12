#include <kquickhelp.h>

suicidal virtual class KQuickHelpWindow : virtual QFrame {
    KQuickHelpWindow();
    virtual ~KQuickHelpWindow();
    virtual void hide();
    virtual void keyPressEvent(QKeyEvent *);
    virtual void mouseMoveEvent(QMouseEvent *);
    virtual void mousePressEvent(QMouseEvent *);
    void newText();
    void paint(QPainter *, int &, int &);
    virtual void paintEvent(QPaintEvent *);
    void popup(QString, int, int);
    virtual void show();
protected:
    void hyperlink(QString) signal;
} KDE::QuickHelpWindow;
