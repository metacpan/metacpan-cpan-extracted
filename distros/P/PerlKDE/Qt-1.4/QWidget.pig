#include <qwidget.h>

suicidal virtual class QWidget : virtual QObject, QPaintDevice {
    enum BackgroundMode {
	FixedColor,
	FixedPixmap,
	NoBackground,
	PaletteForeground,
	PaletteBackground,
	PaletteLight,
	PaletteMidlight,
	PaletteDark,
	PaletteMid,
	PaletteText,
	PaletteBase
    };
    enum FocusPolicy {
	NoFocus,
	TabFocus,
	ClickFocus,
	StrongFocus
    };
    enum PropagationMode {
	NoChildren,
	AllChildren,
	SameFont,
	SamePalette
    };
    QWidget(QWidget * = 0, const char * = 0, WFlags = 0);
    virtual ~QWidget();
    bool acceptDrops() const;
    virtual void adjustSize();
    const QColor &backgroundColor() const;
    QWidget::BackgroundMode backgroundMode() const;
    const QPixmap *backgroundPixmap() const;
    const char *caption() const;
    QRect childrenRect() const;
    void clearFocus();
    virtual bool close(bool = FALSE);
    const QColorGroup &colorGroup() const;
    const QCursor &cursor() const;
    void drawText(const QPoint &, const char *);
    void drawText(int, int, const char *);
    void erase();
    void erase(const QRect &);
    void erase(int, int, int, int);
    static QWidget *find(WId);
    QWidget::FocusPolicy focusPolicy() const;
    QWidget *focusProxy() const;
    QWidget *focusWidget() const;
    const QFont &font() const;
    QFontInfo fontInfo() const;
    QFontMetrics fontMetrics() const;
    QWidget::PropagationMode fontPropagation() const;
    const QColor &foregroundColor() const;
    const QRect &frameGeometry() const;
    const QRect &geometry() const;
    void grabKeyboard();
    void grabMouse();
    void grabMouse(const QCursor &);
    bool hasFocus() const;
    bool hasMouseTracking() const;
    int height() const;
    virtual void hide() slot;
    const QPixmap *icon() const;
    void iconify() slot;
    const char *iconText() const;
    bool isActiveWindow() const;
    bool isDesktop() const;
    bool isEnabled() const;
    bool isEnabledTo(QWidget *) const;
    bool isEnabledToTLW() const;
    bool isFocusEnabled() const;
    bool isModal() const;
    bool isPopup() const;
    bool isTopLevel() const;
    bool isUpdatesEnabled() const;
    bool isVisible() const;
    bool isVisibleTo(QWidget *) const;
    bool isVisibleToTLW() const;
    static QWidget *keyboardGrabber();
    void lower();
    QPoint mapFromGlobal(const QPoint &) const;
    QPoint mapFromParent(const QPoint &) const;
    QPoint mapToGlobal(const QPoint &) const;
    QPoint mapToParent(const QPoint &) const;
    QSize maximumSize() const;
    QSize minimumSize() const;
    static QWidget *mouseGrabber();
    void move(const QPoint &);
    virtual void move(int, int);
    const QPalette &palette() const;
    QWidget::PropagationMode palettePropagation() const;
    QWidget *parentWidget() const;
    QPoint pos() const;
    void raise();
    void recreate(QWidget *, WFlags, const QPoint &, bool = FALSE);
    QRect rect() const;
    void releaseKeyboard();
    void releaseMouse();
    void repaint(bool = TRUE) slot;
    void repaint(const QRect &, bool = TRUE) slot;
    void repaint(int, int, int, int, bool = TRUE) slot;
    void resize(const QSize &);
    virtual void resize(int, int);
    void scroll(int, int);
    void setAcceptDrops(bool);
    void setActiveWindow();
    virtual void setBackgroundColor(const QColor &);
    void setBackgroundMode(QWidget::BackgroundMode);
    virtual void setBackgroundPixmap(const QPixmap &);
    void setCaption(const char *);
    virtual void setCursor(const QCursor &);
    virtual void setEnabled(bool) slot;
    void setFixedHeight(int);
    void setFixedSize(const QSize &);
    void setFixedSize(int, int);
    void setFixedWidth(int);
    void setFocus();
    void setFocusPolicy(QWidget::FocusPolicy);
    void setFocusProxy(QWidget *);
    virtual void setFont(const QFont &);
    void setFontPropagation(QWidget::PropagationMode);
    void setGeometry(const QRect &);
    virtual void setGeometry(int, int, int, int);
    void setIcon(const QPixmap &);
    void setIconText(const char *);
    void setMaximumHeight(int);
    void setMaximumSize(const QSize &);
    void setMaximumSize(int, int);
    void setMaximumWidth(int);
    void setMinimumHeight(int);
    void setMinimumSize(const QSize &);
    void setMinimumSize(int, int);
    void setMinimumWidth(int);
    void setMouseTracking(bool) slot;
    virtual void setPalette(const QPalette &);
    void setPalettePropagation(QWidget::PropagationMode);
    void setSizeIncrement(const QSize &);
    void setSizeIncrement(int, int);
    virtual void setStyle(GUIStyle);
    static void setTabOrder(QWidget *, QWidget *);
    void setUpdatesEnabled(bool) slot;
    virtual void show() slot;
    QSize size() const;
    virtual QSize sizeHint() const;
    QSize sizeIncrement() const;
    GUIStyle style() const;
    bool testWFlags(WFlags) const;
    QWidget *topLevelWidget() const;
    void update() slot;
    void update(const QRect &) slot;
    void update(int, int, int, int) slot;
    int width() const;
    WId winId() const;
    int x() const;
    int y() const;
protected:
    virtual void backgroundColorChange(const QColor &);
    virtual void backgroundPixmapChange(const QPixmap &);
    void clearWFlags(WFlags);
    virtual void closeEvent(QCloseEvent *);
    void create(WId);
    void create(WId, bool, bool);
    void destroy(bool, bool);
    virtual void enabledChange(bool);
    virtual void enterEvent(QEvent *);
    virtual bool event(QEvent *);
    virtual void focusInEvent(QFocusEvent *);
    virtual bool focusNextPrevChild(bool);
    virtual void focusOutEvent(QFocusEvent *);
    virtual void fontChange(const QFont &);
    WFlags getWFlags() const;
    virtual void keyPressEvent(QKeyEvent *);
    virtual void keyReleaseEvent(QKeyEvent *);
    virtual void leaveEvent(QEvent *);
    int metric(int) const;
    virtual void mouseDoubleClickEvent(QMouseEvent *);
    virtual void mouseMoveEvent(QMouseEvent *);
    virtual void mousePressEvent(QMouseEvent *);
    virtual void mouseReleaseEvent(QMouseEvent *);
    virtual void moveEvent(QMoveEvent *);
    virtual void paintEvent(QPaintEvent *);
    virtual void paletteChange(const QPalette &);
    virtual void resizeEvent(QResizeEvent *);
    void setCRect(const QRect &);
    void setFRect(const QRect &);
    void setWFlags(WFlags);
    virtual void styleChange(GUIStyle);
} Qt::Widget;

