# Form implementation generated from reading ui file 'richedit.ui'
#
# Created: jeu jun 13 20:02:56 2002
#      by: The PerlQt User Interface Compiler (puic)
#


use strict;

# the below is a manual addition... 
# maybe puic should do that.
# Allows to run a modular application from anywhere
use FindBin;
use lib "$FindBin::Bin";                                 

package EditorForm;
use Qt;
use Qt::isa qw(Qt::MainWindow);
use Qt::slots
    init => [],
    fileExit => [],
    fileNew => [],
    fileOpen => [],
    fileSave => [],
    fileSaveAs => [],
    helpAbout => [],
    helpContents => [],
    helpIndex => [],
    changeAlignment => ['QAction*'],
    saveAndContinue => ['const QString&'];
use Qt::attributes qw(
    textEdit
    fontComboBox
    SpinBox2
    menubar
    fileMenu
    editMenu
    PopupMenu_2
    helpMenu
    toolBar
    Toolbar
    fileNewAction
    fileOpenAction
    fileSaveAction
    fileSaveAsAction
    fileExitAction
    editUndoAction
    editRedoAction
    editCutAction
    editCopyAction
    editPasteAction
    helpContentsAction
    helpIndexAction
    helpAboutAction
    boldAction
    italicAction
    underlineAction
    alignActionGroup
    leftAlignAction
    rightAlignAction
    centerAlignAction
);


sub uic_load_pixmap_EditorForm
{
    my $pix = Qt::Pixmap();
    my $m = Qt::MimeSourceFactory::defaultFactory()->data(shift);

    if($m)
    {
        Qt::ImageDrag::decode($m, $pix);
    }

    return $pix;
}


