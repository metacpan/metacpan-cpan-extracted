#include <qsplitter.h>

suicidal virtual class QSplitter : virtual QFrame {
    enum Orientation { Horizontal, Vertical };
    enum ResizeMode { Stretch, KeepSize };
    QSplitter(QWidget * = 0, const char * = 0);
    QSplitter(QSplitter::Orientation, QWidget * = 0, const char * = 0);
    virtual ~QSplitter();
    virtual bool event(QEvent *);
    void moveToFirst(QWidget *);
    void moveToLast(QWidget *);
    bool opaqueResize() const;
    QSplitter::Orientation orientation() const;
    void refresh();
    void setOpaqueResize(bool = TRUE);
    void setOrientation(QSplitter::Orientation);
    void setResizeMode(QWidget *, QSplitter::ResizeMode);
protected:
    int adjustPos(int);
    void childInsertEvent(QChildEvent *);
    void childRemoveEvent(QChildEvent *);
    virtual void drawSplitter(QPainter *, QCOORD, QCOORD, QCOORD, QCOORD);
    void layoutHintEvent(QEvent *);
    void moveSplitter(QCOORD);
    void resizeEvent(QResizeEvent *);
    void setRubberband(int);
} Qt::Splitter;
