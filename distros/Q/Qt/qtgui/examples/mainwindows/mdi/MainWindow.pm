package MainWindow;

use strict;
use warnings;

use QtCore4;
use QtGui4;
use QtCore4::isa qw( Qt::MainWindow );
use QtCore4::slots
    newFile => [''],
    openSlot => [''],
    save => [''],
    saveAs => [''],
    cut => [''],
    copy => [''],
    paste => [''],
    about => [''],
    updateMenus => [''],
    updateWindowMenu => [''],
    createMdiChild => [''],
    switchLayoutDirection => [''],
    setActiveSubWindow => ['QWidget*'];

use MdiChild;

sub NEW {
    shift->SUPER::NEW(@_);
    my $mdiArea = Qt::MdiArea();
    this->{mdiArea} = $mdiArea;
    this->setCentralWidget($mdiArea);
    this->connect($mdiArea, SIGNAL 'subWindowActivated(QMdiSubWindow *)',
                  this, SLOT 'updateMenus()');
    my $windowMapper = Qt::SignalMapper(this);
    this->{windowMapper} = $windowMapper;
    this->connect($windowMapper, SIGNAL 'mapped(QWidget*)',
                  this, SLOT 'setActiveSubWindow(QWidget*)');

    createActions();
    createMenus();
    createToolBars();
    createStatusBar();
    updateMenus();

    readSettings();

    this->setWindowTitle("MDI");
}

sub closeEvent {
    my ( $event ) = @_;

    this->{mdiArea}->closeAllSubWindows();
    if (activeMdiChild()) {
        $event->ignore();
    } else {
        writeSettings();
        $event->accept();
    }
}

sub newFile {
    my $child = createMdiChild();
    $child->newFile();
    $child->show();
}

sub openSlot {
    my $fileName = Qt::FileDialog::getOpenFileName(this);
    if ($fileName) {
        my $existing = findMdiChild($fileName);
        if ($existing) {
            this->{mdiArea}->setActiveSubWindow($existing);
            return;
        }

        my $child = createMdiChild();
        if ($child->loadFile($fileName)) {
            this->statusBar()->showMessage("File loaded", 2000);
            $child->show();
        } else {
            $child->close();
        }
        push @{this->{children}}, $child;
    }
}

sub save {
    if (activeMdiChild() && activeMdiChild()->save()) {
        this->statusBar()->showMessage("File saved", 2000);
    }
}

sub saveAs {
    if (activeMdiChild() && activeMdiChild()->saveAs()) {
        this->statusBar()->showMessage("File saved", 2000);
    }
}

sub cut {
    if (activeMdiChild()) {
        activeMdiChild()->cut();
    }
}

sub copy {
    if (activeMdiChild()) {
        activeMdiChild()->copy();
    }
}

sub paste {
    if (activeMdiChild()) {
        activeMdiChild()->paste();
    }
}

sub about {
   Qt::MessageBox::about(this, "About MDI",
            "The <b>MDI</b> example demonstrates how to write multiple " .
            "document interface applications using Qt.");
}

sub updateMenus {
    my $hasMdiChild = (activeMdiChild() != 0);
    this->{saveAct}->setEnabled($hasMdiChild);
    this->{saveAsAct}->setEnabled($hasMdiChild);
    this->{pasteAct}->setEnabled($hasMdiChild);
    this->{closeAct}->setEnabled($hasMdiChild);
    this->{closeAllAct}->setEnabled($hasMdiChild);
    this->{tileAct}->setEnabled($hasMdiChild);
    this->{cascadeAct}->setEnabled($hasMdiChild);
    this->{nextAct}->setEnabled($hasMdiChild);
    this->{previousAct}->setEnabled($hasMdiChild);
    this->{separatorAct}->setVisible($hasMdiChild);

    my $hasSelection = (this->activeMdiChild() &&
                        this->activeMdiChild()->textCursor()->hasSelection());
    this->{cutAct}->setEnabled($hasSelection);
    this->{copyAct}->setEnabled($hasSelection);
}

sub updateWindowMenu {
    this->{windowMenu}->clear();
    this->{windowMenu}->addAction(this->{closeAct});
    this->{windowMenu}->addAction(this->{closeAllAct});
    this->{windowMenu}->addSeparator();
    this->{windowMenu}->addAction(this->{tileAct});
    this->{windowMenu}->addAction(this->{cascadeAct});
    this->{windowMenu}->addSeparator();
    this->{windowMenu}->addAction(this->{nextAct});
    this->{windowMenu}->addAction(this->{previousAct});
    this->{windowMenu}->addAction(this->{separatorAct});

    my @windows = @{this->{mdiArea}->subWindowList()};
    this->{separatorAct}->setVisible(scalar @windows);

    foreach my $i ( 0..$#windows ) {
        my $child = $windows[$i]->widget();

        my $text;
        if ($i < 9) {
            $text = sprintf "&%d %s", $i + 1,
                               $child->userFriendlyCurrentFile();
        } else {
            $text = sprintf "%s %s", $i + 1,
                              $child->userFriendlyCurrentFile();
        }
        my $action  = this->{windowMenu}->addAction($text);
        $action->setCheckable(1);
        $action->setChecked($child == activeMdiChild());
        this->connect($action, SIGNAL 'triggered()', this->{windowMapper}, SLOT 'map()');
        this->{windowMapper}->setMapping($action, $windows[$i]);
    }
}

