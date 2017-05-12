#include <qevent.h>

struct QEvent {
    QEvent(int);
    QEvent(const QEvent &);
    ~QEvent();
    int type() const;
} Qt::Event;

const int Event_None;
const int Event_Timer;
const int Event_MouseButtonPress;
const int Event_MouseButtonRelease;
const int Event_MouseButtonDblClick;
const int Event_MouseMove;
const int Event_KeyPress;
const int Event_KeyRelease;
const int Event_FocusIn;
const int Event_FocusOut;
const int Event_Enter;
const int Event_Leave;
const int Event_Paint;
const int Event_Move;
const int Event_Resize;
const int Event_Create;
const int Event_Destroy;
const int Event_Show;
const int Event_Hide;
const int Event_Close;
const int Event_Quit;
const int Event_Accel;
const int Event_Clipboard;
const int Event_SockAct;
const int Event_DragEnter;
const int Event_DragMove;
const int Event_DragLeave;
const int Event_Drop;
const int Event_DragResponse;
const int Event_ChildInserted;
const int Event_ChildRemoved;
const int Event_LayoutHint;
const int Event_User;

enum ButtonState {
    NoButton,
    LeftButton,
    RightButton,
    MidButton,
    MouseButtonMask,
    ShiftButton,
    ControlButton,
    AltButton,
    KeyButtonMask
};
