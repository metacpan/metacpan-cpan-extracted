#include <ktopwidget.h>

suicidal virtual class KTopLevelWidget : virtual KTMainWindow {
    KTopLevelWidget(const char * = 0L);
    virtual ~KTopLevelWidget();
protected:
    virtual void closeEvent(QCloseEvent *);
} KDE::TopLevelWidget;
