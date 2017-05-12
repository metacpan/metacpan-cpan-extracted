#undef debug
#undef warning
#undef fatal
#include <qglobal.h>
#include <qwindefs.h>
#include <X11/Xlib.h>

namespace Qt {
    static void debug(const char *) : debug($0);
    static void warning(const char *) : warning($0);
    static void fatal(const char *) : fatal($0);
    static bool sysInfo(int *, bool *) : qSysInfo($0, $1);
    static const char *version() : qVersion();

    static int xfd() : ConnectionNumber(qt_xdisplay());

;    static void addPostRoutine(....) : pig_Qt_addPostRoutine($0);
;    static .... installMsgHandler(....) : pig_Qt_installMsgHandler($0);
;    static ulong int lor(...) : pig_Qt_listor();
} Qt;

const int QT_VERSION;
const char *QT_VERSION_STR;

extern const int QCOORD_MIN;
extern const int QCOORD_MAX;

enum QtMsgType {
    QtDebugMsg,
    QtWarningMsg,
    QtFatalMsg
};
