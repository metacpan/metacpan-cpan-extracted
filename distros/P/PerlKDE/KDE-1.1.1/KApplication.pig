
#include <kapp.h>

suicidal virtual class KApplication : virtual QApplication {
    enum ConfigState { APPCONFIG_NONE, APPCONFIG_READONLY, APPCONFIG_READWRITE };

    KApplication(int &{@argc(1)}, char **{argv});
    KApplication(int &{@argc(1)}, char **{argv}, const QString &);
    virtual ~KApplication();
    virtual void addDropZone(KDNDDropZone *);
    const QString &appName() const;
    const char *checkRecoverFile(const char *, bool &);
;    Display *getDisplay();
    Atom getDndEnterProtocolAtom();
    Atom getDndLeaveProtocolAtom();
    Atom getDndProtocolAtom();
    Atom getDndRootProtocolAtom();
    Atom getDndSelectionAtom();
    void enableSessionManagement(bool = FALSE);
    virtual bool eventFilter(QObject *, QEvent *);
    static QString findFile(const char *);
    const char *getCaption() const;
    KCharsets *getCharsets() const;
    KConfig *getConfig() const;
    KApplication::ConfigState getConfigState() const;
    QPopupMenu *getHelpMenu(bool, const char *);
    QPixmap getIcon() const;
    KIconLoader *getIconLoader();
    static KApplication *getKApplication();
;    bool getKDEFonts(QStrList *);
    KLocale *getLocale();
    QPixmap getMiniIcon() const;
    KConfig *getSessionConfig();
    void invokeHTMLHelp(QString, QString) const;
    bool isRestored() const;
    static const QString &kde_appsdir();
    static const QString &kde_bindir();
    static const QString &kde_cgidir();
    static const QString &kde_configdir();
    static const QString &kde_datadir();
    static const QString &kde_htmldir();
    static const QString &kde_icondir();
    static const QString &kde_localedir();
    static const QString &kde_mimedir();
    static const QString &kde_partsdir();
    static const QString &kde_sounddir();
    static const QString &kde_toolbardir();
    static const QString &kde_wallpaperdir();
    static QString localconfigdir();
    bool localeConstructed() const;
    static QString localkdedir();
    virtual void removeDropZone(KDNDDropZone *);
    virtual void setRootDropZone(KDNDDropZone *);
    void setTopWidget(QWidget *);
    void setWmCommand(const char *);
    const char *tempSaveName(const char *);
    QWidget *topWidget() const;
protected:
    void appearanceChanged() signal;
    static QString kdedir();
    void kdisplayFontChanged() signal;
    void kdisplayStyleChanged() signal;
    void saveYourself() signal;
    void shutDown() signal;
} KDE::Application;
