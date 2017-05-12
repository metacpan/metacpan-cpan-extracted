#include <kruler.h>

suicidal virtual class KRuler : virtual QFrame {
    enum direction { horizontal, vertical };
    enum metric_style { custom, pixel, inch, millimetres, centimetres, metres };
    enum paint_style { flat, raised, sunken };
    KRuler(KRuler::direction, QWidget * = 0, const char * = 0, WFlags = 0, bool = TRUE);
    KRuler(KRuler::direction, int, QWidget * = 0, const char * = 0, WFlags = 0, bool = TRUE);
    virtual ~KRuler();
    int getBigMarkDistance() const;
    int getLittleMarkDistance() const;
    int getMaxValue() const;
    int getMediumMarkDistance() const;
    int getMinValue() const;
    int getOffset() const;
    double getPixelPerMark() const;
    int getTinyMarkDistance() const;
    int getValue() const;
    void setBigMarkDistance(int);
    void setEndLabel(const char *);
    void setLittleMarkDistance(int);
    void setMaxValue(int);
    void setMediumMarkDistance(int);
    void setMinValue(int);
    void setOffset(int);
    void setPixelPerMark(double);
    void setRange(int, int);
    void setRulerStyle(KRuler::metric_style);
    void setTinyMarkDistance(int);
    void setValue(int);
    void setValuePerBigMark(int);
    void setValuePerLittleMark(int);
    void setValuePerMediumMark(int);
    void showBigMarkLabel(bool);
    void showBigMarks(bool);
    void showEndLabel(bool);
    void showEndMarks(bool);
    void showLittleMarks(bool);
    void showMediumMarkLabel(bool);
    void showMediumMarks(bool);
    void showTinyMarks(bool);
    void slidedown(int = 1);
    void slideup(int = 1);
    void slotNewOffset(int) slot;
    void slotNewValue(int) slot;
protected:
    virtual void drawContents(QPainter *);
} KDE::Ruler;
