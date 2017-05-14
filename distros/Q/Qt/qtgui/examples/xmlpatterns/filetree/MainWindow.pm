package MainWindow;

use strict;
use warnings;
use QtCore4;
use QtGui4;
use QtXmlPatterns4;
use QtCore4::isa qw( Qt::MainWindow );
use FileTree;
use Ui_MainWindow;
use QtCore4::slots
    on_actionOpenDirectory_triggered => [],
    on_actionAbout_triggered => [],
    on_queryBox_currentIndexChanged => [];

use lib '../shared';
#use XmlSyntaxHighlighter;

sub ui() {
    return this->{ui};
}

sub m_namePool() {
    return this->{m_namePool};
}

sub m_fileTree() {
    return this->{m_fileTree};
}

sub m_fileNode() {
    return this->{m_fileNode};
}

# [0]
sub NEW {
    my ($class) = @_;
    $class->SUPER::NEW();
    this->{m_namePool} = Qt::XmlNamePool();
    this->{m_fileTree} = FileTree(m_namePool);
    this->{ui} = Ui_MainWindow->setupUi(this);

    #XmlSyntaxHighlighter(ui->fileTree->document());

    # Set up the font.
    {
        my $font = Qt::Font('Courier',10);
        $font->setFixedPitch(1);

        ui->fileTree->setFont($font);
        ui->queryEdit->setFont($font);
        ui->output->setFont($font);
    }

    my $dir = Qt::LibraryInfo::location(Qt::LibraryInfo::ExamplesPath()) . '/xmlpatterns/filetree';

    if (Qt::Dir($dir)->exists()) {
        loadDirectory($dir);
    }
    else {
        ui->fileTree->setPlainText(this->tr('Use the Open menu entry to select a directory.'));
    }

    my $queries = Qt::Dir(':/queries/', '*.xq')->entryList();

    foreach my $query ( @{$queries} ) {
        ui->queryBox->addItem($query);
    }

}
# [0]

# [2]
sub on_queryBox_currentIndexChanged
{
    my $queryFile = Qt::File(':/queries/' . ui->queryBox->currentText());
    $queryFile->open(Qt::IODevice::ReadOnly());

    ui->queryEdit->setPlainText($queryFile->readAll()->data());
    evaluateResult();
}
# [2]

# [3]
sub evaluateResult
{
    if (!defined ui->queryBox->currentText()) {
        return;
    }

    my $query = Qt::XmlQuery(m_namePool);
    $query->bindVariable('fileTree', Qt::XmlItem(m_fileNode));
    $query->setQuery(Qt::Url('qrc:/queries/' . ui->queryBox->currentText()));

    my $formatterOutput = Qt::ByteArray();
    my $buffer = Qt::Buffer($formatterOutput);
    $buffer->open(Qt::IODevice::WriteOnly());

    my $formatter = Qt::XmlFormatter($query, $buffer);
    $query->evaluateTo($formatter);

    ui->output->setText($formatterOutput->constData());
}
# [3]

# [1]
sub on_actionOpenDirectory_triggered
{
    my $directoryName = Qt::FileDialog::getExistingDirectory(this);
    if (defined $directoryName) {
        loadDirectory($directoryName);
    }
}
# [1]

# [4]
# [5]
sub loadDirectory
{
    my ($directory) = @_;
    die "Directory $directory does not exist." unless Qt::Dir($directory)->exists();

    this->{m_fileNode} = m_fileTree->nodeFor($directory);
# [5]

    my $query = Qt::XmlQuery(m_namePool);
    my $xmlItem = Qt::XmlItem(m_fileNode);
    $query->bindVariable('fileTree', $xmlItem );
    $query->setQuery(Qt::Url('qrc:/queries/wholeTree.xq'));

    my $output = Qt::ByteArray();
    my $buffer = Qt::Buffer($output);
    $buffer->open(Qt::IODevice::WriteOnly());

    my $formatter = Qt::XmlFormatter($query, $buffer);
    $query->evaluateTo($formatter);

    ui->treeInfo->setText(sprintf this->tr('Model of %s output as XML.'), $directory);
    ui->fileTree->setText($output->constData());
    evaluateResult();
# [6]    
}
# [6]    
# [4]

sub on_actionAbout_triggered
{
    Qt::MessageBox::about(this, this->tr('About File Tree'),
                   this->tr('<p>Select <b>File->Open Directory</b> and ' .
                      'choose a directory. The directory is then ' .
                      'loaded into the model, and the model is ' .
                      'displayed on the left as XML.</p>' .

                      '<p>From the query menu on the right, select ' .
                      'a query. The query is displayed and then run ' .
                      'on the model. The results are displayed below ' .
                      'the query.</p>'));
}

1;
