#include <qfont.h>

struct QFont {
    enum StyleHint {
	Helvetica,
	Times,
	Courier,
	OldEnglish,
	System,
	AnyStyle,
	SansSerif,
	Serif,
	TypeWriter,
	Decorative
    };
    enum Weight {
	Light,
	Normal,
	DemiBold,
	Bold,
	Black
    };
    enum CharSet {
	Latin1, ISO_8859_1,
	AnyCharSet,
	Latin2, ISO_8859_2,
	Latin3, ISO_8859_3,
	Latin4, ISO_8859_4,
	Latin5, ISO_8859_5,
	Latin6, ISO_8859_6,
	Latin7, ISO_8859_7,
	Latin8, ISO_8859_8,
	Latin9, ISO_8859_9,
	KOI8R
    };
    QFont();
    QFont(const QFont &);
    QFont(const char *, int = 12, int = QFont::Normal, bool = FALSE);
    QFont(const char *, int, int, bool, QFont::CharSet);
    virtual ~QFont();
    QFont &operator = (const QFont &);
    bool operator == (const QFont &) const;
    bool operator != (const QFont &) const;
    const char *{serial} operator << () const : pig_serialize($this);
    void operator >> (const char *{serial}) : pig_deserialize($this, $1);
    bool bold() const;
    QFont::CharSet charSet() const;
    static const QFont &defaultFont();
    bool exactMatch() const;
    const char *family() const;
    bool fixedPitch() const;
    HANDLE handle(HANDLE = 0) const;
    static void insertSubstitution(const char *, const char *);
    bool isCopyOf(const QFont &) const;
    bool italic() const;
    QString key() const;
    static void listSubstitutions(QStrList *);
    int pointSize() const;
    bool rawMode() const;
    static void removeSubstitution(const char *);
    void setBold(bool);
    void setCharSet(QFont::CharSet);
    static void setDefaultFont(const QFont &);
    void setFamily(const char *);
    void setFixedPitch(bool);
    void setItalic(bool);
    void setPointSize(int);
    void setRawMode(bool);
    void setStrikeOut(bool);
    void setStyleHint(QFont::StyleHint);
    void setUnderline(bool);
    void setWeight(int);
    bool strikeOut() const;
    QFont::StyleHint styleHint() const;
    static const char *substitute(const char *);
    bool underline() const;
    int weight() const;
protected:
    int deciPointSize() const;
    QString defaultFamily() const;
    bool dirty() const;
    QString lastResortFamily() const;
    QString lastResortFont() const;
} Qt::Font;
