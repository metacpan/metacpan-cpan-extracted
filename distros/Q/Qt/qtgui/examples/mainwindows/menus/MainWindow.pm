package MainWindow;

use strict;
use warnings;
use QtCore4;
use QtGui4;

# [0]
use QtCore4::isa qw( Qt::MainWindow );
# [0]

# [1]
use QtCore4::slots
    newFile => [],
    open => [],
    save => [],
    print => [],
    undo => [],
    redo => [],
    cut => [],
    copy => [],
    paste => [],
    bold => [],
    italic => [],
    leftAlign => [],
    rightAlign => [],
    justify => [],
    center => [],
    setLineSpacing => [],
    setParagraphSpacing => [],
    about => [],
    aboutQt => [];
# [1]

# [3]
sub getFileMenu() {
    return this->{fileMenu};
}

sub getEditMenu() {
    return this->{editMenu};
}

sub getFormatMenu() {
    return this->{formatMenu};
}

sub getHelpMenu() {
    return this->{helpMenu};
}

sub getAlignmentGroup() {
    return this->{alignmentGroup};
}

sub getNewAct() {
    return this->{newAct};
}

sub getOpenAct() {
    return this->{openAct};
}

sub getSaveAct() {
    return this->{saveAct};
}

sub getPrintAct() {
    return this->{printAct};
}

sub getExitAct() {
    return this->{exitAct};
}

sub getUndoAct() {
    return this->{undoAct};
}

sub getRedoAct() {
    return this->{redoAct};
}

sub getCutAct() {
    return this->{cutAct};
}

sub getCopyAct() {
    return this->{copyAct};
}

sub getPasteAct() {
    return this->{pasteAct};
}

sub getBoldAct() {
    return this->{boldAct};
}

sub getItalicAct() {
    return this->{italicAct};
}

sub getLeftAlignAct() {
    return this->{leftAlignAct};
}

sub getRightAlignAct() {
    return this->{rightAlignAct};
}

sub getJustifyAct() {
    return this->{justifyAct};
}

sub getCenterAct() {
    return this->{centerAct};
}

sub getSetLineSpacingAct() {
    return this->{setLineSpacingAct};
}

sub getSetParagraphSpacingAct() {
    return this->{setParagraphSpacingAct};
}

sub getAboutAct() {
    return this->{aboutAct};
}

sub getAboutQtAct() {
    return this->{aboutQtAct};
}

sub getInfoLabel() {
    return this->{infoLabel};
}

# [3]

# [0]
sub NEW {
    my ( $class ) = @_;
    $class->SUPER::NEW();
    my $widget = Qt::Widget();
    this->setCentralWidget($widget);
# [0]

# [1]
    my $topFiller = Qt::Widget();
    $topFiller->setSizePolicy(Qt::SizePolicy::Expanding(), Qt::SizePolicy::Expanding());

    my $infoLabel = this->{infoLabel} = Qt::Label(this->tr('<i>Choose a menu option, or right-click to ' .
                              'invoke a context menu</i>'));
    $infoLabel->setFrameStyle(Qt::Frame::StyledPanel() | Qt::Frame::Sunken());
    $infoLabel->setAlignment(Qt::AlignCenter());

    my $bottomFiller = Qt::Widget();
    $bottomFiller->setSizePolicy(Qt::SizePolicy::Expanding(), Qt::SizePolicy::Expanding());

    my $layout = Qt::VBoxLayout();
    $layout->setMargin(5);
    $layout->addWidget($topFiller);
    $layout->addWidget($infoLabel);
    $layout->addWidget($bottomFiller);
    $widget->setLayout($layout);
# [1]

# [2]
    this->createActions();
    this->createMenus();

    my $message = this->tr('A context menu is available by right-clicking');
    this->statusBar()->showMessage($message);

    this->setWindowTitle(this->tr('Menus'));
    this->setMinimumSize(160, 160);
    this->resize(480, 320);
}
# [2]

# [3]
sub contextMenuEvent {
    my ($event) = @_;
    my $menu = Qt::Menu(this);
    $menu->addAction(this->getCutAct);
    $menu->addAction(this->getCopyAct);
    $menu->addAction(this->getPasteAct);
    $menu->exec($event->globalPos());
}
# [3]

