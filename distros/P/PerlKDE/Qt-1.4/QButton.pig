#include <qbutton.h>

suicidal virtual class QButton : virtual QWidget {
    QButton(QWidget * = 0, const char * = 0);
    virtual ~QButton();
    int accel() const;
    void animateClick() slot;
    bool autoRepeat() const;
    bool autoResize() const;
    bool isDown() const;
    bool isOn() const;
    bool isToggleButton() const;
    const QPixmap *pixmap() const;
    void setAccel(int);
    void setAutoRepeat(bool);
    void setAutoResize(bool);
    void setDown(bool);
    void setPixmap(const QPixmap &);
    void setText(const char *);
    const char *text() const;
    void toggle() slot;
protected:
    void clicked() signal;
    virtual void drawButton(QPainter *);
    virtual void drawButtonLabel(QPainter *);
    virtual void enabledChange(bool);
    virtual void focusInEvent(QFocusEvent *);
    virtual void focusOutEvent(QFocusEvent *);
    virtual bool hitButton(const QPoint &) const;
    virtual void keyPressEvent(QKeyEvent *);
    virtual void mouseMoveEvent(QMouseEvent *);
    virtual void mousePressEvent(QMouseEvent *);
    virtual void mouseReleaseEvent(QMouseEvent *);
    virtual void paintEvent(QPaintEvent *);
    void pressed() signal;
    void released() signal;
    void setDown(bool);
    void setOn(bool);
    void setToggleButton(bool);
    void toggled(bool) signal;
} Qt::Button;
