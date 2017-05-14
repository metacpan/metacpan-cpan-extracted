package HttpWindow;

use strict;
use warnings;
use QtCore4;
use QtGui4;
use QtNetwork4;
use QtCore4::isa qw( Qt::Dialog );
use QtCore4::slots
    downloadFile => [],
    cancelDownload => [],
    httpRequestFinished => ['int', 'bool'],
    readResponseHeader => ['const QHttpResponseHeader &'],
    updateDataReadProgress => ['int', 'int',],
    enableDownloadButton => [],
    slotAuthenticationRequired => ['const QString &', 'quint16', 'QAuthenticator *'],
    sslErrors => ['const QList<QSslError> &'];
use Ui_Dialog;

sub statusLabel() {
    return this->{statusLabel};
}

sub urlLabel() {
    return this->{urlLabel};
}

sub urlLineEdit() {
    return this->{urlLineEdit};
}

sub progressDialog() {
    return this->{progressDialog};
}

sub downloadButton() {
    return this->{downloadButton};
}

sub quitButton() {
    return this->{quitButton};
}

sub buttonBox() {
    return this->{buttonBox};
}

sub http() {
    return this->{http};
}

sub file() {
    return this->{file};
}

sub httpGetId() {
    return this->{httpGetId};
}

sub httpRequestAborted() {
    return this->{httpRequestAborted};
}

sub NEW
{
    my ($class, $parent) = @_;
    $class->SUPER::NEW($parent);
    this->{urlLineEdit} = Qt::LineEdit('https://');

    this->{urlLabel} = Qt::Label(this->tr('&URL:'));
    urlLabel->setBuddy(urlLineEdit);
    this->{statusLabel} = Qt::Label(this->tr('Please enter the URL of a file you want to ' .
                                'download.'));

    this->{downloadButton} = Qt::PushButton(this->tr('Download'));
    downloadButton->setDefault(1);
    this->{quitButton} = Qt::PushButton(this->tr('Quit'));
    quitButton->setAutoDefault(0);

    this->{buttonBox} = Qt::DialogButtonBox();
    buttonBox->addButton(downloadButton, Qt::DialogButtonBox::ActionRole());
    buttonBox->addButton(quitButton, Qt::DialogButtonBox::RejectRole());

    this->{progressDialog} = Qt::ProgressDialog(this);

    this->{http} = Qt::Http(this);

    this->connect(urlLineEdit, SIGNAL 'textChanged(QString)',
            this, SLOT 'enableDownloadButton()');
    this->connect(http, SIGNAL 'requestFinished(int,bool)',
            this, SLOT 'httpRequestFinished(int,bool)');
    this->connect(http, SIGNAL 'dataReadProgress(int,int)',
            this, SLOT 'updateDataReadProgress(int,int)');
    this->connect(http, SIGNAL 'responseHeaderReceived(QHttpResponseHeader)',
            this, SLOT 'readResponseHeader(QHttpResponseHeader)');
    this->connect(http, SIGNAL 'authenticationRequired(QString,quint16,QAuthenticator*)',
            this, SLOT 'slotAuthenticationRequired(QString,quint16,QAuthenticator*)');
    this->connect(http, SIGNAL 'sslErrors(QList<QSslError>)',
            this, SLOT 'sslErrors(QList<QSslError>)');
    this->connect(progressDialog, SIGNAL 'canceled()', this, SLOT 'cancelDownload()');
    this->connect(downloadButton, SIGNAL 'clicked()', this, SLOT 'downloadFile()');
    this->connect(quitButton, SIGNAL 'clicked()', this, SLOT 'close()');

    my $topLayout = Qt::HBoxLayout();
    $topLayout->addWidget(urlLabel);
    $topLayout->addWidget(urlLineEdit);

    my $mainLayout = Qt::VBoxLayout();
    $mainLayout->addLayout($topLayout);
    $mainLayout->addWidget(statusLabel);
    $mainLayout->addWidget(buttonBox);
    this->setLayout($mainLayout);

    setWindowTitle(this->tr('HTTP'));
    urlLineEdit->setFocus();
}