sub createMdiChild {
    my $child = MdiChild();
    this->{mdiArea}->addSubWindow($child);

    this->connect($child, SIGNAL 'copyAvailable(bool)',
                  this->{cutAct}, SLOT 'setEnabled(bool)');
    this->connect($child, SIGNAL 'copyAvailable(bool)',
                  this->{copyAct}, SLOT 'setEnabled(bool)');

    return $child;
}

sub createActions {
    my $newAct = Qt::Action(Qt::Icon("images/new.png"), "&New", this);
    this->{newAct} = $newAct;
    $newAct->setShortcut(Qt::KeySequence("Ctrl+N"));
    $newAct->setStatusTip("Create a new file");
    this->connect($newAct, SIGNAL 'triggered()', this, SLOT 'newFile()');

    my $openAct = Qt::Action(Qt::Icon("images/open.png"), "&Open...", this);
    this->{openAct} = $openAct;
    $openAct->setShortcut(Qt::KeySequence("Ctrl+O"));
    $openAct->setStatusTip("Open an existing file");
    this->connect($openAct, SIGNAL 'triggered()', this, SLOT 'openSlot()');

    my $saveAct = Qt::Action(Qt::Icon("images/save.png"), "&Save", this);
    this->{saveAct} = $saveAct;
    $saveAct->setShortcut(Qt::KeySequence("Ctrl+S"));
    $saveAct->setStatusTip("Save the document to disk");
    this->connect($saveAct, SIGNAL 'triggered()', this, SLOT 'save()');

    my $saveAsAct = Qt::Action("Save &As...", this);
    this->{saveAsAct} = $saveAsAct;
    $saveAsAct->setStatusTip("Save the document under a new name");
    this->connect($saveAsAct, SIGNAL 'triggered()', this, SLOT 'saveAs()');

    my $exitAct = Qt::Action("E&xit", this);
    this->{exitAct} = $exitAct;
    $exitAct->setShortcut(Qt::KeySequence("Ctrl+Q"));
    $exitAct->setStatusTip("Exit the application");
    this->connect($exitAct, SIGNAL 'triggered()', Qt::qApp(), SLOT 'closeAllWindows()');

    my $cutAct = Qt::Action(Qt::Icon("images/cut.png"), "Cu&t", this);
    this->{cutAct} = $cutAct;
    $cutAct->setShortcut(Qt::KeySequence("Ctrl+X"));
    $cutAct->setStatusTip("Cut the current selection's contents to the " .
                            "clipboard");
    this->connect($cutAct, SIGNAL 'triggered()', this, SLOT 'cut()');

    my $copyAct = Qt::Action(Qt::Icon("images/copy.png"), "&Copy", this);
    this->{copyAct} = $copyAct;
    $copyAct->setShortcut(Qt::KeySequence("Ctrl+C"));
    $copyAct->setStatusTip("Copy the current selection's contents to the " .
                             "clipboard");
    this->connect($copyAct, SIGNAL 'triggered()', this, SLOT 'copy()');

    my $pasteAct = Qt::Action(Qt::Icon("images/paste.png"), "&Paste", this);
    this->{pasteAct} = $pasteAct;
    $pasteAct->setShortcut(Qt::KeySequence("Ctrl+V"));
    $pasteAct->setStatusTip("Paste the clipboard's contents into the current " .
                              "selection");
    this->connect($pasteAct, SIGNAL 'triggered()', this, SLOT 'paste()');

    my $closeAct = Qt::Action("Cl&ose", this);
    this->{closeAct} = $closeAct;
    $closeAct->setShortcut(Qt::KeySequence("Ctrl+F4"));
    $closeAct->setStatusTip("Close the active window");
    this->connect($closeAct, SIGNAL 'triggered()',
            this->{mdiArea}, SLOT 'closeActiveSubWindow()');

    my $closeAllAct = Qt::Action("Close &All", this);
    this->{closeAllAct} = $closeAllAct;
    $closeAllAct->setStatusTip("Close all the windows");
    this->connect($closeAllAct, SIGNAL 'triggered()',
            this->{mdiArea}, SLOT 'closeAllSubWindows()');

    my $tileAct = Qt::Action("&Tile", this);
    this->{tileAct} = $tileAct;
    $tileAct->setStatusTip("Tile the windows");
    this->connect($tileAct, SIGNAL 'triggered()', this->{mdiArea}, SLOT 'tileSubWindows()');

    my $cascadeAct = Qt::Action("&Cascade", this);
    this->{cascadeAct} = $cascadeAct;
    $cascadeAct->setStatusTip("Cascade the windows");
    this->connect($cascadeAct, SIGNAL 'triggered()', this->{mdiArea}, SLOT 'cascadeSubWindows()');

    my $nextAct = Qt::Action("Ne&xt", this);
    this->{nextAct} = $nextAct;
    $nextAct->setStatusTip("Move the focus to the next window");
    this->connect($nextAct, SIGNAL 'triggered()',
            this->{mdiArea}, SLOT 'activateNextSubWindow()');

    my $previousAct = Qt::Action("Pre&vious", this);
    this->{previousAct} = $previousAct;
    $previousAct->setStatusTip("Move the focus to the previous " .
                                 "window");
    this->connect($previousAct, SIGNAL 'triggered()',
            this->{mdiArea}, SLOT 'activatePreviousSubWindow()');

    my $separatorAct = Qt::Action(this);
    this->{separatorAct} = $separatorAct;
    $separatorAct->setSeparator(1);

    my $aboutAct = Qt::Action("&About", this);
    this->{aboutAct} = $aboutAct;
    $aboutAct->setStatusTip("Show the application's About box");
    this->connect($aboutAct, SIGNAL 'triggered()', this, SLOT 'about()');

    my $aboutQtAct = Qt::Action("About &Qt", this);
    this->{aboutQtAct} = $aboutQtAct;
    $aboutQtAct->setStatusTip("Show the Qt4 library's About box");
    this->connect($aboutQtAct, SIGNAL 'triggered()', Qt::qApp(), SLOT 'aboutQt()');
}

