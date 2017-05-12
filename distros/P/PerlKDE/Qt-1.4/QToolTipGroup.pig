#include <qtooltip.h>

suicidal class QToolTipGroup : QObject {
    QToolTipGroup(QObject *, const char * = 0);
    virtual ~QToolTipGroup();
protected:
    void removeTip() signal;
    void showTip(const char *) signal;
} Qt::ToolTipGroup;
