#include <qgl.h>
#include <qpixmap.h>

suicidal virtual class QGLWidget : virtual QWidget {
    QGLWidget(QWidget * = 0, const char * = 0, const QGLWidget * = 0, WFlags = 0);
    QGLWidget(const QGLFormat &, QWidget * = 0, const char * = 0, const QGLWidget * = 0, WFlags = 0);
    virtual ~QGLWidget();
    const QGLContext *context() const;
    bool doubleBuffer() const;
    QGLFormat format() const;
    bool isSharing() const;
    bool isValid() const;
    virtual void makeCurrent();
    virtual QPixmap renderPixmap(int = 0, int = 0, bool = FALSE);
    virtual void setContext(QGLContext *, const QGLContext * = 0, bool = TRUE);
    virtual void setFormat(const QGLFormat &);
    virtual void swapBuffers();
    virtual void updateGL() slot;
protected:
    bool autoBufferSwap() const;
    virtual void glDraw();
    virtual void glInit();
    virtual void initializeGL();
    virtual void paintEvent(QPaintEvent *);
    virtual void paintGL();
    virtual void resizeEvent(QResizeEvent *);
    virtual void resizeGL(int, int);
    void setAutoBufferSwap(bool);
} Qt::GLWidget;
