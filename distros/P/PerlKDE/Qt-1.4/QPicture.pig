#include <qpicture.h>

class QPicture : QPaintDevice {
    QPicture();
    virtual ~QPicture();
    const char * {qt_bits($this->size())} data() const;
    bool isNull() const;
    bool load(const char *);
    bool play(QPainter *);
    bool save(const char *);
    void setData(const char * {qt_bits}, uint {@qt_bitslen(1)});
    uint size() const;
} Qt::Picture;
