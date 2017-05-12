#include <qbttngrp.h>

suicidal virtual class QButtonGroup : virtual QGroupBox {
    QButtonGroup(QWidget * = 0, const char * = 0);
    QButtonGroup(const char *, QWidget * = 0, const char * = 0);
    virtual ~QButtonGroup();
    QButton *find(int) const;
    int insert(QButton *, int = -1);
    bool isExclusive() const;
    void remove(QButton *);
    void setButton(int);
    void setExclusive(bool);
protected:
    void buttonClicked() slot;
    void buttonPressed() slot;
    void buttonReleased() slot;
    void buttonToggled(bool) slot;
    void clicked(int) signal;
    void pressed(int) signal;
    void released(int) signal;
} Qt::ButtonGroup;
