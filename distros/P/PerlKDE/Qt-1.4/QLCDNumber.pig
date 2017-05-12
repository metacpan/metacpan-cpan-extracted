#undef HEX
#undef DEC
#undef BIN
#undef OCT
#include <qlcdnumber.h>

suicidal virtual class QLCDNumber : virtual QFrame {
    enum Mode {
	HEX,
	DEC,
	OCT,
	BIN
    };
    enum SegmentStyle {
	Outline,
	Filled,
	Flat
    };
    QLCDNumber(QWidget * = 0, const char * = 0);
    QLCDNumber(uint, QWidget * = 0, const char * = 0);
    virtual ~QLCDNumber();
    bool checkOverflow(int) const;
    bool checkOverflow(double) const;
    void display(int) slot;
    void display(double) slot;
    void display(const char *) slot;
    int intValue() const;
    QLCDNumber::Mode mode() const;
    int numDigits() const;
    QLCDNumber::SegmentStyle segmentStyle() const;
    void setBinMode() slot;
    void setDecMode() slot;
    void setHexMode() slot;
    void setOctMode() slot;
    void setMode(QLCDNumber::Mode);
    void setNumDigits(int);
    void setSegmentStyle(QLCDNumber::SegmentStyle);
    void setSmallDecimalPoint(bool) slot;
    virtual QSize sizeHint() const;
    bool smallDecimalPoint() const;
    double value() const;
protected:
    virtual void drawContents(QPainter *);
    void overflow() signal;
    virtual void resizeEvent(QResizeEvent *);
} Qt::LCDNumber;
