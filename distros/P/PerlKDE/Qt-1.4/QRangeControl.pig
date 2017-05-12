#include <qrangecontrol.h>

virtual class QRangeControl {
    QRangeControl();
    QRangeControl(int, int, int, int, int);
    void addLine();
    void addPage();
    int lineStep() const;
    int maxValue() const;
    int minValue() const;
    int pageStep() const;
    void setRange(int, int);
    void setSteps(int, int);
    void setValue(int);
    void subtractLine();
    void subtractPage();
    int value() const;
protected:
    void directSetValue(int);
    int prevValue() const;
    virtual void rangeChange();
    virtual void stepChange();
    virtual void valueChange();
} Qt::RangeControl;
