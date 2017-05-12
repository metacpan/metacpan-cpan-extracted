#include <keditcl.h>

suicidal class KEdGotoLine : QDialog {
    KEdGotoLine(QWidget * = 0, const char * = 0);
    int getLineNumber();
    void selected(int) slot;
} KDE::EdGotoLine;