sub newFile()
{
    this->getInfoLabel->setText(this->tr('Invoked <b>File|New</b>'));
}

sub open()
{
    this->getInfoLabel->setText(this->tr('Invoked <b>File|Open</b>'));
}

sub save()
{
    this->getInfoLabel->setText(this->tr('Invoked <b>File|Save</b>'));
}

sub print()
{
    this->getInfoLabel->setText(this->tr('Invoked <b>File|Print</b>'));
}

sub undo()
{
    this->getInfoLabel->setText(this->tr('Invoked <b>Edit|Undo</b>'));
}

sub redo()
{
    this->getInfoLabel->setText(this->tr('Invoked <b>Edit|Redo</b>'));
}

sub cut()
{
    this->getInfoLabel->setText(this->tr('Invoked <b>Edit|Cut</b>'));
}

sub copy()
{
    this->getInfoLabel->setText(this->tr('Invoked <b>Edit|Copy</b>'));
}

sub paste()
{
    this->getInfoLabel->setText(this->tr('Invoked <b>Edit|Paste</b>'));
}

sub bold()
{
    this->getInfoLabel->setText(this->tr('Invoked <b>Edit|Format|Bold</b>'));
}

sub italic()
{
    this->getInfoLabel->setText(this->tr('Invoked <b>Edit|Format|Italic</b>'));
}

sub leftAlign()
{
    this->getInfoLabel->setText(this->tr('Invoked <b>Edit|Format|Left Align</b>'));
}

sub rightAlign()
{
    this->getInfoLabel->setText(this->tr('Invoked <b>Edit|Format|Right Align</b>'));
}

sub justify()
{
    this->getInfoLabel->setText(this->tr('Invoked <b>Edit|Format|Justify</b>'));
}

sub center()
{
    this->getInfoLabel->setText(this->tr('Invoked <b>Edit|Format|Center</b>'));
}

sub setLineSpacing()
{
    this->getInfoLabel->setText(this->tr('Invoked <b>Edit|Format|Set Line Spacing</b>'));
}

sub setParagraphSpacing()
{
    this->getInfoLabel->setText(this->tr('Invoked <b>Edit|Format|Set Paragraph Spacing</b>'));
}

sub about()
{
    this->getInfoLabel->setText(this->tr('Invoked <b>Help|About</b>'));
    Qt::MessageBox::about(this, this->tr('About Menu'),
            this->tr('The <b>Menu</b> example shows how to create ' .
               'menu-bar menus and context menus.'));
}

sub aboutQt()
{
    this->getInfoLabel->setText(this->tr('Invoked <b>Help|About Qt</b>'));
}

