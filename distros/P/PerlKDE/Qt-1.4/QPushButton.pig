#include <qpushbutton.h>

suicidal virtual class QPushButton : virtual QButton {
    QPushButton(QWidget * = 0, const char * = 0);
    QPushButton(const char *, QWidget * = 0, const char * = 0);
    bool autoDefault() const;
    bool isDefault() const;
    bool isMenuButton() const;
    void move(const QPoint &);
    virtual void move(int, int);
    void resize(const QSize &);
    virtual void resize(int, int);
    void setAutoDefault(bool);
    void setDefault(bool);
    void setGeometry(const QRect &);
    virtual void setGeometry(int, int, int, int);
    void setIsMenuButton(bool);
    void setOn(bool) slot;
    void setToggleButton(bool);
    virtual QSize sizeHint() const;
    void toggle() slot;
protected:
    virtual void drawButton(QPainter *);
    virtual void drawButtonLabel(QPainter *);
    virtual void focusInEvent(QFocusEvent *);
} Qt::PushButton;
