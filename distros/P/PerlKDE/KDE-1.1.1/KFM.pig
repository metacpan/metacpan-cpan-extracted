#include <kfm.h>

suicidal virtual class KFM : virtual QObject {
    KFM();
    virtual ~KFM();
    void allowKFMRestart(bool);
    void configure();
    void copy(const char *, const char *);
    void copyClient(const char *, const char *);
    static bool download(const QString &, QString &);
    void exec(const char *, const char *);
    bool isKFMRunning();
    bool isOK();
    void list(const char *);
    void move(const char *, const char *);
    void moveClient(const char *, const char *);
    void openProperties(const char *);
    void openURL();
    void openURL(const char *);
    void refreshDesktop();
    void refreshDirectory(const char *);
    static void removeTempFile(const QString &);
    void selectRootIcons(int, int, int, int, bool);
    static void setSilent(bool);
    void slotDirEntry(const char *, const char *, const char *, const char *, const char *, int);
    void slotError(int, const char *);
    void slotFinished();
    void sortDesktop();
protected:
;    void dirEntry(KDirEntry &) signal;
    void error(int, const char *) signal;
    void finished() signal;
    void init();
    bool test();
} KDE::FM;
