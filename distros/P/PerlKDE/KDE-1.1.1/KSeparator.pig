#include <kseparator.h>

suicidal virtual class KSeparator : virtual QFrame {
    KSeparator(QWidget * = 0, const char * = 0, WFlags = 0);
    KSeparator(int, QWidget * = 0, const char * = 0, WFlags = 0);
    int orientation() const;
    void setOrientation(int);
    virtual QSize sizeHint() const;
} KDE::Separator;