# [4]
sub createActions()
{
# [5]
    my $newAct = this->{newAct} = Qt::Action(this->tr('&New'), this);
    $newAct->setShortcuts(Qt::KeySequence::New());
    $newAct->setStatusTip(this->tr('Create a file'));
    this->connect($newAct, SIGNAL 'triggered()', this, SLOT 'newFile()');
# [4]

    my $openAct = this->{openAct} = Qt::Action(this->tr('&Open...'), this);
    $openAct->setShortcuts(Qt::KeySequence::Open());
    $openAct->setStatusTip(this->tr('Open an existing file'));
    this->connect($openAct, SIGNAL 'triggered()', this, SLOT 'open()');
# [5]

    my $saveAct = this->{saveAct} = Qt::Action(this->tr('&Save'), this);
    $saveAct->setShortcuts(Qt::KeySequence::Save());
    $saveAct->setStatusTip(this->tr('Save the document to disk'));
    this->connect($saveAct, SIGNAL 'triggered()', this, SLOT 'save()');

    my $printAct = this->{printAct} = Qt::Action(this->tr('&Print...'), this);
    $printAct->setShortcuts(Qt::KeySequence::Print());
    $printAct->setStatusTip(this->tr('Print the document'));
    this->connect($printAct, SIGNAL 'triggered()', this, SLOT 'print()');

    my $exitAct = this->{exitAct} = Qt::Action(this->tr('E&xit'), this);
    $exitAct->setShortcut(Qt::KeySequence(this->tr('Ctrl+Q')));
    $exitAct->setStatusTip(this->tr('Exit the application'));
    this->connect($exitAct, SIGNAL 'triggered()', this, SLOT 'close()');

    my $undoAct = this->{undoAct} = Qt::Action(this->tr('&Undo'), this);
    $undoAct->setShortcuts(Qt::KeySequence::Undo());
    $undoAct->setStatusTip(this->tr('Undo the last operation'));
    this->connect($undoAct, SIGNAL 'triggered()', this, SLOT 'undo()');

    my $redoAct = this->{redoAct} = Qt::Action(this->tr('&Redo'), this);
    $redoAct->setShortcuts(Qt::KeySequence::Redo());
    $redoAct->setStatusTip(this->tr('Redo the last operation'));
    this->connect($redoAct, SIGNAL 'triggered()', this, SLOT 'redo()');

    my $cutAct = this->{cutAct} = Qt::Action(this->tr('Cu&t'), this);
    $cutAct->setShortcuts(Qt::KeySequence::Cut());
    $cutAct->setStatusTip(this->tr('Cut the current selection\'s contents to the ' .
                            'clipboard'));
    this->connect($cutAct, SIGNAL 'triggered()', this, SLOT 'cut()');

    my $copyAct = this->{copyAct} = Qt::Action(this->tr('&Copy'), this);
    $copyAct->setShortcut(Qt::KeySequence(this->tr('Ctrl+C')));
    $copyAct->setStatusTip(this->tr('Copy the current selection\'s contents to the ' .
                             'clipboard'));
    this->connect($copyAct, SIGNAL 'triggered()', this, SLOT 'copy()');

    my $pasteAct = this->{pasteAct} = Qt::Action(this->tr('&Paste'), this);
    $pasteAct->setShortcuts(Qt::KeySequence::Paste());
    $pasteAct->setStatusTip(this->tr('Paste the clipboard\'s contents into the current ' .
                              'selection'));
    this->connect($pasteAct, SIGNAL 'triggered()', this, SLOT 'paste()');

    my $boldAct = this->{boldAct} = Qt::Action(this->tr('&Bold'), this);
    $boldAct->setCheckable(1);
    $boldAct->setShortcut(Qt::KeySequence(this->tr('Ctrl+B')));
    $boldAct->setStatusTip(this->tr('Make the text bold'));
    this->connect($boldAct, SIGNAL 'triggered()', this, SLOT 'bold()');

    my $boldFont = $boldAct->font();
    $boldFont->setBold(1);
    $boldAct->setFont($boldFont);

    my $italicAct = this->{italicAct} = Qt::Action(this->tr('&Italic'), this);
    $italicAct->setCheckable(1);
    $italicAct->setShortcut(Qt::KeySequence(this->tr('Ctrl+I')));
    $italicAct->setStatusTip(this->tr('Make the text italic'));
    this->connect($italicAct, SIGNAL 'triggered()', this, SLOT 'italic()');

    my $italicFont = $italicAct->font();
    $italicFont->setItalic(1);
    $italicAct->setFont($italicFont);

    my $setLineSpacingAct = this->{setLineSpacingAct} = Qt::Action(this->tr('Set &Line Spacing...'), this);
    $setLineSpacingAct->setStatusTip(this->tr('Change the gap between the lines of a ' .
                                       'paragraph'));
    this->connect($setLineSpacingAct, SIGNAL 'triggered()', this, SLOT 'setLineSpacing()');

    my $setParagraphSpacingAct = this->{setParagraphSpacingAct} = Qt::Action(this->tr('Set &Paragraph Spacing...'), this);
    $setLineSpacingAct->setStatusTip(this->tr('Change the gap between paragraphs'));
    this->connect($setParagraphSpacingAct, SIGNAL 'triggered()',
            this, SLOT 'setParagraphSpacing()');

    my $aboutAct = this->{aboutAct} = Qt::Action(this->tr('&About'), this);
    $aboutAct->setStatusTip(this->tr('Show the application\'s About box'));
    this->connect($aboutAct, SIGNAL 'triggered()', this, SLOT 'about()');

    my $aboutQtAct = this->{aboutQtAct} = Qt::Action(this->tr('About &Qt'), this);
    $aboutQtAct->setStatusTip(this->tr('Show the Qt4 library\'s About box'));
    this->connect($aboutQtAct, SIGNAL 'triggered()', qApp, SLOT 'aboutQt()');
    this->connect($aboutQtAct, SIGNAL 'triggered()', this, SLOT 'aboutQt()');

    my $leftAlignAct = this->{leftAlignAct} = Qt::Action(this->tr('&Left Align'), this);
    $leftAlignAct->setCheckable(1);
    $leftAlignAct->setShortcut(Qt::KeySequence(this->tr('Ctrl+L')));
    $leftAlignAct->setStatusTip(this->tr('Left align the selected text'));
    this->connect($leftAlignAct, SIGNAL 'triggered()', this, SLOT 'leftAlign()');

    my $rightAlignAct = this->{rightAlignAct} = Qt::Action(this->tr('&Right Align'), this);
    $rightAlignAct->setCheckable(1);
    $rightAlignAct->setShortcut(Qt::KeySequence(this->tr('Ctrl+R')));
    $rightAlignAct->setStatusTip(this->tr('Right align the selected text'));
    this->connect($rightAlignAct, SIGNAL 'triggered()', this, SLOT 'rightAlign()');

    my $justifyAct = this->{justifyAct} = Qt::Action(this->tr('&Justify'), this);
    $justifyAct->setCheckable(1);
    $justifyAct->setShortcut(Qt::KeySequence(this->tr('Ctrl+J')));
    $justifyAct->setStatusTip(this->tr('Justify the selected text'));
    this->connect($justifyAct, SIGNAL 'triggered()', this, SLOT 'justify()');

    my $centerAct = this->{centerAct} = Qt::Action(this->tr('&Center'), this);
    $centerAct->setCheckable(1);
    $centerAct->setShortcut(Qt::KeySequence(this->tr('Ctrl+E')));
    $centerAct->setStatusTip(this->tr('Center the selected text'));
    this->connect($centerAct, SIGNAL 'triggered()', this, SLOT 'center()');

# [6] //! [7]
    my $alignmentGroup = this->{alignmentGroup} = Qt::ActionGroup(this);
    $alignmentGroup->addAction($leftAlignAct);
    $alignmentGroup->addAction($rightAlignAct);
    $alignmentGroup->addAction($justifyAct);
    $alignmentGroup->addAction($centerAct);
    $leftAlignAct->setChecked(1);
# [6]
}
# [7]

