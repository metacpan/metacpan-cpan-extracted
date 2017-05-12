#include <qcheckbox.h>

suicidal virtual class QCheckBox : virtual QButton {
    QCheckBox(QWidget * = 0, const char * = 0);
    QCheckBox(const char *, QWidget *, const char * = 0);
    bool isChecked() const;
    void setChecked(bool);
    virtual QSize sizeHint() const;
protected:
    virtual void drawButton(QPainter *);
    virtual void drawButtonLabel(QPainter *);
} Qt::CheckBox;
