#include <knewpanner.h>

suicidal virtual class KNewPanner : virtual QWidget {
    enum Orientation { Vertical, Horizontal };
    enum Units { Percent, Absolute };
    KNewPanner(QWidget * = 0, const char * = 0, KNewPanner::Orientation = KNewPanner::Vertical, KNewPanner::Units = KNewPanner::Percent, int = 50);
    virtual ~KNewPanner();
    int absSeparatorPos();
    void activate(QWidget *, QWidget *);
    void deactivate();
    int separatorPos();
    void setAbsSeparatorPos(int, bool = true);
    void setLabels(const char *, const char *);
    void setSeparatorPos(int);
    void setUnits(KNewPanner::Units);
    void showLabels(bool);
    KNewPanner::Units units();
protected:
    int checkValue(int);
    virtual bool eventFilter(QObject *, QEvent *);
    virtual void resizeEvent(QResizeEvent *);
} KDE::NewPanner;
