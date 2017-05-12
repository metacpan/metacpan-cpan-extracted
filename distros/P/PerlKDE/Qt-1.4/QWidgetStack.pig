#include <qwidgetstack.h>

suicidal virtual class QWidgetStack : virtual QFrame {
    QWidgetStack(QWidget * = 0, const char * = 0);
    virtual ~QWidgetStack();
    void addWidget(QWidget *, int);
    int id(QWidget *) const;
    void raiseWidget(int);
    void raiseWidget(QWidget *);
    void removeWidget(QWidget *);
    virtual void show();
    QWidget *visibleWidget() const;
    QWidget *widget(int) const;
protected:
    void aboutToShow(int) signal;
    void aboutToShow(QWidget *) signal;
    virtual void frameChanged();
    void setChildGeometries();
} Qt::WidgetStack;