# [8]
sub createMenus {
# [9] //! [10]
    my $fileMenu = this->{fileMenu} = this->menuBar()->addMenu(this->tr('&File'));
    $fileMenu->addAction(this->getNewAct);
# [9]
    $fileMenu->addAction(this->getOpenAct);
# [10]
    $fileMenu->addAction(this->getSaveAct);
    $fileMenu->addAction(this->getPrintAct);
# [11]
    $fileMenu->addSeparator();
# [11]
    $fileMenu->addAction(this->getExitAct);

    my $editMenu = this->{editMenu} = this->menuBar()->addMenu(this->tr('&Edit'));
    $editMenu->addAction(this->getUndoAct);
    $editMenu->addAction(this->getRedoAct);
    $editMenu->addSeparator();
    $editMenu->addAction(this->getCutAct);
    $editMenu->addAction(this->getCopyAct);
    $editMenu->addAction(this->getPasteAct);
    $editMenu->addSeparator();

    my $helpMenu = this->{helpMenu} = this->menuBar()->addMenu(this->tr('&Help'));
    $helpMenu->addAction(this->getAboutAct);
    $helpMenu->addAction(this->getAboutQtAct);
# [8]

# [12]
    my $formatMenu = this->{formatMenu} = $editMenu->addMenu(this->tr('&Format'));
    $formatMenu->addAction(this->getBoldAct);
    $formatMenu->addAction(this->getItalicAct);
    $formatMenu->addSeparator()->setText(this->tr('Alignment'));
    $formatMenu->addAction(this->getLeftAlignAct);
    $formatMenu->addAction(this->getRightAlignAct);
    $formatMenu->addAction(this->getJustifyAct);
    $formatMenu->addAction(this->getCenterAct);
    $formatMenu->addSeparator();
    $formatMenu->addAction(this->getSetLineSpacingAct);
    $formatMenu->addAction(this->getSetParagraphSpacingAct);
}
# [12]

1;
