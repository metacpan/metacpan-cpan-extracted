#include <ksimpleconfig.h>

class KSimpleConfig : KConfigBase {
    KSimpleConfig(const char *);
    KSimpleConfig(const char *, bool);
    ~KSimpleConfig();
    const QString deleteEntry(const char *, bool);
    bool deleteGroup(const char *, bool = true);
    bool isReadOnly() const;
} KDE::SimpleConfig;
