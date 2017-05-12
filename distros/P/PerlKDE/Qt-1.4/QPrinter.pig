#include <qprinter.h>

class QPrinter : QPaintDevice {
    enum ColorMode { GrayScale, Color };
    enum Orientation { Portrait, Landscape };
    enum PageOrder { FirstPageFirst, LastPageFirst };
    enum PageSize {
	A4,
	B5,
	Letter,
	Legal,
	Executive
    };
    QPrinter();
    virtual ~QPrinter();
    bool abort();
    bool aborted() const;
    const char *creator() const;
    const char *docName() const;
    int fromPage() const;
    int maxPage() const;
    int minPage() const;
    bool newPage();
    int numCopies() const;
    QPrinter::Orientation orientation() const;
    const char *outputFileName() const;
    bool outputToFile() const;
    QPrinter::PageOrder pageOrder() const;
    QPrinter::PageSize pageSize() const;
    const char *printerName() const;
    const char *printProgram() const;
    void setColorMode(QPrinter::ColorMode);
    void setCreator(const char *);
    void setDocName(const char *);
    void setFromTo(int, int);
    void setMinMax(int, int);
    void setNumCopies(int);
    void setOrientation(QPrinter::Orientation);
    void setOutputFileName(const char *);
    void setOutputToFile(bool);
    void setPageOrder(QPrinter::PageOrder);
    void setPageSize(QPrinter::PageSize);
    void setPrintProgram(const char *);
    void setPrinterName(const char *);
    void setup(QWidget * = 0);
    int toPage() const;
} Qt::Printer;
