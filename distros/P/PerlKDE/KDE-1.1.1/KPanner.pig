#include <kpanner.h>

suicidal virtual class KPanner : virtual QWidget {
    enum { O_VERTICAL, O_HORIZONTAL, U_PERCENT, U_ABSOLUTE };
    KPanner(QWidget * = 0, const char * = 0, unsigned = 0, int = 0);
    virtual ~KPanner();
    QWidget *child0();
    QWidget *child1();
    int getAbsSeparator();
    int getMaxValue();
    int getSeparator();
    void setAbsSeparator(int);
    void setLimits(int, int);
    void setSeparator(int);
} KDE::Panner;
