#include <keditcl.h>

suicidal virtual class KEdSrch : virtual QDialog {
    KEdSrch(QWidget * = 0, const char * = 0);
    bool case_sensitive();
    void done_slot() slot;
    bool get_direction();
    QString getText();
    void ok_slot() slot;
    void setText(QString);
protected:
    virtual void focusInEvent(QFocusEvent *);
    virtual void resizeEvent(QResizeEvent *);
    void search_signal() signal;
    void search_done_signal() signal;
} KDE::EdSrch;
