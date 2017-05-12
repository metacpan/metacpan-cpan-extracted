#include <qgl.h>

struct QGLFormat {
    QGLFormat();
    QGLFormat(int);
    bool operator == (const QGLFormat &) : *$this == $1;
    bool operator != (const QGLFormat &) : *$this == $1;
    bool accum() const;
    bool alpha() const;
    static QGLFormat defaultFormat();
    bool depth() const;
    bool directRendering() const;
    bool doubleBuffer() const;
    static bool hasOpenGL();
    bool rgba() const;
    void setAccum(bool);
    void setAlpha(bool);
    static void setDefaultFormat(const QGLFormat &);
    void setDepth(bool);
    void setDirectRendering(bool);
    void setDoubleBuffer(bool);
    void setOption(QGL::FormatOption);
    void setRgba(bool);
    void setStencil(bool);
    void setStereo(bool);
    bool stencil() const;
    bool stereo() const;
    bool testOption(QGL::FormatOption) const;
} Qt::GLFormat;
