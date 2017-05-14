package RSSListing;

use strict;
use warnings;
use QtCore4;
use QtGui4;
use QtNetwork4;
use QtCore4::isa qw( Qt::Widget );
use QtCore4::slots
    fetch => [],
    finished => ['int', 'bool'],
    readData => ['const QHttpResponseHeader &'],
    itemActivated => ['QTreeWidgetItem *'];

sub xml() {
    return this->{xml};
}

sub currentTag() {
    return this->{currentTag};
}

sub linkString() {
    return this->{linkString};
}

sub titleString() {
    return this->{titleString};
}

sub http() {
    return this->{http};
}

sub connectionId() {
    return this->{connectionId};
}

sub lineEdit() {
    return this->{lineEdit};
}

sub treeWidget() {
    return this->{treeWidget};
}

sub abortButton() {
    return this->{abortButton};
}

sub fetchButton() {
    return this->{fetchButton};
}

=begin

rsslisting.cpp

Provides a widget for displaying news items from RDF news sources.
RDF is an XML-based format for storing items of information (see
http://www.w3.org/RDF/ for details).

The widget itself provides a simple user interface for specifying
the URL of a news source, and controlling the downloading of news.

The widget downloads and parses the XML asynchronously, feeding the
data to an XML reader in pieces. This allows the user to interrupt
its operation, and also allows very large data sources to be read.

=cut

=begin

    Constructs an RSSListing widget with a simple user interface, and sets
    up the XML reader to use a custom handler class.

    The user interface consists of a line edit, two push buttons, and a
    list view widget. The line edit is used for entering the URLs of news
    sources; the push buttons start and abort the process of reading the
    news.

=cut

sub NEW
{
    my ($class, $parent) = @_;
    $class->SUPER::NEW($parent);
    this->{http} = Qt::Http();
    this->{xml} = Qt::XmlStreamReader();
    this->{lineEdit} = Qt::LineEdit(this);
    lineEdit->setText('http://labs.qt.nokia.com/blogs/feed');

    this->{fetchButton} = Qt::PushButton(this->tr('Fetch'), this);
    this->{abortButton} = Qt::PushButton(this->tr('Abort'), this);
    abortButton->setEnabled(0);

    this->{treeWidget} = Qt::TreeWidget(this);
    this->connect(treeWidget, SIGNAL 'itemActivated(QTreeWidgetItem*,int)',
            this, SLOT 'itemActivated(QTreeWidgetItem*)');
    my @headerLabels = (this->tr('Title'), this->tr('Link'));
    treeWidget->setHeaderLabels(\@headerLabels);
    treeWidget->header()->setResizeMode(Qt::HeaderView::ResizeToContents());

    this->connect(http, SIGNAL 'readyRead(QHttpResponseHeader)',
             this, SLOT 'readData(QHttpResponseHeader)');

    this->connect(http, SIGNAL 'requestFinished(int,bool)',
             this, SLOT 'finished(int,bool)');

    this->connect(lineEdit, SIGNAL 'returnPressed()', this, SLOT 'fetch()');
    this->connect(fetchButton, SIGNAL 'clicked()', this, SLOT 'fetch()');
    this->connect(abortButton, SIGNAL 'clicked()', http, SLOT 'abort()');

    my $layout = Qt::VBoxLayout(this);

    my $hboxLayout = Qt::HBoxLayout();

    $hboxLayout->addWidget(lineEdit);
    $hboxLayout->addWidget(fetchButton);
    $hboxLayout->addWidget(abortButton);

    $layout->addLayout($hboxLayout);
    $layout->addWidget(treeWidget);

    setWindowTitle(this->tr('RSS listing example'));
    resize(640,480);
}

=begin

    Starts fetching data from a news source specified in the line
    edit widget.

    The line edit is made read only to prevent the user from modifying its
    contents during the fetch; this is only for cosmetic purposes.
    The fetch button is disabled, and the abort button is enabled to allow
    the user to interrupt processing. The list view is cleared, and we
    define the last list view item to be 0, meaning that there are no
    existing items in the list.

    The HTTP handler is supplied with the raw contents of the line edit and
    a fetch is initiated. We keep the ID value returned by the HTTP handler
    for future reference.

=cut

sub fetch
{
    lineEdit->setReadOnly(1);
    fetchButton->setEnabled(0);
    abortButton->setEnabled(1);
    treeWidget->clear();

    xml->clear();

    my $url = Qt::Url(lineEdit->text());

    http->setHost($url->host());
    this->{connectionId} = http->get($url->path());
}

=begin

    Reads data received from the RDF source.

    We read all the available data, and pass it to the XML
    stream reader. Then we call the XML parsing function.

    If parsing fails for any reason, we abort the fetch.

=cut

sub readData
{
    my ($resp) = @_;
    if ($resp->statusCode() != 200) {
        http->abort();
    }
    else {
        xml->addData(http->readAll());
        parseXml();
    }
}

=begin

    Finishes processing an HTTP request.

    The default behavior is to keep the text edit read only.

    If an error has occurred, the user interface is made available
    to the user for further input, allowing a new fetch to be
    started.

    If the HTTP get request has finished, we make the
    user interface available to the user for further input.

=cut

sub finished
{
    my ($id, $error) = @_;
    if ($error) {
        print STDERR "Received error during HTTP fetch.\n";
        lineEdit->setReadOnly(0);
        abortButton->setEnabled(0);
        fetchButton->setEnabled(1);
    }
    elsif ($id == connectionId) {
        lineEdit->setReadOnly(0);
        abortButton->setEnabled(0);
        fetchButton->setEnabled(1);
    }
}


=begin

    Parses the XML data and creates treeWidget items accordingly.

=cut

sub parseXml()
{
    while (!xml->atEnd()) {
        xml->readNext();
        if (xml->isStartElement()) {
            if (xml->name()->toString() eq 'item') {
                this->{linkString} = xml->attributes()->value('rss:about')->toString();
            }
            this->{currentTag} = xml->name()->toString();
        } elsif (xml->isEndElement()) {
            if (xml->name()->toString() eq 'item') {

                my $item = Qt::TreeWidgetItem();
                $item->setText(0, titleString);
                $item->setText(1, linkString);
                treeWidget->addTopLevelItem($item);

                this->{titleString} = '';
                this->{linkString} = '';
            }

        } elsif (xml->isCharacters() && !xml->isWhitespace()) {
            if (currentTag eq 'title') {
                this->{titleString} .= xml->text()->toString();
            }
            elsif (currentTag eq 'link') {
                this->{linkString} .= xml->text()->toString();
            }
        }
    }
    if (xml->error() !=  Qt::XmlStreamReader::NoError() &&
      xml->error() != Qt::XmlStreamReader::PrematureEndOfDocumentError()) {
        print STDERR 'XML ERROR:' . xml->lineNumber() . ': ' . xml->errorString() . "\n";
        http->abort();
    }
}

=begin

    Open the link in the browser

=cut

sub itemActivated
{
    my ($item) = @_;
    Qt::DesktopServices::openUrl(Qt::Url($item->text(1)));
}

1;