sub NEW
{
    shift->SUPER::NEW(@_[0..2]);
    this->statusBar();

    if( this->name() eq "unnamed" )
    {
        this->setName("EditorForm");
    }
    this->resize(646,436);
    this->setCaption(this->trUtf8("Rich Edit"));

    this->setCentralWidget(Qt::Widget(this, "qt_central_widget"));
    my $EditorFormLayout = Qt::HBoxLayout(this->centralWidget(), 11, 6, '$EditorFormLayout');

    textEdit = Qt::TextEdit(this->centralWidget(), "textEdit");
    textEdit->setSizePolicy(Qt::SizePolicy(7, 7, 0, 0, textEdit->sizePolicy()->hasHeightForWidth()));
    textEdit->setTextFormat(&Qt::TextEdit::RichText);
    $EditorFormLayout->addWidget(textEdit);

    fileNewAction= Qt::Action(this,"fileNewAction");
    fileNewAction->setIconSet(Qt::IconSet(uic_load_pixmap_EditorForm("filenew")));
    fileNewAction->setText(this->trUtf8("New"));
    fileNewAction->setMenuText(this->trUtf8("&New"));
    fileNewAction->setAccel(Qt::KeySequence(int(4194382)));
    fileOpenAction= Qt::Action(this,"fileOpenAction");
    fileOpenAction->setIconSet(Qt::IconSet(uic_load_pixmap_EditorForm("fileopen")));
    fileOpenAction->setText(this->trUtf8("Open"));
    fileOpenAction->setMenuText(this->trUtf8("&Open..."));
    fileOpenAction->setAccel(Qt::KeySequence(int(4194383)));
    fileSaveAction= Qt::Action(this,"fileSaveAction");
    fileSaveAction->setIconSet(Qt::IconSet(uic_load_pixmap_EditorForm("filesave")));
    fileSaveAction->setText(this->trUtf8("Save"));
    fileSaveAction->setMenuText(this->trUtf8("&Save"));
    fileSaveAction->setAccel(Qt::KeySequence(int(4194387)));
    fileSaveAsAction= Qt::Action(this,"fileSaveAsAction");
    fileSaveAsAction->setText(this->trUtf8("Save As"));
    fileSaveAsAction->setMenuText(this->trUtf8("Save &As..."));
    fileSaveAsAction->setAccel(Qt::KeySequence(int(0)));
    fileExitAction= Qt::Action(this,"fileExitAction");
    fileExitAction->setText(this->trUtf8("Exit"));
    fileExitAction->setMenuText(this->trUtf8("E&xit"));
    fileExitAction->setAccel(Qt::KeySequence(int(0)));
    editUndoAction= Qt::Action(this,"editUndoAction");
    editUndoAction->setIconSet(Qt::IconSet(uic_load_pixmap_EditorForm("undo")));
    editUndoAction->setText(this->trUtf8("Undo"));
    editUndoAction->setMenuText(this->trUtf8("&Undo"));
    editUndoAction->setAccel(Qt::KeySequence(int(4194394)));
    editRedoAction= Qt::Action(this,"editRedoAction");
    editRedoAction->setIconSet(Qt::IconSet(uic_load_pixmap_EditorForm("redo")));
    editRedoAction->setText(this->trUtf8("Redo"));
    editRedoAction->setMenuText(this->trUtf8("&Redo"));
    editRedoAction->setAccel(Qt::KeySequence(int(4194393)));
    editCutAction= Qt::Action(this,"editCutAction");
    editCutAction->setIconSet(Qt::IconSet(uic_load_pixmap_EditorForm("editcut")));
    editCutAction->setText(this->trUtf8("Cut"));
    editCutAction->setMenuText(this->trUtf8("&Cut"));
    editCutAction->setAccel(Qt::KeySequence(int(4194392)));
    editCopyAction= Qt::Action(this,"editCopyAction");
    editCopyAction->setIconSet(Qt::IconSet(uic_load_pixmap_EditorForm("editcopy")));
    editCopyAction->setText(this->trUtf8("Copy"));
    editCopyAction->setMenuText(this->trUtf8("C&opy"));
    editCopyAction->setAccel(Qt::KeySequence(int(4194371)));
    editPasteAction= Qt::Action(this,"editPasteAction");
    editPasteAction->setIconSet(Qt::IconSet(uic_load_pixmap_EditorForm("editpaste")));
    editPasteAction->setText(this->trUtf8("Paste"));
    editPasteAction->setMenuText(this->trUtf8("&Paste"));
    editPasteAction->setAccel(Qt::KeySequence(int(4194390)));
    helpContentsAction= Qt::Action(this,"helpContentsAction");
    helpContentsAction->setText(this->trUtf8("Contents"));
    helpContentsAction->setMenuText(this->trUtf8("&Contents..."));
    helpContentsAction->setAccel(Qt::KeySequence(int(0)));
    helpIndexAction= Qt::Action(this,"helpIndexAction");
    helpIndexAction->setText(this->trUtf8("Index"));
    helpIndexAction->setMenuText(this->trUtf8("&Index..."));
    helpIndexAction->setAccel(Qt::KeySequence(int(0)));
    helpAboutAction= Qt::Action(this,"helpAboutAction");
    helpAboutAction->setText(this->trUtf8("About"));
    helpAboutAction->setMenuText(this->trUtf8("&About..."));
    helpAboutAction->setAccel(Qt::KeySequence(int(0)));
    boldAction= Qt::Action(this,"boldAction");
    boldAction->setToggleAction(1);
    boldAction->setIconSet(Qt::IconSet(uic_load_pixmap_EditorForm("textbold")));
    boldAction->setText(this->trUtf8("bold"));
    boldAction->setMenuText(this->trUtf8("&Bold"));
    boldAction->setAccel(Qt::KeySequence(int(272629826)));
    italicAction= Qt::Action(this,"italicAction");
    italicAction->setToggleAction(1);
    italicAction->setIconSet(Qt::IconSet(uic_load_pixmap_EditorForm("textitalic")));
    italicAction->setText(this->trUtf8("italic"));
    italicAction->setMenuText(this->trUtf8("&Italic"));
    italicAction->setAccel(Qt::KeySequence(int(272629833)));
    underlineAction= Qt::Action(this,"underlineAction");
    underlineAction->setToggleAction(1);
    underlineAction->setIconSet(Qt::IconSet(uic_load_pixmap_EditorForm("textunder")));
    underlineAction->setText(this->trUtf8("underline"));
    underlineAction->setMenuText(this->trUtf8("&Underline"));
    underlineAction->setAccel(Qt::KeySequence(int(272629845)));
    alignActionGroup= Qt::ActionGroup(this,"alignActionGroup");
    alignActionGroup->setText(this->trUtf8("align"));
    alignActionGroup->setUsesDropDown(0);
    leftAlignAction= Qt::Action(alignActionGroup,"leftAlignAction");
    leftAlignAction->setToggleAction(1);
    leftAlignAction->setIconSet(Qt::IconSet(uic_load_pixmap_EditorForm("textleft")));
    leftAlignAction->setText(this->trUtf8("left"));
    leftAlignAction->setMenuText(this->trUtf8("&Left"));
    leftAlignAction->setAccel(Qt::KeySequence(int(272629836)));
    rightAlignAction= Qt::Action(alignActionGroup,"rightAlignAction");
    rightAlignAction->setToggleAction(1);
    rightAlignAction->setIconSet(Qt::IconSet(uic_load_pixmap_EditorForm("textright")));
    rightAlignAction->setText(this->trUtf8("right"));
    rightAlignAction->setMenuText(this->trUtf8("&Right"));
    rightAlignAction->setAccel(Qt::KeySequence(int(272629842)));
    centerAlignAction= Qt::Action(alignActionGroup,"centerAlignAction");
    centerAlignAction->setToggleAction(1);
    centerAlignAction->setIconSet(Qt::IconSet(uic_load_pixmap_EditorForm("textcenter")));
    centerAlignAction->setText(this->trUtf8("center"));
    centerAlignAction->setMenuText(this->trUtf8("&Center"));


    toolBar = Qt::ToolBar("", this, &DockTop);

    toolBar->setLabel(this->trUtf8("Tools"));
    fileNewAction->addTo(toolBar);
    fileOpenAction->addTo(toolBar);
    fileSaveAction->addTo(toolBar);
    toolBar->addSeparator;
    editUndoAction->addTo(toolBar);
    editRedoAction->addTo(toolBar);
    editCutAction->addTo(toolBar);
    editCopyAction->addTo(toolBar);
    editPasteAction->addTo(toolBar);
    Toolbar = Qt::ToolBar("", this, &DockTop);

    Toolbar->setLabel(this->trUtf8("Toolbar"));
    leftAlignAction->addTo(Toolbar);
    centerAlignAction->addTo(Toolbar);
    rightAlignAction->addTo(Toolbar);
    Toolbar->addSeparator;
    boldAction->addTo(Toolbar);
    italicAction->addTo(Toolbar);
    underlineAction->addTo(Toolbar);
    Toolbar->addSeparator;

    fontComboBox = Qt::ComboBox(0, Toolbar, "fontComboBox");

    SpinBox2 = Qt::SpinBox(Toolbar, "SpinBox2");
    SpinBox2->setMinValue(int(6));
    SpinBox2->setValue(int(10));


    menubar= Qt::MenuBar( this, "menubar");

    fileMenu= Qt::PopupMenu(this);
    fileNewAction->addTo(fileMenu);
    fileOpenAction->addTo(fileMenu);
    fileSaveAction->addTo(fileMenu);
    fileSaveAsAction->addTo(fileMenu);
    fileMenu->insertSeparator;
    fileExitAction->addTo(fileMenu);
    menubar->insertItem(this->trUtf8("&File"), fileMenu);

    editMenu= Qt::PopupMenu(this);
    editUndoAction->addTo(editMenu);
    editRedoAction->addTo(editMenu);
    editMenu->insertSeparator;
    editCutAction->addTo(editMenu);
    editCopyAction->addTo(editMenu);
    editPasteAction->addTo(editMenu);
    menubar->insertItem(this->trUtf8("&Edit"), editMenu);

    PopupMenu_2= Qt::PopupMenu(this);
    leftAlignAction->addTo(PopupMenu_2);
    rightAlignAction->addTo(PopupMenu_2);
    centerAlignAction->addTo(PopupMenu_2);
    PopupMenu_2->insertSeparator;
    boldAction->addTo(PopupMenu_2);
    italicAction->addTo(PopupMenu_2);
    underlineAction->addTo(PopupMenu_2);
    menubar->insertItem(this->trUtf8("F&ormat"), PopupMenu_2);

    helpMenu= Qt::PopupMenu(this);
    helpContentsAction->addTo(helpMenu);
    helpIndexAction->addTo(helpMenu);
    helpMenu->insertSeparator;
    helpAboutAction->addTo(helpMenu);
    menubar->insertItem(this->trUtf8("&Help"), helpMenu);



    Qt::Object::connect(fileNewAction, SIGNAL "activated()", this, SLOT "fileNew()");
    Qt::Object::connect(fileOpenAction, SIGNAL "activated()", this, SLOT "fileOpen()");
    Qt::Object::connect(fileSaveAction, SIGNAL "activated()", this, SLOT "fileSave()");
    Qt::Object::connect(fileSaveAsAction, SIGNAL "activated()", this, SLOT "fileSaveAs()");
    Qt::Object::connect(fileExitAction, SIGNAL "activated()", this, SLOT "fileExit()");
    Qt::Object::connect(helpIndexAction, SIGNAL "activated()", this, SLOT "helpIndex()");
    Qt::Object::connect(helpContentsAction, SIGNAL "activated()", this, SLOT "helpContents()");
    Qt::Object::connect(helpAboutAction, SIGNAL "activated()", this, SLOT "helpAbout()");
    Qt::Object::connect(SpinBox2, SIGNAL "valueChanged(int)", textEdit, SLOT "setPointSize(int)");
    Qt::Object::connect(editCutAction, SIGNAL "activated()", textEdit, SLOT "cut()");
    Qt::Object::connect(editPasteAction, SIGNAL "activated()", textEdit, SLOT "paste()");
    Qt::Object::connect(editCopyAction, SIGNAL "activated()", textEdit, SLOT "copy()");
    Qt::Object::connect(editRedoAction, SIGNAL "activated()", textEdit, SLOT "redo()");
    Qt::Object::connect(editUndoAction, SIGNAL "activated()", textEdit, SLOT "undo()");
    Qt::Object::connect(alignActionGroup, SIGNAL "selected(QAction*)", this, SLOT "changeAlignment(QAction*)");
    Qt::Object::connect(underlineAction, SIGNAL "toggled(bool)", textEdit, SLOT "setUnderline(bool)");
    Qt::Object::connect(italicAction, SIGNAL "toggled(bool)", textEdit, SLOT "setItalic(bool)");
    Qt::Object::connect(boldAction, SIGNAL "toggled(bool)", textEdit, SLOT "setBold(bool)");
    Qt::Object::connect(fontComboBox, SIGNAL "activated(const QString&)", textEdit, SLOT "setFamily(const QString&)");
    Qt::Object::connect(fontComboBox, SIGNAL "activated(const QString&)", textEdit, SLOT "setFocus()");

    init();
}


