#include <kbuttonbox.h>

suicidal virtual class KButtonBox : virtual QWidget {
    enum { VERTICAL, HORIZONTAL };
    KButtonBox(QWidget *, int = KButtonBox::HORIZONTAL, int = 0, int = 6);
    virtual ~KButtonBox();
    QPushButton *addButton(const char *, bool = FALSE);
    void addStretch(int = 1);
    void layout();
    virtual void resizeEvent(QResizeEvent *);
    virtual QSize sizeHint() const;
protected:
    QSize bestButtonSize() const;
    QSize buttonSizeHint(QPushButton *) const;
    void placeButtons();
} KDE::ButtonBox;
