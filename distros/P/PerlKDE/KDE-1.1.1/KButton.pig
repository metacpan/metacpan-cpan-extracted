#include <kbutton.h>

suicidal virtual class KButton : virtual QButton {
    KButton(QWidget * = 0L, const char * = 0L);
    virtual ~KButton();
protected:
    virtual void drawButton(QPainter *);
    virtual void drawButtonLabel(QPainter *);
    virtual void enterEvent(QEvent *);
    virtual void leaveEvent(QEvent *);
    void paint(QPainter *);
} KDE::Button;
