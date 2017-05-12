#include <kcolordlg.h>

suicidal virtual class KColorDialog : virtual QDialog {
    KColorDialog(QWidget * = 0L, const char * = 0L, bool = FALSE);
    QColor color();
    static int getColor(QColor &);
    void setColor(const QColor &);
    void slotOkPressed() slot;
protected:
    void colorSelected(const QColor &) signal;
} KDE::ColorDialog;
