#include <qmessagebox.h>

suicidal virtual class QMessageBox : virtual QDialog {
    enum Icon {
	NoIcon,
	Information,
	Warning,
	Critical
    };
    enum {
	Ok,
	Cancel,
	Yes,
	No,
	Abort,
	Retry,
	Ignore,
	ButtonMask,
	Default,
	Escape,
	FlagMask
    };
    QMessageBox(QWidget * = 0, const char * = 0);
    QMessageBox(const char *, const char *, QMessageBox::Icon, int, int, int, QWidget * = 0, const char * = 0, bool = TRUE, WFlags = 0);
    virtual ~QMessageBox();
    static void about(QWidget *, const char *, const char *);
    static void aboutQt(QWidget *, const char * = 0);
    virtual void adjustSize();
    const char *buttonText(int) const;
    static int critical(QWidget *, const char *, const char *, int, int, int = 0);
    static int critical(QWidget *, const char *, const char *, const char * = "OK", const char * = 0, const char * = 0, int = 0, int = -1);
    QMessageBox::Icon icon() const;
    const QPixmap *iconPixmap() const;
    static int information(QWidget *, const char *, const char *, int, int = 0, int = 0);
    static int information(QWidget *, const char *, const char *, const char * = "OK", const char * = 0, const char * = 0, int = 0, int = -1);
    void setButtonText(int, const char *);
    void setIcon(QMessageBox::Icon);
    void setIconPixmap(const QPixmap &);
    virtual void setStyle(GUIStyle);
    void setText(const char *);
    static QPixmap standardIcon(QMessageBox::Icon, GUIStyle);
    const char *text() const;
    static int warning(QWidget *, const char *, const char *, int, int, int = 0);
    static int warning(QWidget *, const char *, const char *, const char * = "OK", const char * = 0, const char * = 0, int = 0, int = -1);
protected:
    virtual void keyPressEvent(QKeyEvent *);
    virtual void resizeEvent(QResizeEvent *);
} Qt::MessageBox;
