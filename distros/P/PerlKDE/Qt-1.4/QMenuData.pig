#define INCLUDE_MENUITEM_DEF
#include <qmenudata.h>

virtual class QMenuData {
    QMenuData();
    virtual ~QMenuData();
    int accel(int) const;
    void changeItem(const char *, int);
    void changeItem(const QPixmap &, int);
    void changeItem(const QPixmap &, const char *, int);
    void clear();
    bool connectItem(int, const QObject *{receiver(3)}, const char *{member(2)});
    uint count() const;
    bool disconnectItem(int, const QObject *{unreceiver(3)}, const char *{member(2)});
    QMenuItem *findItem(int) const;
;    QMenuItem *findItem(int, QMenuData **) const;
    int idAt(int) const;
    int indexOf(int) const;
    int insertItem(const char *, int = -1, int = -1);
    int insertItem(const QPixmap &, int = -1, int = -1);
    int insertItem(const char *, QPopupMenu *, int = -1, int = -1);
    int insertItem(const QPixmap &, const char *, int = -1, int = -1);
    int insertItem(const QPixmap &, QPopupMenu *, int = -1, int = -1);
    int insertItem(const char *, const QObject *{receiver(3)}, const char *{member(2)}, int = 0);
    int insertItem(const QPixmap &, const QObject *{receiver(3)}, const char *{member(2)}, int = 0);
    int insertItem(const QPixmap &, const char *, QPopupMenu *, int = -1, int = -1);
    int insertItem(const QPixmap &, const char *, const QObject *{receiver(4)}, const char *{member(3)}, int = 0);
    int insertItem(const char *, const QObject *{receiver(3)}, const char *{member(2)}, int, int, int = -1);
    int insertItem(const QPixmap &, const QObject *{receiver(3)}, const char *{member(2)}, int, int, int = -1);
    int insertItem(const QPixmap &, const char *, const QObject *{receiver(4)}, const char *{member(3)}, int, int, int = -1);
    void insertSeparator(int = -1);
    bool isItemChecked(int) const;
    bool isItemEnabled(int) const;
    QPixmap *pixmap(int) const;
    void removeItem(int);
    void removeItemAt(int);
    void setAccel(int, int);
    void setId(int, int);
    void setItemChecked(int, bool);
    void setItemEnabled(int, bool);
    const char *text(int) const;
    virtual void updateItem(int);
protected:
    QMenuItem *findPopup(QPopupMenu *, int * = 0);
;    virtual void menuContentsChanged();
;    virtual void menuDelPopup(QPopupMenu *);
;    virtual void menuInsPopup(QPopupMenu *);
;    virtual void menuStateChanged();
} Qt::MenuData;
