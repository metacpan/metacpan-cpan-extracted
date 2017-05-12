#include <qgl.h>

virtual class QGLContext {
    QGLContext(const QGLFormat &, QPaintDevice *);
    virtual ~QGLContext();
    virtual bool create(const QGLContext * = 0);
    QPaintDevice *device() const;
    QGLFormat format() const;
    bool isSharing() const;
    bool isValid() const;
    virtual void makeCurrent();
    virtual void reset();
    virtual void setFormat(const QGLFormat &);
    virtual void swapBuffers();
protected:
    virtual bool chooseContext(const QGLContext * = 0);
;    virtual void *chooseVisual();
    bool deviceIsPixmap() const;
    virtual void doneCurrent();
    bool initialized() const;
    void setInitialized(bool);
    void setWindowCreated(bool);
;    virtual void *tryVisual(const QGLFormat &);
    bool windowCreated() const;
} Qt::GLContext;
