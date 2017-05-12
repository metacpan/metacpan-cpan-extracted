#include <kcombo.h>

suicidal virtual class KCombo : virtual QComboBox {
    KCombo(QWidget * = 0, const char * = 0, WFlags = 0);
    KCombo(bool, QWidget * = 0, const char * = 0, WFlags = 0);
    virtual ~KCombo();
    void cursorAtEnd();
    int labelFlags() const;
    void setCompletion(bool);
    void setLabelFlags(int);
    void setText(const char *);
} KDE::Combo;
