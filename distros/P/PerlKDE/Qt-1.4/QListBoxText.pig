#include <qlistbox.h>

suicidal virtual class QListBoxText : virtual QListBoxItem {
    QListBoxText(const char * = 0);
    virtual ~QListBoxText();
    virtual int height(const QListBox *) const;
    virtual void paint(QPainter *);
    virtual int width(const QListBox *) const;
} Qt::ListBoxText;
