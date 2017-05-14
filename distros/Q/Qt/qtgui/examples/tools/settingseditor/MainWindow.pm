package MainWindow;

use strict;
use warnings;
use QtCore4;
use QtGui4;
use QtCore4::isa qw( Qt::MainWindow );
use QtCore4::slots
    openSettings => [],
    openIniFile => [],
    openPropertyList => [],
    openRegistryPath => [],
    about => [];
use LocationDialog;
use SettingsTree;


sub settingsTree() {
    return this->{settingsTree};
}

sub locationDialog() {
    return this->{locationDialog};
}

sub fileMenu() {
    return this->{fileMenu};
}

sub optionsMenu() {
    return this->{optionsMenu};
}

sub helpMenu() {
    return this->{helpMenu};
}

sub openSettingsAct() {
    return this->{openSettingsAct};
}

sub openIniFileAct() {
    return this->{openIniFileAct};
}

sub openPropertyListAct() {
    return this->{openPropertyListAct};
}

sub openRegistryPathAct() {
    return this->{openRegistryPathAct};
}

sub refreshAct() {
    return this->{refreshAct};
}

sub exitAct() {
    return this->{exitAct};
}

sub autoRefreshAct() {
    return this->{autoRefreshAct};
}

sub fallbacksAct() {
    return this->{fallbacksAct};
}

sub aboutAct() {
    return this->{aboutAct};
}

sub aboutQtAct() {
    return this->{aboutQtAct};
}

sub NEW
{
    my ($class) = @_;
    $class->SUPER::NEW();
    this->{settingsTree} = SettingsTree();
    setCentralWidget(settingsTree);

    this->{locationDialog} = undef;

    createActions();
    createMenus();

    autoRefreshAct->setChecked(1);
    fallbacksAct->setChecked(1);

    setWindowTitle(this->tr('Settings Editor'));
    resize(500, 600);
}

sub openSettings
{
    if (!locationDialog()) {
        this->{locationDialog} = LocationDialog(this);
    }

    if (locationDialog->exec()) {
        my $settings = Qt::Settings(locationDialog->format(),
                                            locationDialog->scope(),
                                            locationDialog->organization(),
                                            locationDialog->application());
        setSettingsObject($settings);
        fallbacksAct->setEnabled(1);
    }
}

sub openIniFile
{
    my $fileName = Qt::FileDialog::getOpenFileName(this, this->tr('Open INI File'),
                               '', this->tr('INI Files (*.ini *.conf)'));
    if ($fileName) {
        my $settings = Qt::Settings($fileName, Qt::Settings::IniFormat());
        setSettingsObject($settings);
        fallbacksAct->setEnabled(0);
    }
}

sub openPropertyList
{
    my $fileName = Qt::FileDialog::getOpenFileName(this,
                               this->tr('Open Property List'),
                               '', this->tr('Property List Files (*.plist)'));
    if ($fileName) {
        my $settings = Qt::Settings($fileName, Qt::Settings::NativeFormat());
        setSettingsObject($settings);
        fallbacksAct->setEnabled(0);
    }
}

sub openRegistryPath
{
    my $path = Qt::InputDialog::getText(this, this->tr('Open Registry Path'),
                           this->tr('Enter the path in the Windows registry:'),
                           Qt::LineEdit::Normal(), 'HKEY_CURRENT_USER\\');
    if ($path) {
        my $settings = Qt::Settings($path, Qt::Settings::NativeFormat());
        setSettingsObject($settings);
        fallbacksAct->setEnabled(0);
    }
}

sub about
{
    Qt::MessageBox::about(this, this->tr('About Settings Editor'),
            this->tr('The <b>Settings Editor</b> example shows how to access ' .
               'application settings using Qt.'));
}

