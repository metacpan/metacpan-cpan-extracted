#include <qmovie.h>

struct QMovie {
    enum Status {
	SourceEmpty,
	UnrecognizedFormat,
	Paused,
	EndOfFrame,
	EndOfLoop,
	EndOfMovie,
	SpeedChanged
    };
    QMovie();
    QMovie(const QMovie &);
    QMovie(const char *, int = 1024);
    QMovie(QByteArray, int = 1024);
    ~QMovie();
    QMovie &operator = (const QMovie &);
    const QColor &backgroundColor() const;
    void connectResize(QObject *{receiver(2)}, const char *{member(1)});
    void connectStatus(QObject *{receiver(2)}, const char *{member(1)});
    void connectUpdate(QObject *{receiver(2)}, const char *{member(1)});
    void disconnectResize(QObject *{unreceiver(2)}, const char *{member(1)});
    void disconnectStatus(QObject *{unreceiver(2)}, const char *{member(1)} = 0);
    void disconnectUpdate(QObject *{unreceiver(2)}, const char *{member(1)});
    bool finished() const;
    int frameNumber() const;
    const QPixmap &framePixmap() const;
    const QRect &getValidRect() const;
    bool isNull() const;
    void pause();
    bool paused() const;
    void restart();
    bool running() const;
    void setBackgroundColor(const QColor &);
    void setSpeed(int);
    int speed() const;
    void step();
    void step(int);
    int steps() const;
    void unpause();
} Qt::Movie;
