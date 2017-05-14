package MainWindow;

use strict;
use warnings;
use QtCore4;
use QtGui4;
use QtCore4::isa qw( Qt::MainWindow );
use QtCore4::slots
    openFile => ['const QString &'],
    openFileNoArg => [''],
    setRenderer => ['QAction *'];
use SvgView;

sub m_nativeAction() {
    return this->{m_nativeAction};
}

sub m_glAction() {
    return this->{m_glAction};
}

sub m_imageAction() {
    return this->{m_imageAction};
}

sub m_highQualityAntialiasingAction() {
    return this->{m_highQualityAntialiasingAction};
}

sub m_backgroundAction() {
    return this->{m_backgroundAction};
}

sub m_outlineAction() {
    return this->{m_outlineAction};
}

sub m_view() {
    return this->{m_view};
}

sub m_currentPath() {
    return this->{m_currentPath};
}

sub NEW
{
    my ($class) = @_;
    $class->SUPER::NEW();
    my $m_view = this->{m_view} = SvgView();

    my $fileMenu = Qt::Menu(this->tr('&File'), this);
    my $openAction = $fileMenu->addAction(this->tr('&Open...'));
    $openAction->setShortcut(Qt::KeySequence(this->tr('Ctrl+O')));
    my $quitAction = $fileMenu->addAction(this->tr('E&xit'));
    $quitAction->setShortcut(Qt::KeySequence(this->tr('Ctrl+Q')));

    this->menuBar()->addMenu($fileMenu);

    my $viewMenu = Qt::Menu(this->tr('&View'), this);
    my $m_backgroundAction = this->{m_backgroundAction} = $viewMenu->addAction(this->tr('&Background'));
    $m_backgroundAction->setEnabled(0);
    $m_backgroundAction->setCheckable(1);
    $m_backgroundAction->setChecked(0);
    this->connect($m_backgroundAction, SIGNAL 'toggled(bool)', $m_view, SLOT 'setViewBackground(bool)');

    my $m_outlineAction = this->{m_outlineAction} = $viewMenu->addAction(this->tr('&Outline'));
    $m_outlineAction->setEnabled(0);
    $m_outlineAction->setCheckable(1);
    $m_outlineAction->setChecked(1);
    this->connect($m_outlineAction, SIGNAL 'toggled(bool)', $m_view, SLOT 'setViewOutline(bool)');

    this->menuBar()->addMenu($viewMenu);

    my $rendererMenu = Qt::Menu(this->tr('&Renderer'), this);
    my $m_nativeAction = this->{m_nativeAction} = $rendererMenu->addAction(this->tr('&Native'));
    $m_nativeAction->setCheckable(1);
    $m_nativeAction->setChecked(1);
#ifndef QT_NO_OPENGL
    my $m_glAction = this->{m_glAction} = $rendererMenu->addAction(this->tr('&OpenGL'));
    $m_glAction->setCheckable(1);
#endif
    my $m_imageAction = this->{m_imageAction} = $rendererMenu->addAction(this->tr('&Image'));
    $m_imageAction->setCheckable(1);

#ifndef QT_NO_OPENGL
    $rendererMenu->addSeparator();
    my $m_highQualityAntialiasingAction = this->{m_highQualityAntialiasingAction} =
        $rendererMenu->addAction(this->tr('&High Quality Antialiasing'));
    $m_highQualityAntialiasingAction->setEnabled(0);
    $m_highQualityAntialiasingAction->setCheckable(1);
    $m_highQualityAntialiasingAction->setChecked(0);
    this->connect($m_highQualityAntialiasingAction, SIGNAL 'toggled(bool)', $m_view, SLOT 'setHighQualityAntialiasing(bool)');
#endif

    my $rendererGroup = Qt::ActionGroup(this);
    $rendererGroup->addAction($m_nativeAction);
#ifndef QT_NO_OPENGL
    $rendererGroup->addAction($m_glAction);
#endif
    $rendererGroup->addAction($m_imageAction);

    this->menuBar()->addMenu($rendererMenu);

    this->connect($openAction, SIGNAL 'triggered()', this, SLOT 'openFileNoArg()');
    this->connect($quitAction, SIGNAL 'triggered()', qApp, SLOT 'quit()');
    this->connect($rendererGroup, SIGNAL 'triggered(QAction *)',
            this, SLOT 'setRenderer(QAction *)');

    this->setCentralWidget($m_view);
    this->setWindowTitle(this->tr('SVG Viewer'));
}

sub openFileNoArg {
    this->openFile();
}

sub openFile
{
    my ($path) = @_;
    my $fileName;
    if (!$path) {
        $fileName = Qt::FileDialog::getOpenFileName(this, this->tr('Open SVG File'),
                this->m_currentPath, 'SVG files (*.svg *.svgz *.svg.gz)');
    }
    else {
        $fileName = $path;
    }

    if ($fileName) {
        my $file = Qt::File($fileName);
        if (!$file->exists()) {
            Qt::MessageBox::critical(this, this->tr('Open SVG File'),
                           "Could not open file '$fileName'.");

            this->m_outlineAction->setEnabled(0);
            this->m_backgroundAction->setEnabled(0);
            return;
        }

        this->m_view->openFile($file);

        #if (!fileName.startsWith(':/')) {
            this->{m_currentPath} = $fileName;
            this->setWindowTitle(sprintf this->tr('%s - SVGViewer'), this->m_currentPath);
        #}

        this->m_outlineAction->setEnabled(1);
        this->m_backgroundAction->setEnabled(1);

        this->resize(this->m_view->sizeHint() + Qt::Size(80, 80 + this->menuBar()->height()));
    }
}

sub setRenderer
{
    my ($action) = @_;
#ifndef QT_NO_OPENGL
    this->m_highQualityAntialiasingAction->setEnabled(0);
#endif

    # FIXME Why doesn't adding an operator overload to call op_ref_equal work?
    if ($action->op_ref_equal( this->m_nativeAction ) ) {
        this->m_view->setRenderer(SvgView::Native);
    }
#ifndef QT_NO_OPENGL
    elsif ($action->op_ref_equal( this->m_glAction ) ) {
        this->m_highQualityAntialiasingAction->setEnabled(1);
        this->m_view->setRenderer(SvgView::OpenGL);
    }
#endif
    elsif ($action->op_ref_equal( this->m_imageAction ) ) {
        this->m_view->setRenderer(SvgView::Image);
    }
}

1;
