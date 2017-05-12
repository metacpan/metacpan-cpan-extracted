#include <keditcl.h>

suicidal virtual class KIntLineEdit : virtual QLineEdit {
    KIntLineEdit(QWidget * = 0, const char * = 0);
    int getValue();
protected:
    virtual void keyPressEvent(QKeyEvent *);
} KDE::IntLineEdit;
