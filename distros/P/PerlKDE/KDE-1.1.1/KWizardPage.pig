#include <kwizard.h>

struct KWizardPage {
    KWizardPage();
    variable bool enabled();
    variable int id();
    variable void setEnabled(bool);
    variable void setId(int);
    variable void setTitle(const QString &);
    variable void setW(QWidget *);
    variable void setWidget(QWidget *) : $this->w = $1;
    variable QString title();
    variable QWidget *w();
    variable QWidget *widget() : $this->w;
} KDE::WizardPage;
