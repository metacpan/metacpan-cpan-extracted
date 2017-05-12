#include <keditcl.h>

suicidal virtual class KEdReplace : virtual QDialog {
    KEdReplace(QWidget * = 0, const char * = 0);
    bool case_sensitive();
    void done_slot() slot;
    bool get_direction();
    QString getText();
    QString getReplaceText();
    void ok_slot() slot;
    void replace_all_slot() slot;
    void replace_slot() slot;
    void setText(QString);
protected:
    void find_signal() signal;
    virtual void focusInEvent(QFocusEvent *);
    void replace_all_signal() signal;
    void replace_done_signal() signal;
    void replace_signal() signal;
    virtual void resizeEvent(QResizeEvent *);
} KDE::EdReplace;
