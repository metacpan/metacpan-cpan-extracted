#include <kfiledialog.h>

; Will implement KFileDialog as a class at a later time

namespace KFileDialog {
    static QString getOpenFileName(const char * = 0, const char * = 0, QWidget * = 0, const char * = 0);
    static QString getOpenFileURL(const char * = 0, const char * = 0, QWidget * = 0, const char * = 0);
    static QString getSaveFileName(const char * = 0, const char * = 0, QWidget * = 0, const char * = 0);
    static QString getSaveFileURL(const char * = 0, const char * = 0, QWidget * = 0, const char * = 0);
} KDE::FileDialog;
