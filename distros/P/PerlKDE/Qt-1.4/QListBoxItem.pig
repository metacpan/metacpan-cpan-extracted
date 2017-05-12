#include <qlistbox.h>

suicidal virtual class QListBoxItem {
    QListBoxItem();
    virtual ~QListBoxItem();
    abstract int height(const QListBox *) const;
    virtual const QPixmap *pixmap() const;
    virtual const char *text() const;
    abstract int width(const QListBox *) const;
protected:
    abstract void paint(QPainter *);
    void setText(const char *);
} Qt::ListBoxItem;

const int LBI_Undefined;
const int LBI_Text;
const int LBI_Pixmap;
const int LBI_UserDefined;
