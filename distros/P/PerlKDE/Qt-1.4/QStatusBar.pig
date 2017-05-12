#include <qstatusbar.h>

suicidal virtual class QStatusBar : virtual QWidget {
    QStatusBar(QWidget * = 0, const char * = 0);
    virtual ~QStatusBar();
    void addWidget(QWidget *, int, bool = FALSE);
    void clear() slot;
    void message(const char *) slot;
    void message(const char *, int) slot;
    void removeWidget(QWidget *);
protected:
    void hideOrShow();
    virtual void paintEvent(QPaintEvent *);
    void reformat();
} Qt::StatusBar;
