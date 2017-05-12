#include <kcontrol.h>

suicidal virtual class KControlApplication : virtual KApplication {
    KControlApplication(int &{@argc(1)}, char **{argv}, const char * = 0);
    virtual ~KControlApplication();
    void addPage(QWidget *, const QString &, const QString &);
    virtual void apply() slot;
    virtual void defaultValues() slot;
    QTabDialog *getDialog();
    QStrList *getPageList();
    virtual void help() slot;
    virtual void init() slot;
    bool runGUI();
    void setTitle(const char *);
} KDE::ControlApplication;
