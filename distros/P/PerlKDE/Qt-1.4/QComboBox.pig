#include <qcombobox.h>

suicidal virtual class QComboBox : virtual QWidget {
    enum Policy {
	NoInsertion, AtTop, AtCurrent, AtBottom, AfterCurrent, BeforeCurrent
    };
    QComboBox(QWidget * = 0, const char * = 0);
    QComboBox(bool, QWidget * = 0, const char * = 0);
    virtual ~QComboBox();
    bool autoCompletion() const;
    bool autoResize() const;
    void changeItem(const char *, int);
    void changeItem(const QPixmap &, int);
    void clear();
    void clearEdit();
    void clearValidator() slot;
    int count() const;
    int currentItem() const;
    const char *currentText() const;
    virtual bool eventFilter(QObject *, QEvent *);
    QComboBox::Policy insertionPolicy() const;
    void insertItem(const char *, int = -1);
    void insertItem(const QPixmap &, int = -1);
    void insertStrList(const QStrList *, int = -1);
    QListBox *listBox() const;
    int maxCount() const;
    const QPixmap *pixmap(int) const;
    void removeItem(int);
    void setAutoCompletion(bool);
    void setAutoResize(bool);
    virtual void setBackgroundColor(const QColor &);
    void setCurrentItem(int);
    void setEditText(const char *);
    virtual void setEnabled(bool);
    virtual void setFont(const QFont &);
    void setInsertionPolicy(QComboBox::Policy);
    void setListBox(QListBox *);
    void setMaxCount(int);
    virtual void setPalette(const QPalette &);
    void setSizeLimit(int);
    virtual void setStyle(GUIStyle);
    void setValidator(QValidator *);
    virtual QSize sizeHint() const;
    int sizeLimit() const;
    const char *text(int) const;
    QValidator *validator() const;
protected:
    void activated(int) signal;
    void activated(const char *) signal;
    virtual void focusInEvent(QFocusEvent *);
    void highlighted(int) signal;
    void highlighted(const char *) signal;
    virtual void keyPressEvent(QKeyEvent *);
    virtual void mouseDoubleClickEvent(QMouseEvent *);
    virtual void mouseMoveEvent(QMouseEvent *);
    virtual void mousePressEvent(QMouseEvent *);
    virtual void mouseReleaseEvent(QMouseEvent *);
    virtual void paintEvent(QPaintEvent *);
    void popup();
    virtual void resizeEvent(QResizeEvent *);
} Qt::ComboBox;
