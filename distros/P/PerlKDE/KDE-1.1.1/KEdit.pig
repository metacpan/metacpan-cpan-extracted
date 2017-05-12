#include <keditcl.h>

suicidal virtual class KEdit : virtual QMultiLineEdit {
    enum { NONE,
           FORWARD,
           BACKWARD };
    enum { KEDIT_OK,
           KEDIT_OS_ERROR,
           KEDIT_USER_CANCEL,
           KEDIT_RETRY,
           KEDIT_NOPERMISSIONS };
    enum { OPEN_READWRITE,
           OPEN_READONLY,
           OPEN_INSERT };

    KEdit(KApplication * = 0, QWidget * = 0, const char * = 0, const char * = 0);
    virtual ~KEdit();
    bool AutoIndentMode();
    void computePosition() slot;
    int currentColumn();
    int currentLine();
    void doGotoLine();
    int doSave();
    int doSave(const char *);
    bool FillColumnMode();
;    bool format(QStrList &);
;    bool format2(QStrList &, int &);
    QString getName();
;    getpar(int, QStrList &);
;    getpar2(int, QStrList &, int &, QString &);
    int insertFile();
    void installRBPopup(QPopupMenu *);
    bool isModified();
    QString markedText();
    int newFile();
    int openFile(int);
    void repaintAll() slot;
    int repeatSearch();
    void Replace();
    void replacedone_slot() slot;
    void replace_slot() slot;
    void replace_all_slot() slot;
    void replace_search_slot() slot;
    int saveAs();
    void saveasfile(char *);
    void saveBackupCopy(bool);
    void Search();
    void search_slot() slot;
    void searchdone_slot() slot;
    void selectFont();
    void setAutoIndentMode(bool);
    void setFileName(char *);
    void setFillColumnMode(int, bool);
    void setModified() slot;
    void setName(const char *);
    void setReduceWhiteOnJustify(bool);
    void setWordWrap(bool);
    void toggleModified(bool);
    bool WordWrap();
protected:
    void CursorPositionChanged() signal;
    int doReplace(QString, bool, bool, bool, int, int, bool);
    int doSearch(QString, bool, bool, bool, int, int);
    virtual bool eventFilter(QObject *, QEvent *);
    void fileChanged() signal;
    QFileDialog *getFileDialog(const char *);
    virtual void keyPressEvent(QKeyEvent *);
    void loading() signal;
    virtual void mouseMoveEvent(QMouseEvent *);
    virtual void mousePressEvent(QMouseEvent *);
    virtual void mouseReleaseEvent(QMouseEvent *);
    int saveFile();
    void saving() signal;
    void toggle_overwrite_signal() signal;
} KDE::Edit;
