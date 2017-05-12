#include <kled.h>

suicidal virtual class KLed : virtual QWidget {
    enum Color { yellow, orange, red, green, blue };
    enum State { Off , On };
    enum Look { flat, round, sunken };
    KLed(KLed::Color, QWidget * = 0, const char * = 0);
    KLed(KLed::Color, KLed::State, KLed::Look, QWidget * = 0, const char * = 0);
    KLed::Color getColor() const;
    KLed::Look getLook() const;
    QRgb getRgbColor() const;
    KLed::State getState() const;
    void off() slot;
    void on() slot;
    void setColor(KLed::Color);
    void setLook(KLed::Look);
    void setState(KLed::State);
    void toggle() slot;
    void toggleState();
protected:
    virtual void paintEvent(QPaintEvent *);
} KDE::Led;
