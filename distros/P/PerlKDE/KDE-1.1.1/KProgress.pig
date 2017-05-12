#include <kprogress.h>

suicidal virtual class KProgress : virtual QFrame, virtual QRangeControl {
    enum Orientation { Horizontal, Vertical };
    enum BarStyle { Solid, Blocked };

    KProgress(QWidget * = 0, const char * = 0);
    KProgress(KProgress::Orientation, QWidget * = 0, const char * = 0);
    KProgress(int, int, int, KProgress::Orientation, QWidget * = 0, const char * = 0);
    virtual ~KProgress();
    void advance(int) slot;
    const QColor &barColor() const;
    const QPixmap *barPixmap() const;
    KProgress::BarStyle barStyle() const;
    KProgress::Orientation orientation() const;
    void setBarColor(const QColor &);
    void setBarPixmap(const QPixmap &);
    void setBarStyle(KProgress::BarStyle);
    void setOrientation(KProgress::Orientation);
    void setTextEnabled(bool);
    void setValue(int) slot;
    virtual QSize sizeHint() const;
    bool textEnabled() const;
protected:
    virtual void drawContents(QPainter *);
    virtual void paletteChange(const QPalette &);
    void percentageChanged(int) signal;
    virtual void rangeChange();
    virtual void styleChange(GUIStyle);
    virtual void valueChange();
} KDE::Progress;
