#include <kfontdialog.h>

;suicidal virtual class KFontDialog : virtual QDialog {
;    KFontDialog(QWidget * = 0L, const char * = 0L, bool = FALSE, const QStrList * = 0L);
;    QFont font();
;    virtual void setFont(const QFont &);
;protected:
;    void fontSelected(const QFont &) signal;

namespace KFontDialog {
    static int getFont(QFont &);
    static int getFontAndText(QFont &, QString &);
    static QString getXLFD(const QFont &);
} KDE::FontDialog;
