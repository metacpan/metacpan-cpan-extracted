#include <qfiledialog.h>

suicidal virtual class QFileDialog : virtual QDialog {
    enum Mode {
	AnyFile, ExistingFile, Directory
    };
    QFileDialog(QWidget * = 0, const char * = 0, bool = FALSE);
    QFileDialog(const char *, const char * = 0, QWidget * = 0, const char * = 0, bool = FALSE);
    virtual ~QFileDialog();
    const QDir *dir() const;
    const char *dirPath() const;
    virtual bool eventFilter(QObject *, QEvent *);
    static QString getExistingDirectory(const char * = 0, QWidget * = 0, const char * = 0);
    static QString getOpenFileName(const char * = 0, const char * = 0, QWidget * = 0, const char * = 0);
    static QString getSaveFileName(const char * = 0, const char * = 0, QWidget * = 0, const char * = 0);
    static QFileIconProvider *iconProvider();
    QFileDialog::Mode mode() const;
    void rereadDir();
    QString selectedFile() const;
    void setDir(const char *) slot;
    void setDir(const QDir &);
    void setFilter(const char *) slot;
    void setFilters(const QStrList &) slot;
    static void setIconProvider(QFileIconProvider *);
    void setMode(QFileDialog::Mode);
    void setSelection(const char *);
protected:
    void addWidgets(QLabel *, QWidget *, QPushButton *);
    void dirEntered(const char *) signal;
    void fileHighlighted(const char *) signal;
    void fileSelected(const char *) signal;
    virtual void keyPressEvent(QKeyEvent *);
    virtual void resizeEvent(QResizeEvent *);
} Qt::FileDialog;
