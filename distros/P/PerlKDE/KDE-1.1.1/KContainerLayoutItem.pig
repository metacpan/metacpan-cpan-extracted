#include <kcontainer.h>

class KContainerLayoutItem {
    KContainerLayoutItem(QWidget *, bool = FALSE, bool = FALSE, int = 0);
    bool expand() const;
    bool fill() const;
    int padding() const;
    void setExpand(bool);
    void setFill(bool);
    void setPadding(int);
    QWidget *widget();
} KDE::ContainerLayoutItem;
