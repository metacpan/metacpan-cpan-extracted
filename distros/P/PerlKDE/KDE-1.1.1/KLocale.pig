#include <klocale.h>

class KLocale {
    KLocale(const char * = 0L);
    ~KLocale();
    void aliasLocale(const char *, long);
    const QString &charset() const;
    QString directory();
    void enableNumericLocale(bool = true);
    const char *getAlias(long) const;
    const char *getLocale(QString);
    void insertCatalogue(const char *);
    const QString &language() const;
    QStrList languageList() const;
    const QString &languages() const;
    static const QString mergeLocale(const QString &, const QString &, const QString &);
    bool numericLocaleEnabled() const;
    static void splitLocale(const QString &, QString &, QString &, QString &);
    const char *translate(const char *);
} KDE::Locale;
