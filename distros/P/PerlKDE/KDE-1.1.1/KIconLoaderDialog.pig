#include <kiconloaderdialog.h>

suicidal virtual class KIconLoaderDialog : virtual QDialog {
    KIconLoaderDialog(QWidget * = 0, const char * = 0);
    KIconLoaderDialog(KIconLoader *, QWidget * = 0, const char * = 0);
    virtual ~KIconLoaderDialog();
    int exec(QString);
    QPixmap selectIcon(QString &, const QString &);
    void setDir(const QStrList *);
protected:
    void dirChanged(const char *) slot;
    void filterChanged() slot;
    void init();
    void needReload() slot;
    void reject() slot;
    virtual void resizeEvent(QResizeEvent *);
} KDE::IconLoaderDialog;
