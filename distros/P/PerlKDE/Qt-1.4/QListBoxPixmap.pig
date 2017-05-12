#include <qlistbox.h>

suicidal virtual class QListBoxPixmap : virtual QListBoxItem {
    QListBoxPixmap(const QPixmap &);
    virtual ~QListBoxPixmap();
    virtual const QPixmap *pixmap() const;
protected:
    virtual int height(const QListBox *) const;
    virtual void paint(QPainter *);
    virtual int width(const QListBox *) const;
} Qt::ListBoxPixmap;