sub downloadFile
{
    my $url = Qt::Url(urlLineEdit->text());
    my $fileInfo = Qt::FileInfo($url->path());
    my $fileName = $fileInfo->fileName();
    if (!defined $fileName) {
        $fileName = 'index.html';
    }

    if (Qt::File::exists($fileName)) {
        if (Qt::MessageBox::question(this, this->tr('HTTP'), 
                         sprintf( this->tr('There already exists a file called %s in ' .
                                     'the current directory. Overwrite?'), $fileName ),
                                  Qt::MessageBox::Yes()|Qt::MessageBox::No(), Qt::MessageBox::No())
            == Qt::MessageBox::No()) {
            return;
        }
        Qt::File::remove($fileName);
    }

    this->{file} = Qt::File($fileName);
    if (!file->open(Qt::IODevice::WriteOnly())) {
        Qt::MessageBox::information(this, this->tr('HTTP'),
                         sprintf this->tr('Unable to save the file %s: %s.'),
                                 $fileName, file->errorString());
        this->{file} = undef;
        return;
    }

    my $mode = lc($url->scheme()) eq 'https' ? Qt::Http::ConnectionModeHttps() : Qt::Http::ConnectionModeHttp();
    http->setHost($url->host(), $mode, $url->port() == -1 ? 0 : $url->port());
    
    if (!defined $url->userName()) {
        http->setUser($url->userName(), $url->password());
    }

    this->{httpRequestAborted} = 0;
    my $path = Qt::Url::toPercentEncoding($url->path(), Qt::ByteArray('!$&\'()*+,;=:@/'));
    if ($path->isEmpty()) {
        $path->append('/');
    }
    this->{httpGetId} = http->get($path->constData(), file);

    progressDialog->setWindowTitle(this->tr('HTTP'));
    progressDialog->setLabelText(sprintf this->tr('Downloading %s.'), $fileName);
    downloadButton->setEnabled(0);
}

sub cancelDownload
{
    statusLabel->setText(this->tr('Download canceled.'));
    this->{httpRequestAborted} = 1;
    http->abort();
    downloadButton->setEnabled(1);
}

sub httpRequestFinished
{
    my ($requestId, $error) = @_;
    if ($requestId != httpGetId) {
        return;
    }
    if (httpRequestAborted) {
        if (file) {
            file->close();
            file->remove();
            this->{file} = undef;
        }

        progressDialog->hide();
        return;
    }

    if ($requestId != httpGetId) {
        return;
    }

    progressDialog->hide();
    file->close();

    if ($error) {
        file->remove();
        Qt::MessageBox::information(this, this->tr('HTTP'),
                         sprintf this->tr('Download failed: %s.'),
                                 http->errorString());
    } else {
        my $fileName = Qt::FileInfo(Qt::Url(urlLineEdit->text())->path())->fileName();
        statusLabel->setText(sprintf this->tr('Downloaded %s to current directory.'), $fileName);
    }

    downloadButton->setEnabled(1);
    this->{file} = undef;
}

sub readResponseHeader
{
    my ($responseHeader) = @_;
    my $code = $responseHeader->statusCode();
    if ( 
    $code == 200 ||                   # Ok
    $code == 301 ||                   # Moved Permanently
    $code == 302 ||                   # Found
    $code == 303 ||                   # See Other
    $code == 307 ) {                  # Temporary Redirect
        # these are not error conditions
    }
    else {
        Qt::MessageBox::information(this, this->tr('HTTP'),
                         sprintf this->tr('Download failed: %s.'),
                                 $responseHeader->reasonPhrase());
        this->{httpRequestAborted} = 1;
        progressDialog->hide();
        http->abort();
    }
}

sub updateDataReadProgress
{
    my ($bytesRead, $totalBytes) = @_;
    if (httpRequestAborted) {
        return;
    }

    progressDialog->setMaximum($totalBytes);
    progressDialog->setValue($bytesRead);
}

sub enableDownloadButton
{
    downloadButton->setEnabled(urlLineEdit->text());
}

sub slotAuthenticationRequired
{
    my ($hostName, $foo, $authenticator) = @_;
    my $dlg = Qt::Dialog();
    my $ui = Ui_Dialog->setupUi($dlg);
    $ui->setupUi($dlg);
    $dlg->adjustSize();
    $ui->siteDescription->setText(sprintf this->tr('%s at %s'), $authenticator->realm(), $hostName);
    
    if ($dlg->exec() == Qt::Dialog::Accepted()) {
        $authenticator->setUser($ui->userEdit->text());
        $authenticator->setPassword($ui->passwordEdit->text());
    }
}

sub sslErrors
{
    my ($errors) = @_;
    my $errorString;
    foreach my $error ( @{$errors} ) {
        if (defined $errorString) {
            $errorString .= ', ';
        }
        $errorString .= $error->errorString();
    }
    
    if (Qt::MessageBox::warning(this, this->tr('HTTP Example'),
                     sprintf( this->tr('One or more SSL errors has occurred: %s'), $errorString),
                             Qt::MessageBox::Ignore() | Qt::MessageBox::Abort()) == Qt::MessageBox::Ignore()) {
        http->ignoreSslErrors();
    }
}

1;
