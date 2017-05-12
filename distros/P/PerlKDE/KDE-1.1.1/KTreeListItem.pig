#include <ktreelist.h>

suicidal virtual class KTreeListItem {
    KTreeListItem(const char * = 0, const QPixmap * = 0);
    virtual ~KTreeListItem();
    void appendChild(KTreeListItem *);
    virtual QRect boundingRect(const QFontMetrics &) const;
    KTreeListItem *childAt(int);
    uint childCount() const;
    int childIndex(KTreeListItem *);
    bool drawExpandButton() const;
    bool drawText() const;
    bool drawTree() const;
    bool expandButtonClicked(const QPoint &) const;
    int getBranch() const;
    KTreeListItem *getChild();
    int getIndent() const;
    KTreeListItem *getParent();
    const QPixmap *getPixmap() const;
    KTreeListItem *getSibling();
    const char *getText() const;
    bool hasChild() const;
    bool hasParent() const;
    bool hasSibling() const;
    virtual int height(const KTreeList *) const;
    void insertChild(int, KTreeListItem *);
    bool isExpanded() const;
    virtual QRect itemBoundingRect(const QFontMetrics &) const;
    virtual void paint(QPainter *, const QColorGroup &, bool);
    void removeChild(KTreeListItem *);
    void setBranch(int);
    void setChild(KTreeListItem *);
    void setDrawExpandButton(bool);
    void setDrawText(bool);
    void setDrawTree(bool);
    void setExpanded(bool);
    void setIndent(int);
    void setParent(KTreeListItem *);
    void setPixmap(const QPixmap *);
    void setSibling(KTreeListItem *);
    void setText(const char *);
    virtual QRect textBoundingRect(const QFontMetrics &) const;
    virtual int width(const KTreeList *) const;
protected:
    virtual int itemHeight(const QFontMetrics &) const;
    virtual int itemWidth(const QFontMetrics &) const;
} KDE::TreeListItem;
