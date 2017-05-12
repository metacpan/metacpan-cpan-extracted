#include <qcursor.h>

struct QCursor {
    QCursor();
    QCursor(int);
    QCursor(const QCursor &);
    QCursor(const QBitmap &, const QBitmap &, int = -1, int = -1);
    ~QCursor();
    QCursor &operator = (const QCursor &);
    const char *{serial} operator << () const : pig_serialize($this);
    void operator >> (const char *{serial}) : pig_deserialize($this, $1);
    const QBitmap *bitmap() const;
    HANDLE handle() const;
    QPoint hotSpot() const;
    const QBitmap *mask() const;
    static QPoint pos();
    static void setPos(const QPoint &);
    static void setPos(int, int);
    void setShape(int);
    int shape() const;
} Qt::Cursor;

extern const QCursor arrowCursor;
extern const QCursor upArrowCursor;
extern const QCursor crossCursor;
extern const QCursor waitCursor;
extern const QCursor ibeamCursor;
extern const QCursor sizeVerCursor;
extern const QCursor sizeHorCursor;
extern const QCursor sizeBDiagCursor;
extern const QCursor sizeFDiagCursor;
extern const QCursor sizeAllCursor;
extern const QCursor blankCursor;

enum QCursorShape {
    ArrowCursor,
    UpArrowCursor,
    CrossCursor,
    WaitCursor,
    IbeamCursor,
    SizeVerCursor,
    SizeHorCursor,
    SizeBDiagCursor,
    SizeFDiagCursor,
    SizeAllCursor,
    BlankCursor,
    LastCursor,
    BitmapCursor
};
