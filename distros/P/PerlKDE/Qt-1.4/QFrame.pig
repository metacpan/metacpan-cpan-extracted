#include <qframe.h>

suicidal virtual class QFrame : virtual QWidget {
    enum {
	NoFrame,
	Box,
	Panel,
	WinPanel,
	HLine,
	VLine,
	MShape,
	Plain,
	Raised,
	Sunken,
	MShadow
    };
    QFrame(QWidget * = 0, const char * = 0, WFlags = 0, bool = TRUE);
    QRect contentsRect() const;
    QRect frameRect() const;
    int frameShadow() const;
    int frameShape() const;
    int frameStyle() const;
    int frameWidth() const;
    bool lineShapesOk() const;
    int lineWidth() const;
    int margin() const;
    int midLineWidth() const;
    void setFrameStyle(int);
    void setLineWidth(int);
    void setMargin(int);
    void setMidLineWidth(int);
    virtual QSize sizeHint() const;
protected:
    virtual void drawContents(QPainter *);
    virtual void drawFrame(QPainter *);
    virtual void frameChanged();
    virtual void paintEvent(QPaintEvent *);
    virtual void resizeEvent(QResizeEvent *);
    void setFrameRect(const QRect &);
} Qt::Frame;
