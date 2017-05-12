#include <ktoolbar.h>

suicidal virtual class KToolBarButton : virtual QButton {
    KToolBarButton(QWidget * = 0L, const char * = 0L);
    KToolBarButton(const QPixmap &, int, QWidget *, const char * = 0L, int = 26, const char * = 0, bool = false);
    virtual ~KToolBarButton();
    void beToggle(bool);
    bool ImASeparator();
    void modeChange() slot;
    void on(bool);
    QPopupMenu *popup();
    void setDelayedPopup(QPopupMenu *);
    virtual void setEnabled(bool);
    virtual void setPixmap(const QPixmap &);
    void setPopup(QPopupMenu *);
    void setRadio(bool);
    virtual void setText(const char *);
    void toggle();
    void youreSeparator();
protected:
    void ButtonClicked() slot;
    void ButtonPressed() slot;
    void ButtonReleased() slot;
    void ButtonToggled() slot;
    void clicked(int) signal;
    void doubleClicked(int) signal;
    virtual void drawButton(QPainter *);
    virtual void enterEvent(QEvent *);
    virtual bool eventFilter(QObject *, QEvent *);
    void highlighted(int, bool) signal;
    virtual void leaveEvent(QEvent *);
    void makeDisabledPixmap();
    virtual void paletteChange(const QPalette &);
    void pressed(int) signal;
    void released(int) signal;
    void toggled(int) signal;
    void showMenu();
    void slotDelayTimeout() slot;
} KDE::ToolBarButton;
