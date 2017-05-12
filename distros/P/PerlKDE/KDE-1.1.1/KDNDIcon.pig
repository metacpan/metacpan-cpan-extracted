#include <drag.h>

suicidal virtual class KDNDIcon : virtual QWidget {
    KDNDIcon(QPixmap &, int, int);
    KDNDIcon(const KDNDIcon &);
    KDNDIcon &operator = (const KDNDIcon &);
    virtual ~KDNDIcon();
protected:
    virtual void paintEvent(QPaintEvent *);
    virtual void resizeEvent(QResizeEvent *);
} KDE::DNDIcon;
