#include <qdragobject.h>

suicidal virtual class QDragObject : virtual QObject {
    enum DragMode {
	DragDefault,
	DragCopy,
	DragMove,
	DragCopyOrMove
    };
    QDragObject(QWidget * = 0, const char * = 0);
    virtual ~QDragObject();
    bool drag();
    void dragCopy();
    bool dragMove();
    abstract QByteArray encodedData(const char *) const;
    abstract const char *format(int) const;
    virtual bool provides(const char *) const;
    QWidget *source();
protected:
    virtual bool drag(QDragObject::DragMode);
} Qt::DragObject;
