#include <qpixmapcache.h>

namespace QPixmapCache {
    static int cacheLimit();
    static void clear();
    static QPixmap *find(const char *);
    static bool find(const char *, QPixmap &);
    static bool insert(const char *, QPixmap *);
    static void insert(const char *, const QPixmap &);
    static void setCacheLimit(int);
} Qt::PixmapCache;
