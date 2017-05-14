package MainWindow;

use strict;
use warnings;
use QtCore4;
use QtGui4;
use QtXmlPatterns4;
use Ui_MainWindow;
use QObjectXmlModel;
use QtCore4::isa qw( Qt::MainWindow );
use QtCore4::slots
    on_actionAbout_triggered => [];

use lib '../shared';
#use XmlSyntaxHighlighter;

sub ui() {
    return this->{ui};
}

sub NEW
{
    my ($class) = @_;
    $class->SUPER::NEW();
    this->{ui} = Ui_MainWindow->setupUi(this);

    #XmlSyntaxHighlighter(ui->wholeTreeOutput->document());

    # Setup the font.
    {
        my $font = Qt::Font('Courier');
        $font->setFixedPitch(1);

        ui->wholeTree->setFont($font);
        ui->wholeTreeOutput->setFont($font);
        ui->htmlQueryEdit->setFont($font);
    }

    my $namePool = Qt::XmlNamePool();
    my $qObjectModel = QObjectXmlModel(this, $namePool);
    my $query = Qt::XmlQuery($namePool);

    # The Qt::Object tree as XML view. 
    {
        $query->bindVariable('root', Qt::XmlItem($qObjectModel->root()));
        $query->setQuery(Qt::Url('qrc:/queries/wholeTree.xq'));

        die '$query is invalid' unless $query->isValid();
        my $output = Qt::ByteArray();
        my $buffer = Qt::Buffer($output);
        $buffer->open(Qt::IODevice::WriteOnly());

        # Let's the use the formatter, so it's a bit easier to read. 
        my $serializer = Qt::XmlFormatter($query, $buffer);

        $query->evaluateTo($serializer);
        $buffer->close();

        {
            my $queryFile = Qt::File(':/queries/wholeTree.xq');
            $queryFile->open(Qt::IODevice::ReadOnly());
            ui()->wholeTree->setPlainText($queryFile->readAll()->constData());
            ui()->wholeTreeOutput->setPlainText($output->constData());
        }
    }

    # The Qt::Object occurrence statistics as HTML view. 
    {
        $query->setQuery(Qt::Url('qrc:/queries/statisticsInHTML.xq'));
        die '$query is invalid' unless $query->isValid();

        my $output = Qt::ByteArray();
        my $buffer = Qt::Buffer($output);
        $buffer->open(Qt::IODevice::WriteOnly());

        # Let's the use the serializer, so we gain a bit of speed. 
        my $serializer = Qt::XmlSerializer($query, $buffer);

        $query->evaluateTo($serializer);
        $buffer->close();

        {
            my $queryFile = Qt::File(':/queries/statisticsInHTML.xq');
            $queryFile->open(Qt::IODevice::ReadOnly());
            ui()->htmlQueryEdit->setPlainText($queryFile->readAll()->constData());
            ui()->htmlOutput->setHtml($output->constData());
        }
    }
}

sub on_actionAbout_triggered
{
    Qt::MessageBox::about(this,
                       this->tr('About Qt::Object XML Model'),
                       this->tr('<p>The <b>Qt::Object XML Model</b> example shows ' .
                          'how to use XQuery on top of data of your choice ' .
                          'without converting it to an XML document.</p>' .
                          '<p>In this example a Qt::SimpleXmlNodeModel subclass ' .
                          'makes it possible to query a Qt::Object tree using ' .
                          'XQuery and retrieve the result as pointers to ' .
                          'Qt::Objects, or as XML.</p>' .
                          '<p>A possible use case of this could be to write ' .
                          'an application that tests a graphical interface ' .
                          'against Human Interface Guidelines, or that ' .
                          'queries an application\'s data which is modeled ' .
                          'using a Qt::Object tree and dynamic properties.'));
}

1;
