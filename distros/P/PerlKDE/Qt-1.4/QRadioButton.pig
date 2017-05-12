#include <qradiobutton.h>

suicidal virtual class QRadioButton : virtual QButton {
    QRadioButton(QWidget * = 0, const char * = 0);
    QRadioButton(const char *, QWidget * = 0, const char * = 0);
    bool isChecked() const;
    void setChecked(bool);
    virtual QSize sizeHint() const;
protected:
    virtual void drawButton(QPainter *);
    virtual void drawButtonLabel(QPainter *);
    virtual bool hitButton(const QPoint &) const;
    virtual void keyPressEvent(QKeyEvent *);
    virtual void mouseReleaseEvent(QMouseEvent *);
} Qt::RadioButton;
