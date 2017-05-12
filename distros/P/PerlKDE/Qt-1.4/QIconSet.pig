#include <qiconset.h>

struct QIconSet {
    enum Size {
	Automatic,
	Small,
	Large
    };
    enum Mode {
	Normal,
	Disabled,
	Active
    };
    QIconSet(const QPixmap &, QIconSet::Size = QIconSet::Automatic);
    QIconSet(const QIconSet &);
    virtual ~QIconSet();
    QIconSet &operator = (const QIconSet &);
    bool isGenerated(QIconSet::Size, QIconSet::Mode) const;
    QPixmap pixmap() const;
    QPixmap pixmap(QIconSet::Size, QIconSet::Mode) const;
    void reset(const QPixmap &, QIconSet::Size);
    void setPixmap(const char *, QIconSet::Size, QIconSet::Mode = QIconSet::Normal);
    void setPixmap(const QPixmap &, QIconSet::Size, QIconSet::Mode = QIconSet::Normal);
} Qt::IconSet;
