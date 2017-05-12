#include <qfontinfo.h>

struct QFontInfo {
    QFontInfo(const QFont &);
    QFontInfo(const QFontInfo &);
    ~QFontInfo();
    QFontInfo &operator = (const QFontInfo &);
    bool bold() const;
    QFont::CharSet charSet() const;
    bool exactMatch() const;
    const char *family() const;
    bool fixedPitch() const;
    bool italic() const;
    int pointSize() const;
    bool rawMode() const;
    bool strikeOut() const;
    QFont::StyleHint styleHint() const;
    bool underline() const;
    int weight() const;
} Qt::FontInfo;
