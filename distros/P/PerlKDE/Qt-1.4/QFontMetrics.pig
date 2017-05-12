#include <qfontmetrics.h>

struct QFontMetrics {
    QFontMetrics(const QFont &);
    QFontMetrics(const QFontMetrics &);
    ~QFontMetrics();
    QFontMetrics &operator = (const QFontMetrics &);
    int ascent() const;
    QRect boundingRect(char) const;
    QRect boundingRect(const char *, int = -1) const;
    QRect boundingRect(int, int, int, int, int, const char *, int = -1, int = 0, int *{intarray} = 0, char **{internal} = 0) const;
    int descent() const;
    int height() const;
    bool inFont(char) const;
    int leading() const;
    int leftBearing(char) const;
    int lineSpacing() const;
    int lineWidth() const;
    int maxWidth() const;
    int minLeftBearing() const;
    int minRightBearing() const;
    int rightBearing(char) const;
    QSize size(int, const char *, int = -1, int = 0, int *{intarray} = 0, char **{internal} = 0) const;
    int strikeOutPos() const;
    int underlinePos() const;
    int width(const char *, int = -1) const;
} Qt::FontMetrics;
