#include <qvalidator.h>

suicidal virtual class QDoubleValidator : virtual QValidator {
    QDoubleValidator(QWidget *, const char * = 0);
    QDoubleValidator(double, double, int, QWidget *, const char * = 0);
    virtual ~QDoubleValidator();
    double bottom() const;
    int decimals() const;
    virtual void setRange(double, double, int = 0);
    double top() const;
    virtual QValidator::State validate(QString &, int &);
} Qt::DoubleValidator;
