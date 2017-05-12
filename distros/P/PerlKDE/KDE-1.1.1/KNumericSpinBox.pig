#include <kspinbox.h>

suicidal virtual class KNumericSpinBox : virtual KSpinBox {
    KNumericSpinBox(QWidget * = 0, const char * = 0, int = AlignLeft);
    virtual ~KNumericSpinBox();
    void getRange(int &, int &);
    int getStep();
    int getValue();
    void setRange(int, int);
    void setStep(int);
    void setValue(int);
    void slotDecrease() slot;
    void slotIncrease() slot;
} KDE::NumericSpinBox;
