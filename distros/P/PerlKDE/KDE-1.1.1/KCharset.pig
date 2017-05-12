#include <kcharsets.h>

struct KCharset {
    KCharset();
    KCharset(const char *);
    KCharset(QFont::CharSet);
    KCharset(const KCharset &);
    KCharset &operator = (const KCharset &);
    bool operator == (const KCharset &) const;
    int bits() const;
    bool isAvailable() const;
    bool isDisplayable();
    bool isDisplayable(const char *);
    bool isRegistered() const;
    const char *name() const;
    bool ok() const;
    bool printable(int);
    QFont::CharSet qtCharset() const;
    QFont &setQFont(QFont &);
    QString xCharset();
} KDE::Charset;
