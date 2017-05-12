#include <kledlamp.h>

suicidal virtual class KLedLamp : virtual QFrame {
    enum State { On, Off };
    KLedLamp(QWidget * = 0);
    void off() slot;
    void on() slot;
    void setState(KLedLamp::State);
    KLedLamp::State state() const;
    void toggle() slot;
    void toggleState();
protected:
    virtual void drawContents(QPainter *);
} KDE::LedLamp;
