package MainWindow;

use Qt;
use Qt::QString;
#use blib;
use Qt::QApplication;
use Qt::QMainWindow;
use Qt::QWidget;
use Qt::QFont;
use Qt::QAction;
use Qt::QActionGroup;
use Qt::QKeySequence;
use Qt::QLabel;
use Qt::QMenu;
use Qt::QMenuBar;
use Qt::QStatusBar;
use Qt::QSizePolicy;
use Qt::QBoxLayout;

our @ISA = qw(Qt::QMainWindow);
our @EXPORT = qw(MainWindow);


sub MainWindow {
    my $class = 'MainWindow';
    my @signals = ();
    my @slots = ('newFile()','open_()','save()','print_()','undo()','redo()','cut()','copy()','paste()','bold()','italic()',
	'leftAlign()','rightAlign()','justify()','center()','setLineSpacing()','setParagraphSpacing()','about()','aboutQt()');
    my $this = QMainWindow(\@signals, \@slots);
    bless $this, $class;

    $this->{widget} = QWidget();
    $this->setCentralWidget($this->{widget});

    $this->{topFiller} = QWidget();
    $this->{topFiller}->setSizePolicy(Qt::QSizePolicy::Expanding, Qt::QSizePolicy::Expanding);

    $this->{infoLabel} = QLabel(QString('<i>Choose a menu option, or right-click to '.
                              'invoke a context menu</i>'));
    $this->{infoLabel}->setFrameStyle(Qt::QFrame::StyledPanel | Qt::QFrame::Sunken);
    $this->{infoLabel}->setAlignment(Qt::AlignCenter);

    $this->{bottomFiller} = QWidget();
    $this->{bottomFiller}->setSizePolicy(Qt::QSizePolicy::Expanding, Qt::QSizePolicy::Expanding);

    $this->{layout} = QVBoxLayout();
    $this->{layout}->setMargin(5);
    $this->{layout}->addWidget($this->{topFiller});
    $this->{layout}->addWidget($this->{infoLabel});
    $this->{layout}->addWidget($this->{bottomFiller});
    $this->{widget}->setLayout($this->{layout});

    $this->createActions();
    $this->createMenus();

    $message = QString("A context menu is available by right-clicking");
    $this->statusBar()->showMessage($message);

    $this->setWindowTitle(QString("Menus"));
    $this->setMinimumSize(160, 160);
    $this->resize(480, 320);
    
    return $this;
}

sub contextMenuEvent {
    my $this = shift;
    my $event = shift;
    $this->{menu} = QMenu($this);
    $this->{menu}->addAction($this->{cutAct});
    $this->{menu}->addAction($this->{copyAct});
    $this->{menu}->addAction($this->{pasteAct});
    $this->{menu}->exec($event->globalPos());
}

sub newFile {
    my $this = shift;
    $this->{infoLabel}->setText(QString('Invoked <b>File|New</b>'));
}

sub open_ {
    my $this = shift;
    $this->{infoLabel}->setText(QString('Invoked <b>File|Open</b>'));
}

sub save {
    my $this = shift;
    $this->{infoLabel}->setText(QString('Invoked <b>File|Save</b>'));
}

sub print_ {
    my $this = shift;
    $this->{infoLabel}->setText(QString('Invoked <b>File|Print</b>'));
}

sub undo {
    my $this = shift;
    $this->{infoLabel}->setText(QString('Invoked <b>Edit|Undo</b>'));
}

sub redo {
    my $this = shift;
    $this->{infoLabel}->setText(QString('Invoked <b>Edit|Redo</b>'));
}

sub cut {
    my $this = shift;
    $this->{infoLabel}->setText(QString('Invoked <b>Edit|Cut</b>'));
}

sub copy {
    my $this = shift;
    $this->{infoLabel}->setText(QString('Invoked <b>Edit|Copy</b>'));
}

sub paste {
    my $this = shift;
    $this->{infoLabel}->setText(QString('Invoked <b>Edit|Paste</b>'));
}

sub bold {
    my $this = shift;
    $this->{infoLabel}->setText(QString('Invoked <b>Edit|Format|Bold</b>'));
}

