#include <qprogressbar.h>

suicidal virtual class QProgressBar : virtual QFrame {
    QProgressBar(QWidget * = 0, const char * = 0, WFlags = 0);
    QProgressBar(int, QWidget * = 0, const char * = 0, WFlags = 0);
    int progress() const;
    void reset() slot;
    void setProgress(int) slot;
    void setTotalSteps(int) slot;
    virtual void show();
    virtual QSize sizeHint() const;
    int totalSteps() const;
protected:
    virtual void drawContents(QPainter *);
    virtual bool setIndicator(QString &, int, int);
} Qt::ProgressBar;
