#include <kwmmapp.h>

suicidal virtual class KWMModuleApplication : virtual KApplication {
    KWMModuleApplication(int &{@argc(1)}, char **{argv});
    KWMModuleApplication(int &{@argc(1)}, char **{argv}, const QString &);
    virtual ~KWMModuleApplication();
    void connectToKWM(bool = false);
    bool hasWindow(Window);
protected:
    void commandReceived(QString) signal;
    void desktopChange(int) signal;
    void desktopNameChange(int, QString) signal;
    void desktopNumberChange(int) signal;
    void dialogWindowAdd(Window) signal;
    void dockWindowAdd(Window) signal;
    void dockWindowRemove(Window) signal;
    void init() signal;
    void initialized() signal;
    void playSound(QString) signal;
    void registerSound(QString) signal;
    void unregisterSound(QString) signal;
    void windowActivate(Window) signal;
    void windowAdd(Window) signal;
    void windowChange(Window) signal;
    void windowIconChanged(Window) signal;
    void windowLower(Window) signal;
    void windowRaise(Window) signal;
    void windowRemove(Window) signal;
} KDE::WMModuleApplication;
