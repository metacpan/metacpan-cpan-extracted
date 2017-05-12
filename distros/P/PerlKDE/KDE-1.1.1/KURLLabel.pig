#include <kurllabel.h>

enum TextAlignment { Bottom, Left, Top, Right };

suicidal virtual class KURLLabel : virtual QLabel {
    KURLLabel(QWidget * = 0, const char * = 0, WFlags = 0);
    virtual ~KURLLabel();
    const QPixmap *pixmap() const;
    void setAltPixmap(const QPixmap &) slot;
    void setBackgroundColor(const QColor &) slot;
    void setBackgroundColor(const char *) slot;
    void setFloat(bool = true) slot;
    virtual void setFont(const QFont &) slot;
    void setGlow(bool = true) slot;
    void setHighlightedColor(const QColor &) slot;
    void setHighlightedColor(const char *) slot;
    void setMovie(const QMovie &) slot;
    void setPixmap(const QPixmap &) slot;
    void setSelectedColor(const QColor &) slot;
    void setSelectedColor(const char *) slot;
    void setText(const char *) slot;
    void setTextAlignment(TextAlignment);
    void setTipText(const char *) slot;
    void setTransparentMode(bool);
    void setUnderline(bool = true) slot;
    void setURL(const char *) slot;
    void setUseCursor(bool, const QCursor * = 0) slot;
    void setUseTips(bool = true) slot;
    virtual QSize sizeHint() const;
    const char *text() const;
    const char *url() const;
protected:
    virtual void drawContents(QPainter *);
    void enteredURL() signal;
    void enteredURL(const char *) signal;
    virtual void leaveEvent(QEvent *);
    void leftClickedURL(const char *) signal;
    void leftURL() signal;
    void leftURL(const char *) signal;
    void m_enterEvent();
    void m_leaveEvent();
    void middleClickedURL(const char *) signal;
    virtual void mouseMoveEvent(QMouseEvent *);
    virtual void mousePressEvent(QMouseEvent *);
    virtual void paintEvent(QPaintEvent *);
    void rightClickedURL() signal;
    void rightClickedURL(const char *) signal;
    virtual void timerEvent(QTimerEvent *);
} KDE::URLLabel;
