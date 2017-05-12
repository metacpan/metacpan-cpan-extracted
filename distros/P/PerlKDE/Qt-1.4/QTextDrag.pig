#include <qdragobject.h>

suicidal virtual class QTextDrag : virtual QDragObject {
    QTextDrag(const char *, QWidget * = 0, const char * = 0);
    QTextDrag(QWidget * = 0, const char * = 0);
    virtual ~QTextDrag();
    static bool canDecode(QDragMoveEvent *);
    static bool decode(QDropEvent *, QString &);
    void setText(const char *);
} Qt::TextDrag;
