#include <qlayout.h>

suicidal class QGridLayout : QLayout {
    QGridLayout(int, int, int = -1, const char * = 0);
    QGridLayout(QWidget *, int, int, int = 0, int = -1, const char * = 0);
    virtual ~QGridLayout();
    void addLayout(QLayout *, int, int);
    void addMultiCellWidget(QWidget *, int, int, int, int, int = 0);
    void addColSpacing(int, int);
    void addRowSpacing(int, int);
    void addWidget(QWidget *, int, int, int = 0);
    void expand(int, int);
    int numCols() const;
    int numRows() const;
    void setColStretch(int, int);
    void setRowStretch(int, int);
} Qt::GridLayout;
