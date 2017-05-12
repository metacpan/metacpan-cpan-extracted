#include <qpaintdevicemetrics.h>

struct QPaintDeviceMetrics {
    QPaintDeviceMetrics(const QPaintDevice *);
    int depth() const;
    int height() const;
    int heightMM() const;
    int numColors() const;
    int width() const;
    int widthMM() const;
} Qt::PaintDeviceMetrics;
