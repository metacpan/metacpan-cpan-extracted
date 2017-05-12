#include <qlistview.h>

suicidal virtual class QCheckListItem : virtual QListViewItem {
    enum Type { RadioButton, CheckBox, Controller };
    QCheckListItem(QCheckListItem *, const char *, QCheckListItem::Type = QCheckListItem::Controller);
    QCheckListItem(QListView *, const char *, QCheckListItem::Type = QCheckListItem::Controller);
    QCheckListItem(QListViewItem *, const char *, const QPixmap &);
    QCheckListItem(QListView *, const char *, const QPixmap &);
    bool isOn() const;
    virtual void paintCell(QPainter *, const QColorGroup &, int, int, int);
    void setOn(bool);
    virtual void setup();
    virtual void stateChange(bool);
    const char *text() const;
    const char *text(int) const;
    QCheckListItem::Type type() const;
    virtual int width(const QFontMetrics &, const QListView *, int) const;
protected:
    void activate();
    virtual void paintBranches(QPainter *, const QColorGroup &, int, int, int, GUIStyle);
    void turnOffChild();
} Qt::CheckListItem;
