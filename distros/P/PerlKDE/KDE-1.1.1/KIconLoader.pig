#include <kiconloader.h>

class KIconLoader : QObject {
    KIconLoader();
    KIconLoader(KConfig *, const QString &, const QString &);
    ~KIconLoader();
    void flush(const QString &);
    QStrList *getDirList();
    QString getIconPath(const QString &, bool = false);
    bool insertDirectory(int, const QString &);
    QPixmap loadApplicationIcon(const QString &, int = 0, int = 0);
    QPixmap loadApplicationMiniIcon(const QString &, int = 0, int = 0);
    QPixmap loadIcon(const QString &, int = 0, int = 0);
    QPixmap loadMiniIcon(const QString &, int = 0, int = 0);
    QPixmap reloadIcon(const QString &, int = 0, int = 0);
} KDE::IconLoader;
