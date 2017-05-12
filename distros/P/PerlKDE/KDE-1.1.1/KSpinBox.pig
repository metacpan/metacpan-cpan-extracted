#include <kspinbox.h>

suicidal virtual class KSpinBox : virtual QWidget {
    KSpinBox(QWidget * = 0, const char * = 0, int = AlignLeft);
    virtual ~KSpinBox();
    int getAlign();
    const char *getValue();
    bool isEditable();
    void setAlign(int);
    void setEditable(bool);
    void setValue(const char *);
    virtual QSize sizeHint() const;
    void slotIncrease() slot;
    void slotDecrease() slot;
protected:
    virtual void resizeEvent(QResizeEvent *);
    void slotStartDecr() slot;
    void slotStartIncr() slot;
    void slotStopDecr() slot;
    void slotStopIncr() slot;
    void valueDecreased() signal;
    void valueIncreased() signal;
} KDE::SpinBox;
