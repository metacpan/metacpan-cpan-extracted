#include <krestrictedline.h>

suicidal virtual class KRestrictedLine : virtual QLineEdit {
    KRestrictedLine(QWidget * = 0, const char * = 0, const char * = 0);
    virtual ~KRestrictedLine();
    void setValidChars(const char *);
protected:
    void invalidChar(int) signal;
    virtual void keyPressEvent(QKeyEvent *);
} KDE::RestrictedLine;