sub createActions
{
    this->{openSettingsAct} = Qt::Action(this->tr('&Open Application Settings...'), this);
    openSettingsAct->setShortcut(Qt::KeySequence((Qt::KeySequence::Open())));
    this->connect(openSettingsAct, SIGNAL 'triggered()', this, SLOT 'openSettings()');

    this->{openIniFileAct} = Qt::Action(this->tr('Open I&NI File...'), this);
    openIniFileAct->setShortcut(Qt::KeySequence(this->tr('Ctrl+N')));
    this->connect(openIniFileAct, SIGNAL 'triggered()', this, SLOT 'openIniFile()');

    this->{openPropertyListAct} = Qt::Action(this->tr('Open Mac &Property List...'), this);
    openPropertyListAct->setShortcut(Qt::KeySequence(this->tr('Ctrl+P')));
    this->connect(openPropertyListAct, SIGNAL 'triggered()',
            this, SLOT 'openPropertyList()');

    this->{openRegistryPathAct} = Qt::Action(this->tr('Open Windows &Registry Path...'),
                                      this);
    openRegistryPathAct->setShortcut(Qt::KeySequence(this->tr('Ctrl+G')));
    this->connect(openRegistryPathAct, SIGNAL 'triggered()',
            this, SLOT 'openRegistryPath()');

    this->{refreshAct} = Qt::Action(this->tr('&Refresh'), this);
    refreshAct->setShortcut(Qt::KeySequence(this->tr('Ctrl+R')));
    refreshAct->setEnabled(0);
    this->connect(refreshAct, SIGNAL 'triggered()', settingsTree, SLOT 'refresh()');

    this->{exitAct} = Qt::Action(this->tr('E&xit'), this);
    exitAct->setShortcut(Qt::KeySequence((Qt::KeySequence::Quit())));
    this->connect(exitAct, SIGNAL 'triggered()', this, SLOT 'close()');

    this->{autoRefreshAct} = Qt::Action(this->tr('&Auto-Refresh'), this);
    autoRefreshAct->setShortcut(Qt::KeySequence(this->tr('Ctrl+A')));
    autoRefreshAct->setCheckable(1);
    autoRefreshAct->setEnabled(0);
    this->connect(autoRefreshAct, SIGNAL 'triggered(bool)',
            settingsTree, SLOT 'setAutoRefresh(bool)');
    this->connect(autoRefreshAct, SIGNAL 'triggered(bool)',
            refreshAct, SLOT 'setDisabled(bool)');

    this->{fallbacksAct} = Qt::Action(this->tr('&Fallbacks'), this);
    fallbacksAct->setShortcut(Qt::KeySequence(this->tr('Ctrl+F')));
    fallbacksAct->setCheckable(1);
    fallbacksAct->setEnabled(0);
    this->connect(fallbacksAct, SIGNAL 'triggered(bool)',
            settingsTree, SLOT 'setFallbacksEnabled(bool)');

    this->{aboutAct} = Qt::Action(this->tr('&About'), this);
    this->connect(aboutAct, SIGNAL 'triggered()', this, SLOT 'about()');

    this->{aboutQtAct} = Qt::Action(this->tr('About &Qt'), this);
    this->connect(aboutQtAct, SIGNAL 'triggered()', qApp, SLOT 'aboutQt()');

#ifndef Q_WS_MAC
    openPropertyListAct->setEnabled(0);
#endif
#ifndef Q_WS_WIN
    openRegistryPathAct->setEnabled(0);
#endif
}

sub createMenus
{
    this->{fileMenu} = menuBar()->addMenu(this->tr('&File'));
    fileMenu->addAction(openSettingsAct);
    fileMenu->addAction(openIniFileAct);
    fileMenu->addAction(openPropertyListAct);
    fileMenu->addAction(openRegistryPathAct);
    fileMenu->addSeparator();
    fileMenu->addAction(refreshAct);
    fileMenu->addSeparator();
    fileMenu->addAction(exitAct);

    this->{optionsMenu} = menuBar()->addMenu(this->tr('&Options'));
    optionsMenu->addAction(autoRefreshAct);
    optionsMenu->addAction(fallbacksAct);

    menuBar()->addSeparator();

    this->{helpMenu} = menuBar()->addMenu(this->tr('&Help'));
    helpMenu->addAction(aboutAct);
    helpMenu->addAction(aboutQtAct);
}

sub setSettingsObject
{
    my ($settings) = @_;
    $settings->setFallbacksEnabled(fallbacksAct->isChecked());
    settingsTree->setSettingsObject($settings);

    refreshAct->setEnabled(1);
    autoRefreshAct->setEnabled(1);

    my $niceName = $settings->fileName();
    $niceName =~ s/\\/\//g;

    $niceName =~ s/.*\///g;

    if (!$settings->isWritable()) {
        $niceName = Qt::String(this->tr('%1 (read only)'))->arg($niceName);
    }

    setWindowTitle(Qt::String(this->tr('%1 - %2'))->arg($niceName)->arg(this->tr('Settings Editor')));
}

1;
