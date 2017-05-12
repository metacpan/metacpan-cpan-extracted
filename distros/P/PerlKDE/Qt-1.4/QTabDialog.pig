#include <qtabdialog.h>

suicidal virtual class QTabDialog : virtual QDialog {
    QTabDialog(QWidget * = 0, const char * = 0, bool = FALSE, WFlags = 0);
    virtual ~QTabDialog();
    void addTab(QWidget *, const char *);
    void addTab(QWidget *, QTab *);
    bool hasApplyButton() const;
    bool hasCancelButton() const;
    bool hasDefaultButton() const;
    bool hasOkButton() const;
    bool isTabEnabled(const char *) const;
    void setApplyButton(const char * = "Apply");
    void setCancelButton(const char * = "Cancel");
    void setDefaultButton(const char * = "Defaults");
    virtual void setFont(const QFont &);
    void setOkButton(const char * = "OK");
    void setTabEnabled(const char *, bool);
    virtual void show();
    void showPage(QWidget *);
    const char *tabLabel(QWidget *);
protected:
    void aboutToShow() signal;
    void applyButtonPressed() signal;
    void cancelButtonPressed() signal;
    void defaultButtonPressed() signal;
    virtual void paintEvent(QPaintEvent *);
    virtual void resizeEvent(QResizeEvent *);
    void selected(const char *) signal;
    void setTabBar(QTabBar *);
    virtual void styleChange(GUIStyle);
    QTabBar *tabBar() const;
} Qt::TabDialog;