sub italic {
    my $this = shift;
    $this->{infoLabel}->setText(QString('Invoked <b>Edit|Format|Italic</b>'));
}

sub leftAlign {
    my $this = shift;
    $this->{infoLabel}->setText(QString('Invoked <b>Edit|Format|Left Align</b>'));
}

sub rightAlign {
    my $this = shift;
    $this->{infoLabel}->setText(QString('Invoked <b>Edit|Format|Right Align</b>'));
}

sub justify {
    my $this = shift;
    $this->{infoLabel}->setText(QString('Invoked <b>Edit|Format|Justify</b>'));
}

sub center {
    my $this = shift;
    $this->{infoLabel}->setText(QString('Invoked <b>Edit|Format|Center</b>'));
}

sub setLineSpacing {
    my $this = shift;
    $this->{infoLabel}->setText(QString('Invoked <b>Edit|Format|Set Line Spacing</b>'));
}

sub setParagraphSpacing {
    my $this = shift;
    $this->{infoLabel}->setText(QString('Invoked <b>Edit|Format|Set Paragraph Spacing</b>'));
}

sub about {
    my $this = shift;
    $this->{infoLabel}->setText(QString('Invoked <b>Help|About</b>'));
    QMessageBox::about($this, QString("About Menu"),
            QString('The <b>Menu</b> example shows how to create menu-bar menus and context menus.'));
}

sub aboutQt {
    my $this = shift;
    $this->{infoLabel}->setText(QString('Invoked <b>Help|About Qt</b>'));
}

