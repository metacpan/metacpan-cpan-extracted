#include <kpopmenu.h>

suicidal virtual class KPopupMenu : virtual QPopupMenu {
    KPopupMenu(QWidget * = 0, const char * = 0);
    KPopupMenu(const char *, QWidget * = 0, const char * = 0);
    virtual ~KPopupMenu();
    void setTitle(const char *);
    const char *title() const;
private:
    void paintCell(QPainter *, int, int);
} KDE::PopupMenu;
