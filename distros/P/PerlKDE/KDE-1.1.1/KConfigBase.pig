#include <kconfig.h>

class KConfigBase {
;    KEntryIterator *entryIterator(const char *);
    const char *group() const;
;    KGroupIterator *groupIterator();
    bool hasKey(const char *) const;
    bool isDollarExpansion() const;
    bool readBoolEntry(const char *, bool = false) const;
    QColor readColorEntry(const char *, const QColor * = 0L) const;
    double readDoubleNumEntry(const char *, double = 0.0) const;
    const QString readEntry(const char *, const char * = 0L) const;
    QFont readFontEntry(const char *, const QFont * = 0L);
;    int readListEntry(const char *, QStrList &, char = ',') const;
    long readLongNumEntry(const char *, long = 0) const;
    int readNumEntry(const char *, int = 0) const;
    QPoint readPointEntry(const char *, const QPoint * = 0L) const;
    QRect readRectEntry(const char *, const QRect * = 0L) const;
    QSize readSizeEntry(const char *, const QSize * = 0L) const;
    long readUnsignedLongNumEntry(const char *, long = 0) const;
    uint readUnsignedNumEntry(const char *, uint = 0) const;
    void reparseConfiguration();
    void rollback(bool = true);
    void setDollarExpansion(bool = TRUE);
    void setGroup(const char *);
    void sync();

; I did my best with writeEntry, but I can't ever do signed/unsigned
; int/long differentiation

    const char *writeEntry(const char *, const char *, bool = true, bool = false, bool = false);
    void writeEntry(const char *, QStrList &, char = ',', bool = true, bool = false, bool = false);
    const char *writeEntry(const char *, double, bool = true, bool = false, bool = false);
    const char *writeEntry(const char *, int, bool = true, bool = false, bool = false);
    void writeEntry(const char *, const QColor &, bool = true, bool = false, bool = false);
    void writeEntry(const char *, const QFont &, bool = true, bool = false, bool = false);
    void writeEntry(const char *, const QPoint &, bool = true, bool = false, bool = false);
    void writeEntry(const char *, const QRect &, bool = true, bool = false, bool = false);
    void writeEntry(const char *, const QSize &, bool = true, bool = false, bool = false);

    const char *writeBoolEntry(const char *, bool, bool = true, bool = false, bool = false) : $this->writeEntry($1, $2, $3, $4, $5);
    const char *writeDoubleNumEntry(const char *, double, bool = true, bool = false, bool = false) : $this->writeEntry($1, $2, $3, $4, $5);
    void writeListEntry(const char *, QStrList &, char = ',', bool = true, bool = false, bool = false) : $this->writeEntry($1, $2, $3, $4, $5, $6);
    const char *writeLongNumEntry(const char *, long, bool = true, bool = false, bool = false) : $this->writeEntry($1, $2, $3, $4, $5);
    const char *writeNumEntry(const char *, int, bool = true, bool = false, bool = false) : $this->writeEntry($1, $2, $3, $4, $5);
    const char *writeUnsignedLongNumEntry(const char *, long, bool = true, bool = false, bool = false) : $this->writeEntry($1, (unsigned long)$2, $3, $4, $5);
    const char *writeUnsignedNumEntry(const char *, uint, bool = true, bool = false, bool = false) : $this->writeEntry($1, $2, $3, $4, $5);

    void writeColorEntry(const char *, const QColor &, bool = true, bool = false, bool = false) : $this->writeEntry($1, $2, $3, $4, $5);
    void writeFontEntry(const char *, const QFont &, bool = true, bool = false, bool = false) : $this->writeEntry($1, $2, $3, $4, $5);
    void writePointEntry(const char *, const QPoint &, bool = true, bool = false, bool = false) : $this->writeEntry($1, $2, $3, $4, $5);
    void writeRectEntry(const char *, const QRect &, bool = true, bool = false, bool = false) : $this->writeEntry($1, $2, $3, $4, $5);
    void writeSizeEntry(const char *, const QSize &, bool = true, bool = false, bool = false) : $this->writeEntry($1, $2, $3, $4, $5);
} KDE::ConfigBase;
