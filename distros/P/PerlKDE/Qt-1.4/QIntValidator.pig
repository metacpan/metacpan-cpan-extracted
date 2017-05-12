#include <qvalidator.h>

suicidal virtual class QIntValidator : virtual QValidator {
    QIntValidator(QWidget *, const char * = 0);
    QIntValidator(int, int, QWidget *, const char *);
    virtual ~QIntValidator();
    int bottom() const;
    virtual void setRange(int, int);
    int top() const;
    virtual QValidator::State validate(QString &, int &);
} Qt::IntValidator;
