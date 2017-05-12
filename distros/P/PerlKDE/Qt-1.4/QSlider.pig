#include <qslider.h>

suicidal virtual class QSlider : virtual QWidget, virtual QRangeControl {
    enum Orientation { Horizontal, Vertical };
    enum TickSetting {
	NoMarks,
	Above,
	Left,
	Below,
	Right,
	Both
    };
    QSlider(QWidget * = 0, const char * = 0);
    QSlider(QSlider::Orientation, QWidget * = 0, const char * = 0);
    QSlider(int, int, int, int, QSlider::Orientation, QWidget * = 0, const char * = 0);
    void addStep() slot;
    QSlider::Orientation orientation() const;
    void setOrientation(QSlider::Orientation);
    virtual void setPalette(const QPalette &);
    void setTickInterval(int);
    void setTickmarks(QSlider::TickSetting);
    void setTracking(bool);
    void setValue(int) slot;
    virtual QSize sizeHint() const;
    QRect sliderRect() const;
    void subtractStep() slot;
    int tickInterval() const;
    QSlider::TickSetting tickmarks() const;
    bool tracking() const;
protected:
    void drawTicks(QPainter *, int, int, int = 1) const;
    void drawWinGroove(QPainter *, QCOORD);
    virtual void focusInEvent(QFocusEvent *);
    virtual void keyPressEvent(QKeyEvent *);
    virtual void mouseMoveEvent(QMouseEvent *);
    virtual void mousePressEvent(QMouseEvent *);
    virtual void mouseReleaseEvent(QMouseEvent *);
    virtual void paintEvent(QPaintEvent *);
    virtual void paintSlider(QPainter *, const QRect &);
    virtual void rangeChange();
    virtual void resizeEvent(QResizeEvent *);
    void sliderMoved(int) signal;
    void sliderPressed() signal;
    void sliderReleased() signal;
    virtual int thickness() const;
    virtual void valueChange();
    void valueChanged(int) signal;
} Qt::Slider;
