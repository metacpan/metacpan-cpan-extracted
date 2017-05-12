#include <qheader.h>

suicidal virtual class QHeader : virtual QTableView {
    enum Orientation {
	Horizontal,
	Vertical
    };
    QHeader(QWidget * = 0, const char * = 0);
    QHeader(int, QWidget * = 0, const char * = 0);
    virtual ~QHeader();
    int addLabel(const char *, int = -1);
    int cellAt(int) const;
    int cellPos(int) const;
    int cellSize(int) const;
    int count() const;
    const char *label(int);
    int mapToActual(int) const;
    int mapToLogical(int) const;
    int offset() const;
    QHeader::Orientation orientation() const;
    void setCellSize(int, int);
    void setClickEnabled(bool, int = -1);
    void setLabel(int, const char *, int = -1);
    void setMovingEnabled(bool);
    void setOffset(int) slot;
    void setOrientation(QHeader::Orientation);
    void setResizeEnabled(bool, int = -1);
    void setTracking(bool);
    virtual QSize sizeHint() const;
    bool tracking() const;
protected:
    virtual int cellHeight(int);
    virtual int cellWidth(int);
    virtual void mouseMoveEvent(QMouseEvent *);
    virtual void mousePressEvent(QMouseEvent *);
    virtual void mouseReleaseEvent(QMouseEvent *);
    void moved(int, int) signal;
    virtual void paintCell(QPainter *, int, int);
    virtual void resizeEvent(QResizeEvent *);
    void sectionClicked(int) signal;
    virtual void setupPainter(QPainter *);
    void sizeChange(int, int, int) signal;
    QRect sRect(int);
} Qt::Header;
