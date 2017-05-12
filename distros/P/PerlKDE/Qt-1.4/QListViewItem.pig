#include <qlistview.h>

suicidal virtual class QListViewItem {
    QListViewItem(QListView *);
    QListViewItem(QListViewItem *);
    QListViewItem(QListView *, const char *, const char * = 0, const char * = 0, const char * = 0, const char * = 0, const char * = 0, const char * = 0, const char * = 0);
    QListViewItem(QListViewItem *, const char *, const char * = 0, const char * = 0, const char * = 0, const char * = 0, const char * = 0, const char * = 0, const char * = 0);
    virtual ~QListViewItem();
    int childCount() const;
    int depth() const;
    QListViewItem *firstChild() const;
    int height() const;
    virtual void insertItem(QListViewItem *);
    virtual void invalidateHeight();
    bool isExpandable();
    bool isOpen() const;
    bool isSelectable() const;
    bool isSelected() const;
    QListViewItem *itemAbove();
    QListViewItem *itemBelow();
    virtual const char *key(int, bool) const;
    QListView *listView() const;
    QListViewItem *nextSibling() const;
    virtual void paintBranches(QPainter *, const QColorGroup &, int, int, int, GUIStyle);
    virtual void paintCell(QPainter *, const QColorGroup &, int, int, int);
    virtual void paintFocus(QPainter *, const QColorGroup &, const QRect &);
    QListViewItem *parent() const;
    virtual const QPixmap *pixmap(int) const;
    virtual void removeItem(QListViewItem *);
    void repaint() const;
    virtual void setExpandable(bool);
    virtual void setOpen(bool);
    virtual void setPixmap(int, const QPixmap &);
    virtual void setSelectable(bool);
    virtual void setSelected(bool);
    virtual void setText(int, const char *);
    virtual void setup();
    virtual void sortChildItems(int, bool);
    virtual const char *text(int) const;
    int totalHeight() const;
    virtual int width(const QFontMetrics &, const QListView *, int) const;
    void widthChanged(int = -1) const;
protected:
    virtual void activate();
    virtual void enforceSortOrder() const;
    virtual void setHeight(int);
} Qt::ListViewItem;
