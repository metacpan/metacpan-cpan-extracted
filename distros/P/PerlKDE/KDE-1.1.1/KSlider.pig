#include <kslider.h>

suicidal virtual class KSlider : virtual QSlider {
    KSlider(QWidget * = 0L, const char * = 0L);
    KSlider(QSlider::Orientation, QWidget * = 0L, const char * = 0L);
    KSlider(int, int, int, int, QSlider::Orientation, QWidget * = 0L, const char * = 0L);
    virtual QSize sizeHint() const;
protected:
    virtual void backgroundColorChange(const QPalette &);
    virtual void focusInEvent(QFocusEvent *);
    virtual void focusOutEvent(QFocusEvent *);
    virtual void paintSlider(QPainter *, const QRect &);
    virtual void paletteChange(const QPalette &);
    virtual void rangeChange();
    void sliderMoved(int) signal;
    void sliderPressed() signal;
    void sliderReleased() signal;
    virtual void valueChange();
    void valueChanged(int) signal;
} KDE::Slider;
