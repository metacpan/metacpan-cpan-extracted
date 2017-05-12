#include <qpixmap.h>

struct QPixmap : QPaintDevice {
    enum ColorMode {
	Auto,
	Color,
	Mono
    };
    enum Optimization {
	NoOptim,
	NormalOptim,
	BestOptim
    };
    QPixmap();
    QPixmap(const char ** {qt_xpm});
    QPixmap(const QPixmap &);
    QPixmap(const QSize &, int = -1);
    QPixmap(int, int, int = -1);
    QPixmap(const char *, const char *, int);
    virtual ~QPixmap();
    QPixmap &operator = (const QImage &);
    QPixmap &operator = (const QPixmap &);
    const char *{serial} operator << () const : pig_serialize($this);
    void operator >> (const char *{serial}) : pig_deserialize($this, $1);
    bool convertFromImage(const QImage &, int);
    QImage convertToImage() const;
    QBitmap createHeuristicMask(bool = TRUE) const;
    static int defaultDepth();
    static QPixmap::Optimization defaultOptimization();
    int depth() const;
    void detach();
    void fill(const QColor & = white);
    void fill(const QWidget *, const QPoint &);
    void fill(const QWidget *, int, int);
    static QPixmap grabWindow(WId, int = 0, int = 0, int = -1, int = -1);
    int height() const;
    static const char *imageFormat(const char *);
    static bool isGloballyOptimized();
    bool isNull() const;
    bool isOptimized() const;
    bool isQBitmap() const;
    bool load(const char *, const char *, int);
    bool loadFromData(QByteArray, const char * = 0, int = 0);
    const QBitmap *mask() const;
    QPixmap::Optimization optimization() const;
    void optimize(bool);
    static void optimizeGlobally(bool);
    QRect rect() const;
    void resize(const QSize &);
    void resize(int, int);
    bool save(const char *, const char *) const;
    bool selfMask() const;
    int serialNumber() const;
    static void setDefaultOptimization(QPixmap::Optimization);
    void setMask(const QBitmap &);
    void setOptimization(QPixmap::Optimization);
    QSize size() const;
    static QWMatrix trueMatrix(const QWMatrix &, int, int);
    int width() const;
    QPixmap xForm(const QWMatrix &) const;
} Qt::Pixmap;