sub init
{

    textEdit->setFocus;
    my $fonts = Qt::FontDatabase;
    fontComboBox->insertStringList($fonts->families);
    my $font = lc textEdit->family;
    for(my $i = 0; $i < fontComboBox->count; $i++) {
        if($font eq fontComboBox->text($i)) {
            fontComboBox->setCurrentItem($i);
            last;
        }
    }

}

sub fileExit
{
    print "EditorForm->fileExit(): Not implemented yet.\n";
}

sub fileNew
{
    print "EditorForm->fileNew(): Not implemented yet.\n";
}

sub fileOpen
{
    print "EditorForm->fileOpen(): Not implemented yet.\n";
}

sub fileSave
{
    print "EditorForm->fileSave(): Not implemented yet.\n";
}

sub fileSaveAs
{
    print "EditorForm->fileSaveAs(): Not implemented yet.\n";
}

sub helpAbout
{
    print "EditorForm->helpAbout(): Not implemented yet.\n";
}

sub helpContents
{
    print "EditorForm->helpContents(): Not implemented yet.\n";
}

sub helpIndex
{
    print "EditorForm->helpIndex(): Not implemented yet.\n";
}

sub changeAlignment
{
    print "EditorForm->changeAlignment(QAction*): Not implemented yet.\n";
}

sub saveAndContinue
{
    print "EditorForm->saveAndContinue(const QString&): Not implemented yet.\n";
}

1;


package main;

use Qt;
use EditorForm;
use imageCollection;

my $a = Qt::Application(\@ARGV);
Qt::Object::connect($a, SIGNAL("lastWindowClosed()"), $a, SLOT("quit()"));
my $w = EditorForm;
$a->setMainWidget($w);
$w->show;
exit $a->exec;


