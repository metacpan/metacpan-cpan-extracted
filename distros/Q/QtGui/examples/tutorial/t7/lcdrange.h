#ifndef LCDRANGE_H
#define LCDRANGE_H

#include <QWidget>

class QSlider;

class LCDRange : public QWidget
{
    Q_OBJECT

public:
    LCDRange(QWidget *parent = 0);

    int value() const;

public slots:
    void setValue(int value);

signals:
    void valueChanged(int newValue);

private:
    QSlider *slider;
};

#endif
