#include <qspinbox.h>

suicidal virtual class QSpinBox : virtual QFrame, virtual QRangeControl {
    QSpinBox(QWidget * = 0, const char * = 0);
    QSpinBox(int, int, int = 1, QWidget * = 0, const char * = 0 );
    virtual ~QSpinBox();
    virtual QString cleanText() const;
    virtual const char *prefix() const;
    virtual void setPrefix(const char *) slot;
    virtual void setSuffix(const char *) slot;
    void setSpecialValueText(const char *);
    void setValidator(QValidator *);
    virtual void setValue(int) slot;
    void setWrapping(bool);
    virtual QSize sizeHint() const;
    const char *specialValueText() const;
    virtual void stepDown() slot;
    virtual void stepUp() slot;
    virtual const char *suffix() const;
    const char *text() const;
    bool wrapping() const;
protected:
    QString currentValueText();
    QPushButton *downButton() const;
    QLineEdit *editor() const;
    virtual void enabledChange(bool);
    virtual bool eventFilter(QObject *, QEvent *);
    virtual void fontChange(const QFont &);
    virtual void interpretText();
    virtual int mapTextToValue(bool *);
    virtual QString mapValueToText(int);
    virtual void paletteChange(const QPalette &);
    virtual void rangeChange();
    virtual void resizeEvent(QResizeEvent *);
    virtual void styleChange(GUIStyle);
    void textChanged() slot;
    QPushButton *upButton() const;
    virtual void updateDisplay();
    virtual void valueChange();
    void valueChanged(int) signal;
    void valueChanged(const char *) signal;
} Qt::SpinBox;
