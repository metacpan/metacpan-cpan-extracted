#include <qlabel.h>

suicidal virtual class QLabel : virtual QFrame {
    QLabel(QWidget * = 0, const char * = 0, WFlags = 0);
    QLabel(const char *, QWidget * = 0, const char * = 0, WFlags = 0);
    QLabel(QWidget *, const char *, QWidget *, const char *, WFlags = 0);
    virtual ~QLabel();
    int alignment() const;
    bool autoResize() const;
    QWidget *buddy() const;
    void clear() slot;
    int margin() const;
    QMovie *movie() const;
    QPixmap *pixmap() const;
    void setAlignment(int);
    void setAutoResize(bool);
    void setBuddy(QWidget *);
    void setMargin(int);
    void setMovie(const QMovie &) slot;
    void setNum(int) slot;
    void setNum(double) slot;
    void setPixmap(const QPixmap &) slot;
    void setText(const char *) slot;
    virtual QSize sizeHint() const;
    const char *text() const;
protected:
    virtual void drawContents(QPainter *);
} Qt::Label;
