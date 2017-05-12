#include <qvalidator.h>

suicidal virtual class QValidator : virtual QObject {
    enum State { Invalid, Valid, Acceptable };
    QValidator(QWidget *, const char * = 0);
    virtual ~QValidator();
    virtual void fixup(QString &);
    abstract QValidator::State validate(QString &, int &);
} Qt::Validator;
