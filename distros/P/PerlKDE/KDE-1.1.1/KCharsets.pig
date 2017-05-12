#include <kcharsets.h>
#include <qstrlist.h>

class KCharsets {
    KCharsets();
    ~KCharsets();
    QStrList available() const;
    int bits(KCharset);
    KCharset charset(const QFont &);
    KCharset charset(QFont::CharSet);
    KCharset charsetFromX(const QString &);
    const KCharsetConversionResult &convert(unsigned);
    const KCharsetConversionResult &convertTag(const char *);
    const KCharsetConversionResult &convertTag(const char *, int &);
    KCharset defaultCh() const;
    KCharset defaultCharset() const;
    QStrList displayable(const char *);
    bool isAvailable(KCharset);
    bool isDisplayable(KCharset);
    bool isDisplayable(KCharset, const char *);
    bool isRegistered(KCharset);
    const char *name(const QFont &);
    const char *name(QFont::CharSet);
    QFont::CharSet qtCharset();
    QFont::CharSet qtCharset(KCharset);
    QStrList registered() const;
    bool setDefault(KCharset);
    QFont &setQFont(QFont &);
    QFont &setQFont(QFont &, KCharset);
} KDE::Charsets;
