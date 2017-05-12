#include <qlineedit.h>

suicidal virtual class QLineEdit : virtual QWidget {
    enum EchoMode {
	Normal,
	NoEcho,
	Password
    };
    QLineEdit(QWidget * = 0, const char * = 0);
    virtual ~QLineEdit();
    void clear() slot;
    void clearValidator() slot;
    int cursorPosition() const;
    void deselect() slot;
    QLineEdit::EchoMode echoMode() const;
    bool frame() const;
    void insert(const char *) slot;
    int maxLength() const;
    void selectAll() slot;
    void setCursorPosition(int);
    void setEchoMode(QLineEdit::EchoMode);
    virtual void setEnabled(bool);
    virtual void setFont(const QFont &);
    void setFrame(bool);
    void setMaxLength(int);
    void setSelection(int, int);
    void setText(const char *) slot;
    void setValidator(QValidator *);
    virtual QSize sizeHint() const;
    const char *text() const;
    bool validateAndSet(const char *, int, int, int);
    QValidator *validator() const;
protected:
    virtual bool event(QEvent *);
    virtual void focusInEvent(QFocusEvent *);
    virtual void focusOutEvent(QFocusEvent *);
    bool hasMarkedText() const;
    virtual void keyPressEvent(QKeyEvent *);
    virtual void leaveEvent(QEvent *);
    QString markedText() const;
    virtual void mouseDoubleClickEvent(QMouseEvent *);
    virtual void mouseMoveEvent(QMouseEvent *);
    virtual void mousePressEvent(QMouseEvent *);
    virtual void mouseReleaseEvent(QMouseEvent *);
    virtual void paintEvent(QPaintEvent *);
    void repaintArea(int, int);
    virtual void resizeEvent(QResizeEvent *);
    void returnPressed() signal;
    void textChanged(const char *) signal;
    virtual void timerEvent(QTimerEvent *);
} Qt::LineEdit;
