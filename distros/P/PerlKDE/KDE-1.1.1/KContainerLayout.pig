#include <kcontainer.h>

suicidal virtual class KContainerLayout : virtual QFrame {
    enum { Horizontal, Vertical };
    KContainerLayout(QWidget * = 0, const char * = 0, int = KContainerLayout::Horizontal, bool = FALSE, int = 5, WFlags = 0, bool = TRUE);
    virtual ~KContainerLayout();
    int endOffset() const;
    int getNumberOfWidgets() const;
    bool homogeneos() const;
    int orientation() const;
    int packEnd(QWidget *, bool = FALSE, bool = FALSE, int = 1);
    int packStart(QWidget *, bool = FALSE, bool = FALSE, int = 1);
    void setEndOffset(int);
    void setHomogeneos(bool);
    void setOrientation(int);
    void setSpacing(int);
    void setStartOffset(int);
    void sizeToFit();
    int spacing() const;
    int startOffset() const;
protected:
    void calculateSizeHint();
    virtual bool eventFilter(QObject *, QEvent *);
    bool horizontal() const;
    QSize idealSizeOfWidget(KContainerLayoutItem *);
    int numberOfWidgetsWithExpand();
    void recalcLayout();
    void repositionWidgets();
    virtual void resizeEvent(QResizeEvent *);
    virtual QSize sizeHint() const;
    QSize sizeOfLargerWidget();
    QSize widgetSize(KContainerLayoutItem *);
} KDE::ContainerLayout;
