#include <klined.h>

suicidal virtual class KLined : virtual QLineEdit {
    KLined(QWidget * = 0, const char * = 0);
    virtual ~KLined();
    void cursorAtEnd();
protected:
    void completion() signal;
    virtual bool eventFilter(QObject *, QEvent *);
    void rotation() signal;
} KDE::Lined;
