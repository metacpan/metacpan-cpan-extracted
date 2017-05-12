#include <kcolorbtn.h>

suicidal virtual class KColorButton : virtual QPushButton {
    KColorButton(QWidget *, const char * = 0L);
    KColorButton(const QColor &, QWidget *, const char * = 0L);
    virtual ~KColorButton();
    const QColor color() const;
    void setColor(const QColor &);
protected:
    void changed(const QColor &) signal;
    virtual void drawButtonLabel(QPainter *);
    void slotClicked() slot;
} KDE::ColorButton;