sub createActions {
    my $this = shift;

    $this->{newAct} = QAction(QString("&New"), $this);
    $this->{newAct}->setShortcut(QKeySequence(QString("Ctrl+N")));
    $this->{newAct}->setStatusTip(QString("Create a new file"));
    $this->connect($this->{newAct}, SIGNAL('triggered()'), $this, SLOT('newFile()'));

    $this->{openAct} = QAction(QString("&Open..."), $this);
    $this->{openAct}->setShortcut(QKeySequence(QString("Ctrl+O")));
    $this->{openAct}->setStatusTip(QString("Open an existing file"));
    $this->connect($this->{openAct}, SIGNAL('triggered()'), $this, SLOT('open_()'));

    $this->{saveAct} = QAction(QString("&Save"), $this);
    $this->{saveAct}->setShortcut(QKeySequence(QString("Ctrl+S")));
    $this->{saveAct}->setStatusTip(QString("Save the document to disk"));
    $this->connect($this->{saveAct}, SIGNAL('triggered()'), $this, SLOT('save()'));

    $this->{printAct} = QAction(QString("&Print..."), $this);
    $this->{printAct}->setShortcut(QKeySequence(QString("Ctrl+P")));
    $this->{printAct}->setStatusTip(QString("Print the document"));
    $this->connect($this->{printAct}, SIGNAL('triggered()'), $this, SLOT('print_()'));

    $this->{exitAct} = QAction(QString("E&xit"), $this);
    $this->{exitAct}->setShortcut(QKeySequence(QString("Ctrl+Q")));
    $this->{exitAct}->setStatusTip(QString("Exit the application"));
    $this->connect($this->{exitAct}, SIGNAL('triggered()'), $this, SLOT('close()'));

    $this->{undoAct} = QAction(QString("&Undo"), $this);
    $this->{undoAct}->setShortcut(QKeySequence(QString("Ctrl+Z")));
    $this->{undoAct}->setStatusTip(QString("Undo the last operation"));
    $this->connect($this->{undoAct}, SIGNAL('triggered()'), $this, SLOT('undo()'));

    $this->{redoAct} = QAction(QString("&Redo"), $this);
    $this->{redoAct}->setShortcut(QKeySequence(QString("Ctrl+Y")));
    $this->{redoAct}->setStatusTip(QString("Redo the last operation"));
    $this->connect($this->{redoAct}, SIGNAL('triggered()'), $this, SLOT('redo()'));

    $this->{cutAct} = QAction(QString("Cu&t"), $this);
    $this->{cutAct}->setShortcut(QKeySequence(QString("Ctrl+X")));
    $this->{cutAct}->setStatusTip(QString("Cut the current selection's contents to the clipboard"));
    $this->connect($this->{cutAct}, SIGNAL('triggered()'), $this, SLOT('cut()'));

    $this->{copyAct} = QAction(QString("&Copy"), $this);
    $this->{copyAct}->setShortcut(QKeySequence(QString("Ctrl+C")));
    $this->{copyAct}->setStatusTip(QString("Copy the current selection's contents to the clipboard"));
    $this->connect($this->{copyAct}, SIGNAL('triggered()'), $this, SLOT('copy()'));

    $this->{pasteAct} = QAction(QString("&Paste"), $this);
    $this->{pasteAct}->setShortcut(QKeySequence(QString("Ctrl+V")));
    $this->{pasteAct}->setStatusTip(QString("Paste the clipboard's contents into the current selection"));
    $this->connect($this->{pasteAct}, SIGNAL('triggered()'), $this, SLOT('paste()'));

    $this->{boldAct} = QAction(QString("&Bold"), $this);
    $this->{boldAct}->setCheckable(1); # 1 == true
    $this->{boldAct}->setShortcut(QKeySequence(QString("Ctrl+B")));
    $this->{boldAct}->setStatusTip(QString("Make the text bold"));
    $this->connect($this->{boldAct}, SIGNAL('triggered()'), $this, SLOT('bold()'));

    $this->{boldFont} = $this->{boldAct}->font();
    $this->{boldFont}->setBold(1); # 1 == true
    $this->{boldAct}->setFont($this->{boldFont});

    $this->{italicAct} = QAction(QString("&Italic"), $this);
    $this->{italicAct}->setCheckable(1); # true
    $this->{italicAct}->setShortcut(QKeySequence(QString("Ctrl+I")));
    $this->{italicAct}->setStatusTip(QString("Make the text italic"));
    $this->connect($this->{italicAct}, SIGNAL('triggered()'), $this, SLOT('italic()'));

    $this->{italicFont} = $this->{italicAct}->font();
    $this->{italicFont}->setItalic(1); # true
    $this->{italicAct}->setFont($this->{italicFont});

    $this->{setLineSpacingAct} = QAction(QString("Set &Line Spacing..."), $this);
    $this->{setLineSpacingAct}->setStatusTip(QString("Change the gap between the lines of a paragraph"));
    $this->connect($this->{setLineSpacingAct}, SIGNAL('triggered()'), $this, SLOT('setLineSpacing()'));

    $this->{setParagraphSpacingAct} = QAction(QString("Set &Paragraph Spacing..."), $this);
    $this->{setLineSpacingAct}->setStatusTip(QString("Change the gap between paragraphs"));
    $this->connect($this->{setParagraphSpacingAct}, SIGNAL('triggered()'), $this, SLOT('setParagraphSpacing()'));

    $this->{aboutAct} = QAction(QString("&About"), $this);
    $this->{aboutAct}->setStatusTip(QString("Show the application's About box"));
    $this->connect($this->{aboutAct}, SIGNAL('triggered()'), $this, SLOT('about()'));

    $this->{aboutQtAct} = QAction(QString("About &Qt"), $this);
    $this->{aboutQtAct}->setStatusTip(QString("Show the Qt library's About box"));
    $this->connect($this->{aboutQtAct}, SIGNAL('triggered()'), $qApp, SLOT('aboutQt()'));
    $this->connect($this->{aboutQtAct}, SIGNAL('triggered()'), $this, SLOT('aboutQt()'));

    $this->{leftAlignAct} = QAction(QString("&Left Align"), $this);
    $this->{leftAlignAct}->setCheckable(1); # true
    $this->{leftAlignAct}->setShortcut(QKeySequence(QString("Ctrl+L")));
    $this->{leftAlignAct}->setStatusTip(QString("Left align the selected text"));
    $this->connect($this->{leftAlignAct}, SIGNAL('triggered()'), $this, SLOT('leftAlign()'));

    $this->{rightAlignAct} = QAction(QString("&Right Align"), $this);
    $this->{rightAlignAct}->setCheckable(1); # true
    $this->{rightAlignAct}->setShortcut(QKeySequence(QString("Ctrl+R")));
    $this->{rightAlignAct}->setStatusTip(QString("Right align the selected text"));
    $this->connect($this->{rightAlignAct}, SIGNAL('triggered()'), $this, SLOT('rightAlign()'));

    $this->{justifyAct} = QAction(QString("&Justify"), $this);
    $this->{justifyAct}->setCheckable(1); # true
    $this->{justifyAct}->setShortcut(QKeySequence(QString("Ctrl+J")));
    $this->{justifyAct}->setStatusTip(QString("Justify the selected text"));
    $this->connect($this->{justifyAct}, SIGNAL('triggered()'), $this, SLOT('justify()'));

    $this->{centerAct} = QAction(QString("&Center"), $this);
    $this->{centerAct}->setCheckable(1); # true
    $this->{centerAct}->setShortcut(QKeySequence(QString("Ctrl+E")));
    $this->{centerAct}->setStatusTip(QString("Center the selected text"));
    $this->connect($this->{centerAct}, SIGNAL('triggered()'), $this, SLOT('center()'));
    
    $this->{alignmentGroup} = QActionGroup($this);
    $this->{alignmentGroup}->addAction($this->{leftAlignAct});
    $this->{alignmentGroup}->addAction($this->{rightAlignAct});
    $this->{alignmentGroup}->addAction($this->{justifyAct});
    $this->{alignmentGroup}->addAction($this->{centerAct});
    $this->{leftAlignAct}->setChecked(1); # true 
}