enum GUIStyle {
    MacStyle,
    WindowsStyle,
    Win3Style,
    PMStyle,
    MotifStyle
};

extern const uint WState_Created;
extern const uint WState_Disabled;
extern const uint WState_Visible;
extern const uint WState_DoHide;
extern const uint WState_ClickToFocus;
extern const uint WState_TrackMouse;
extern const uint WState_BlockUpdates;
extern const uint WState_PaintEvent;
extern const uint WType_TopLevel;
extern const uint WType_Modal;
extern const uint WType_Popup;
extern const uint WType_Desktop;
extern const uint WStyle_Customize;
extern const uint WStyle_NormalBorder;
extern const uint WStyle_DialogBorder;
extern const uint WStyle_NoBorder;
extern const uint WStyle_Title;
extern const uint WStyle_SysMenu;
extern const uint WStyle_Minimize;
extern const uint WStyle_Maximize;
extern const uint WStyle_MinMax;
extern const uint WStyle_Tool;
extern const uint WStyle_Mask;
extern const uint WCursorSet;
extern const uint WDestructiveClose;
extern const uint WPaintDesktop;
extern const uint WPaintUnclipped;
extern const uint WPaintClever;
extern const uint WConfigPending;
extern const uint WResizeNoErase;
extern const uint WRecreated;
extern const uint WExportFontMetrics;
extern const uint WExportFontInfo;
extern const uint WFocusSet;
extern const uint WState_TabToFocus;
