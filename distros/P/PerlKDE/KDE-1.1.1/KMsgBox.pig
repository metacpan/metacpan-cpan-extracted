#include <kmsgbox.h>

suicidal virtual class KMsgBox : virtual QDialog {
    enum IconStyle { INFORMATION, EXCLAMATION, STOP, QUESTION };
    enum DefaultButton { DB_FIRST, DB_SECOND, DB_THIRD, DB_FOURTH };

    KMsgBox(QWidget * = 0, const char * = 0, const char * = 0, int = KMsgBox::INFORMATION, const char * = 0, const char * = 0, const char * = 0, const char * = 0);
    virtual ~KMsgBox();
    void b1Pressed() slot;
    void b2Pressed() slot;
    void b3Pressed() slot;
    void b4Pressed() slot;
    static int message(QWidget * = 0, const char * = 0, const char * = 0, int = 0, const char * = 0);
    static int yesNo(QWidget * = 0, const char * = 0, const char * = 0, int = 0, const char * = 0, const char * = 0);
    static int yesNoCancel(QWidget * = 0, const char * = 0, const char * = 0, int = 0, const char * = 0, const char * = 0, const char * = 0);
} KDE::MsgBox;
