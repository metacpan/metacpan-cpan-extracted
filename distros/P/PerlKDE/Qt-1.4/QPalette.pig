#include <qpalette.h>

struct QPalette {
    QPalette();
    QPalette(const QColor &);
    QPalette(const QPalette &);
    QPalette(const QColorGroup &, const QColorGroup &, const QColorGroup &);
    ~QPalette();
    QPalette &operator = (const QPalette &);
    bool operator == (const QPalette &) const;
    bool operator != (const QPalette &) const;
    const char *{serial} operator << () const : pig_serialize($this);
    void operator >> (const char *{serial}) : pig_deserialize($this, $1);
    const QColorGroup &active() const;
    QPalette copy() const;
    const QColorGroup &disabled() const;
    bool isCopyOf(const QPalette &);
    const QColorGroup &normal() const;
    int serialNumber() const;
    void setActive(const QColorGroup &);
    void setDisabled(const QColorGroup &);
    void setNormal(const QColorGroup &);
} Qt::Palette;
