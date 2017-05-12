#include <qclipboard.h>

class QClipboard : QObject {
    void clear();
    QPixmap *pixmap() const;
    void setPixmap(const QPixmap &);
    void setText(const char *);
    const char *text() const;
protected:
    void dataChanged() signal;
private:
    ~QClipboard();
} Qt::Clipboard;