sub createMenus {
    my $this = shift;

    $this->{fileMenu} = $this->menuBar()->addMenu(QString("&File"));
    $this->{fileMenu}->Qt::QWidget::addAction($this->{newAct});
    $this->{fileMenu}->Qt::QWidget::addAction($this->{openAct});
    $this->{fileMenu}->Qt::QWidget::addAction($this->{saveAct});
    $this->{fileMenu}->Qt::QWidget::addAction($this->{printAct});
    $this->{fileMenu}->addSeparator();
    $this->{fileMenu}->Qt::QWidget::addAction($this->{exitAct});

    $this->{editMenu} = $this->menuBar()->addMenu(QString("&Edit"));
    $this->{editMenu}->Qt::QWidget::addAction($this->{undoAct});
    $this->{editMenu}->Qt::QWidget::addAction($this->{redoAct});
    $this->{editMenu}->addSeparator();
    $this->{editMenu}->Qt::QWidget::addAction($this->{cutAct});
    $this->{editMenu}->Qt::QWidget::addAction($this->{copyAct});
    $this->{editMenu}->Qt::QWidget::addAction($this->{pasteAct});
    $this->{editMenu}->addSeparator();

    $this->{helpMenu} = $this->menuBar()->addMenu(QString("&Help"));
    $this->{helpMenu}->Qt::QWidget::addAction($this->{aboutAct});
    $this->{helpMenu}->Qt::QWidget::addAction($this->{aboutQtAct});

    $this->{formatMenu} = $this->{editMenu}->addMenu(QString("&Format"));
    $this->{formatMenu}->Qt::QWidget::addAction($this->{boldAct});
    $this->{formatMenu}->Qt::QWidget::addAction($this->{italicAct});
    $this->{formatMenu}->addSeparator()->setText(QString("Alignment"));
    $this->{formatMenu}->Qt::QWidget::addAction($this->{leftAlignAct});
    $this->{formatMenu}->Qt::QWidget::addAction($this->{rightAlignAct});
    $this->{formatMenu}->Qt::QWidget::addAction($this->{justifyAct});
    $this->{formatMenu}->Qt::QWidget::addAction($this->{centerAct});
    $this->{formatMenu}->addSeparator();
    $this->{formatMenu}->Qt::QWidget::addAction($this->{setLineSpacingAct});
    $this->{formatMenu}->Qt::QWidget::addAction($this->{setParagraphSpacingAct});
}

1;
