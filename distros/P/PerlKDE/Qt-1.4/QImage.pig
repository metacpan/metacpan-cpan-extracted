#include <qimage.h>

struct QImage {
    enum Endian {
	IgnoreEndian,
	BigEndian,
	LittleEndian
    };
    QImage();
    QImage(const char ** {qt_xpm});
    QImage(const QImage &);
    QImage(const char *, const char * = 0);
    QImage(const QSize &, int, int = 0, QImage::Endian = QImage::IgnoreEndian);
    QImage(int, int, int, int = 0, QImage::Endian = QImage::IgnoreEndian);
    ~QImage();
    QImage &operator = (const QImage &);
    QImage &operator = (const QPixmap &);
    const char *{serial} operator << () const : pig_serialize($this);
    void operator >> (const char *{serial}) : pig_deserialize($this, $1);
    bool allGray() const;
    void bitBlt(int, int, const QImage *, int = 0, int = 0, int = -1, int = -1, int = 0) : bitBlt($this, $1, $2, $3, $4, $5, $6, $7, $8);
    QImage::Endian bitOrder() const;
    uchar *{qt_ubits} bits() const;
    int bytesPerLine() const;
    QRgb color(int) const;
    QRgb *colorTable() const;
    QImage convertBitOrder(QImage::Endian) const;
    QImage convertDepth(int) const;
    QImage convertDepth(int, int) const;
    QImage convertDepthWithPalette(int, QRgb *{intarray}, int {@intarrayitems(2)}, int = 0);
    QImage copy() const;
    QImage copy(QRect &) const;
    QImage copy(int, int, int, int, int = 0) const;
    bool create(const QSize &, int, int = 0, QImage::Endian = QImage::IgnoreEndian);
    bool create(int, int, int, int = 0, QImage::Endian = QImage::IgnoreEndian);
    QImage createAlphaMask(int) const;
    QImage createHeuristicMask(bool = TRUE) const;
    int depth() const;
    void detach();
    void fill(uint);
    bool hasAlphaBuffer() const;
    int height() const;
    static const char *imageFormat(const char *);
    static QStrList inputFormats();
    bool isGrayscale() const;
    bool isNull() const;
    uchar ** {qt_ubitsarray($this->height(), $this->width(), $this->bytesPerLine())} jumpTable() const;
    bool load(const char *, const char * = 0);
    bool loadFromData(QByteArray, const char *);
    int numBytes() const;
    int numColors() const;
    static QStrList outputFormats();
    QRgb pixel(int, int) const;
    int pixelIndex(int, int) const;
    QRect rect() const;
    void reset();
    bool save(const char *, const char *) const;
    uchar * {qt_ubits} scanLine(int) const;
    void setAlphaBuffer(bool);
    void setColor(int, QRgb);
    QImage smoothScale(int, int) const;
    void setNumColors(int);
    void setPixel(int, int, uint);
    QSize size() const;
    static QImage::Endian systemBitOrder();
    static QImage::Endian systemByteOrder();
    bool valid(int, int) const;
    int width() const;
} Qt::Image;
