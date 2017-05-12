#include <qmenubar.h>

suicidal virtual class QMenuBar : virtual QFrame, virtual QMenuData {
    enum Separator { Never, InWindowsStyle };
    QMenuBar(QWidget * = 0, const char * = 0);
    virtual ~QMenuBar();
    virtual bool eventFilter(QObject *, QEvent *);
    virtual int heightForWidth(int) const;
    virtual void hide();
    void setSeparator(QMenuBar::Separator);
    QMenuBar::Separator separator() const;
    virtual void show();
    virtual void updateItem(int);
protected:
    void activated(int) signal;
    virtual void drawContents(QPainter *);
    virtual void fontChange(const QFont &);
    void highlighted(int) signal;
    virtual void keyPressEvent(QKeyEvent *);
    virtual void leaveEvent(QEvent *);
    virtual void menuContentsChanged();
    virtual void menuStateChanged();
    virtual void mouseMoveEvent(QMouseEvent *);
    virtual void mousePressEvent(QMouseEvent *);
    virtual void mouseReleaseEvent(QMouseEvent *);
    virtual void resizeEvent(QResizeEvent *);
} Qt::MenuBar;
