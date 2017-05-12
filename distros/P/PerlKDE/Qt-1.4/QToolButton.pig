#include <qtoolbutton.h>

suicidal virtual class QToolButton : virtual QButton {
    QToolButton(QWidget * = 0, const char * = 0);

; In perl, it's receiver(5). In any other language, it should be receiver(4)

    QToolButton(const QPixmap &, const char *, const char *, QObject *{receiver(5)}, const char *{member(4)}, QToolBar *, const char * = 0);
    QToolButton(QIconSet, const char *, const char *, QObject *{receiver(5)}, const char *{member(4)}, QToolBar *, const char * = 0);
    virtual ~QToolButton();
    QIconSet iconSet() const;
    void setIconSet(const QIconSet &);
    void setOn(bool) slot;
    virtual void setTextLabel(const char *, bool = TRUE) slot;
    void setToggleButton(bool) slot;
    virtual void setUsesBigPixmap(bool) slot;
    virtual void setUsesTextLabel(bool) slot;
    virtual QSize sizeHint() const;
    const char *textLabel() const;
    void toggle() slot;
    bool usesBigPixmap() const;
    bool usesTextLabel() const;
protected:
    virtual void drawButton(QPainter *);
    virtual void drawButtonLabel(QPainter *);
    virtual void enterEvent(QEvent *);
    virtual void leaveEvent(QEvent *);
    bool uses3D() const;
} Qt::ToolButton;
