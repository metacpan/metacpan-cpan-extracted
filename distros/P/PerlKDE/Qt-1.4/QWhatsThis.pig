#include <qwhatsthis.h>

namespace QWhatsThis {
    static void add(QWidget *, const char *, bool = TRUE);
    static void add(QWidget *, const QPixmap &, const char *, const char *, bool = TRUE);
    static void remove(QWidget *);
    static const char *textFor(QWidget *);
    static QToolButton *whatsThisButton(QWidget *);
} Qt::WhatsThis;
