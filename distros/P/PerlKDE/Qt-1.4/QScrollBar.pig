#include <qscrollbar.h>

suicidal virtual class QScrollBar : virtual QWidget, virtual QRangeControl {
    enum Orientation { Horizontal, Vertical };
    QScrollBar(QWidget * = 0, const char * = 0);
    QScrollBar(QScrollBar::Orientation, QWidget * = 0, const char * = 0);
    QScrollBar(int, int, int, int, int, QScrollBar::Orientation, QWidget * = 0, const char * = 0);
    bool draggingSlider() const;
    QScrollBar::Orientation orientation() const;
    void setOrientation(QScrollBar::Orientation);
    virtual void setPalette(const QPalette &);
    void setTracking(bool);
    virtual QSize sizeHint() const;
    bool tracking() const;
protected:
    virtual void keyPressEvent(QKeyEvent *);
    virtual void mouseMoveEvent(QMouseEvent *);
    virtual void mousePressEvent(QMouseEvent *);
    virtual void mouseReleaseEvent(QMouseEvent *);
    void nextLine() signal;
    void nextPage() signal;
    virtual void paintEvent(QPaintEvent *);
    void prevLine() signal;
    void prevPage() signal;
    virtual void rangeChange();
    virtual void resizeEvent(QResizeEvent *);
    void sliderMoved(int) signal;
    void sliderPressed() signal;
    QRect sliderRect() const;
    void sliderReleased() signal;
    int sliderStart() const;
    virtual void stepChange();
    virtual void timerEvent(QTimerEvent *);
    virtual void valueChange();
    void valueChanged(int) signal;
} Qt::ScrollBar;
