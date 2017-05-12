#include <kdbtn.h>

suicidal virtual class KDirectionButton : virtual QButton {
    KDirectionButton(QWidget * = 0, const char * = 0);
    KDirectionButton(ArrowType, QWidget * = 0, const char * = 0);
    virtual ~KDirectionButton();
    ArrowType direction();
    void setDirection(ArrowType);
protected:
   virtual void drawButton(QPainter *);
} KDE::DirectionButton;
