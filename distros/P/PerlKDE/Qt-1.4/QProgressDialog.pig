#include <qprogressdialog.h>

suicidal virtual class QProgressDialog : virtual QSemiModal {
    QProgressDialog(QWidget * = 0, const char * = 0, bool = FALSE, WFlags = 0);
    QProgressDialog(const char *, const char *, int, QWidget * = 0, const char * = 0, bool = FALSE, WFlags = 0);
    virtual ~QProgressDialog();
    void cancel() slot;
    int progress() const;
    void reset() slot;
    void setBar(QProgressBar *);
    void setCancelButton(QPushButton *);
    void setCancelButtonText(const char *) slot;
    void setLabel(QLabel *);
    void setLabelText(const char *) slot;
    void setProgress(int) slot;
    void setTotalSteps(int) slot;
    virtual QSize sizeHint() const;
    int totalSteps() const;
    bool wasCancelled() const;
protected:
    void cancelled() signal;
    virtual void resizeEvent(QResizeEvent *);
    virtual void styleChange(GUIStyle);
} Qt::ProgressDialog;
