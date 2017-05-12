#include <kintegerline.h>

enum KEditLineType { KEditTypeOct, KEditTypeDec, KEditTypeHex };

suicidal virtual class KIntegerLine : virtual KRestrictedLine {
    KIntegerLine(QWidget * = 0, const char * = 0, KEditLineType = KEditTypeDec);
    virtual ~KIntegerLine();
    KEditLineType getType();
    void setValue(int);
    int value();
protected:
    virtual void keyPressEvent(QKeyEvent *);
    void valueChanged(int) signal;
} KDE::IntegerLine;
