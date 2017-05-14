#ifndef CANNONFIELD_H
#define CANNONFIELD_H

#include <QWidget>

class CannonField : public QWidget
{
    Q_OBJECT

public:
    CannonField(QWidget *parent = 0);

    int angle() const { return currentAngle; }

public slots:
    void setAngle(int angle);

signals:
    void angleChanged(int newAngle);

protected:
    void paintEvent(QPaintEvent *event);

private:
    int currentAngle;
};

#endif
