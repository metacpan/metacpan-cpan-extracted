#include <kwizard.h>

suicidal virtual class KDialog : virtual QDialog {
    KDialog(QWidget * = 0, const char * = 0, bool = false, WFlags = 0);
protected:
    virtual void keyPressEvent(QKeyEvent*);
} KDE::Dialog;
