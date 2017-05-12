#include <qlayout.h>

suicidal class QBoxLayout : QLayout {
    enum Direction {
	LeftToRight,
	RightToLeft,
	TopToBottom,
	BottomToTop,
	Down,
	Up
    };
    QBoxLayout(QBoxLayout::Direction, int = -1, const char * = 0);
    QBoxLayout(QWidget *, QBoxLayout::Direction, int = 0, int = -1, const char * = 0);
    virtual ~QBoxLayout();
    void addLayout(QLayout *, int = 0);
    void addSpacing(int);
    void addStretch(int = 0);
    void addStrut(int);
    void addWidget(QWidget *, int = 0, int = AlignCenter);
    QBoxLayout::Direction direction() const;
} Qt::BoxLayout;
