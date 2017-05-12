#include <qgroupbox.h>

suicidal virtual class QGroupBox : virtual QFrame {
    QGroupBox(QWidget * = 0, const char * = 0);
    QGroupBox(const char *, QWidget * = 0, const char * = 0);
    int alignment() const;
    void setAlignment(int);
    void setTitle(const char *);
    const char *title() const;
protected:
    virtual void paintEvent(QPaintEvent *);
} Qt::GroupBox;
