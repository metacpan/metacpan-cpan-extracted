#include <qprintdialog.h>

suicidal virtual class QPrintDialog : virtual QDialog {
    QPrintDialog(QPrinter *, QWidget * = 0, const char * = 0);
    virtual ~QPrintDialog();
    static bool getPrinterSetup(QPrinter *);
    QPrinter *printer() const;
    void setPrinter(QPrinter *, bool = FALSE);
} Qt::PrintDialog;
