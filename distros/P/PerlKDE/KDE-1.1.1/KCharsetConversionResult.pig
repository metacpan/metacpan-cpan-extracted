#include <kcharsets.h>

struct KCharsetConversionResult {
    KCharsetConversionResult();
    KCharsetConversionResult &operator = (const KCharsetConversionResult &);
    KCharset charset() const;
    const char *copy() const : (const char *)*$this;
    QFont font(const QFont &) const;
    const char *getText() const : (const char *)*$this;
    QFont &setQFont(QFont &) const;
    const char *text() const : (const char *)*$this;
} KDE::CharsetConversionResult;
