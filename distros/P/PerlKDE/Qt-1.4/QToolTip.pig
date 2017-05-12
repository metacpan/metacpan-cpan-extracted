#include <qtooltip.h>

suicidal virtual class QToolTip {
    QToolTip(QWidget *, QToolTipGroup * = 0);
    static void add(QWidget *, const char *);
    static void add(QWidget *, const QRect &, const char *);
    static void add(QWidget *, const char *, QToolTipGroup *, const char *);
    static void add(QWidget *, const QRect &, const char *, QToolTipGroup *, const char *);
    static QFont font();
    QToolTipGroup *group() const;
    static QPalette palette();
    QWidget *parentWidget() const;
    static void remove(QWidget *);
    static void remove(QWidget *, const QRect &);
    static void setFont(const QFont &);
    static void setPalette(const QPalette &);
protected:
    void clear();
    abstract void maybeTip(const QPoint &);
    void tip(const QRect &, const char *);
    void tip(const QRect &, const char *, const char *);
} Qt::ToolTip;
