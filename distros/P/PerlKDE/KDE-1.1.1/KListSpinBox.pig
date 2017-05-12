#include <kspinbox.h>

suicidal virtual class KListSpinBox : virtual KSpinBox {
    KListSpinBox(QStrList *{qt_leak_QStrList_ptr}, QWidget * = 0, const char * = 0, int = AlignLeft);
    virtual ~KListSpinBox();
    uint getIndex();
    void setIndex(uint);
    void slotDecrease() slot;
    void slotIncrease() slot;
} KDE::ListSpinBox;