sub createMenus {
    my $fileMenu = this->menuBar()->addMenu("&File");
    $fileMenu->addAction(this->{newAct});
    $fileMenu->addAction(this->{openAct});
    $fileMenu->addAction(this->{saveAct});
    $fileMenu->addAction(this->{saveAsAct});
    $fileMenu->addSeparator();
    my $action = $fileMenu->addAction("Switch layout direction");
    this->connect($action, SIGNAL 'triggered()', this, SLOT 'switchLayoutDirection()');
    $fileMenu->addAction(this->{exitAct});

    my $editMenu = this->menuBar()->addMenu("&Edit");
    $editMenu->addAction(this->{cutAct});
    $editMenu->addAction(this->{copyAct});
    $editMenu->addAction(this->{pasteAct});

    my $windowMenu = this->menuBar()->addMenu("&Window");
    this->{windowMenu} = $windowMenu;
    this->updateWindowMenu();
    this->connect($windowMenu, SIGNAL 'aboutToShow()', this, SLOT 'updateWindowMenu()');

    this->menuBar()->addSeparator();

    my $helpMenu = this->menuBar()->addMenu("&Help");
    $helpMenu->addAction(this->{aboutAct});
    $helpMenu->addAction(this->{aboutQtAct});

}

sub createToolBars {
    my $fileToolBar = this->addToolBar("File");
    $fileToolBar->addAction(this->{newAct});
    $fileToolBar->addAction(this->{openAct});
    $fileToolBar->addAction(this->{saveAct});

    my $editToolBar = this->addToolBar("Edit");
    $editToolBar->addAction(this->{cutAct});
    $editToolBar->addAction(this->{copyAct});
    $editToolBar->addAction(this->{pasteAct});
}

sub createStatusBar {
    this->statusBar()->showMessage("Ready");
}

sub readSettings {
    my $settings = Qt::Settings("Trolltech", "MDI Example");
    my $pos = $settings->value("pos", Qt::Variant(Qt::Point(200, 200)))->toPoint();
    my $size = $settings->value("size", Qt::Variant(Qt::Size(400, 400)))->toSize();
    this->resize($size);
    this->move($pos);
}

sub writeSettings {
    my $settings = Qt::Settings("Trolltech", "MDI Example");
    $settings->setValue("pos", Qt::Variant(this->pos()));
    $settings->setValue("size", Qt::Variant(this->size()));
}

sub activeMdiChild {
    if (my $activeSubWindow = this->{mdiArea}->activeSubWindow()) {
        return CAST $activeSubWindow->widget(), 'MdiChild';
    }
    return 0;
}

sub findMdiChild {
    my( $fileName ) = @_;
    my $canonicalFilePath = Qt::FileInfo($fileName)->canonicalFilePath();

    foreach my $window ( @{this->{mdiArea}->subWindowList()} ) {
        my $mdiChild = CAST $window->widget(), 'MdiChild';
        if ($mdiChild->currentFile() eq $canonicalFilePath) {
            return $window;
        }
    }
    return 0;
}

sub switchLayoutDirection {
    if (this->layoutDirection() == Qt::LeftToRight()) {
        Qt::qApp()->setLayoutDirection(Qt::RightToLeft());
    }
    else {
        Qt::qApp()->setLayoutDirection(Qt::LeftToRight());
    }
}

sub setActiveSubWindow {
    my ( $window ) = @_;
    if (!$window){
        return;
    }
    this->{mdiArea}->setActiveSubWindow($window);
}

1;
