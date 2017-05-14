package Screenshot; 

use strict;
use warnings;
use QtCore4;
use QtGui4;
# [0]
use QtCore4::isa qw( Qt::Widget );
use QtCore4::slots
    newScreenshot => [],
    saveScreenshot => [],
    shootScreen => [],
    updateCheckBox => [];

sub originalPixmap() {
    return this->{originalPixmap};
}

sub setOriginalPixmap($) {
    return this->{originalPixmap} = shift;
}

sub screenshotLabel() {
    return this->{screenshotLabel};
}

sub setScreenshotLabel($) {
    return this->{screenshotLabel} = shift;
}

sub optionsGroupBox() {
    return this->{optionsGroupBox};
}

sub setOptionsGroupBox($) {
    return this->{optionsGroupBox} = shift;
}

sub delaySpinBox() {
    return this->{delaySpinBox};
}

sub setDelaySpinBox($) {
    return this->{delaySpinBox} = shift;
}

sub delaySpinBoxLabel() {
    return this->{delaySpinBoxLabel};
}

sub setDelaySpinBoxLabel($) {
    return this->{delaySpinBoxLabel} = shift;
}

sub hideThisWindowCheckBox() {
    return this->{hideThisWindowCheckBox};
}

sub setHideThisWindowCheckBox($) {
    return this->{hideThisWindowCheckBox} = shift;
}

sub newScreenshotButton() {
    return this->{newScreenshotButton};
}

sub setNewScreenshotButton($) {
    return this->{newScreenshotButton} = shift;
}

sub saveScreenshotButton() {
    return this->{saveScreenshotButton};
}

sub setSaveScreenshotButton($) {
    return this->{saveScreenshotButton} = shift;
}

sub quitScreenshotButton() {
    return this->{quitScreenshotButton};
}

sub setQuitScreenshotButton($) {
    return this->{quitScreenshotButton} = shift;
}

sub mainLayout() {
    return this->{mainLayout};
}

sub setMainLayout($) {
    return this->{mainLayout} = shift;
}

sub optionsGroupBoxLayout() {
    return this->{optionsGroupBoxLayout};
}

sub setOptionsGroupBoxLayout($) {
    return this->{optionsGroupBoxLayout} = shift;
}

sub buttonsLayout() {
    return this->{buttonsLayout};
}

sub setButtonsLayout($) {
    return this->{buttonsLayout} = shift;
}
# [0]

# [0]
sub NEW
{
    my ($class) = @_;
    $class->SUPER::NEW();
    this->setScreenshotLabel( Qt::Label() );
    this->screenshotLabel->setSizePolicy(Qt::SizePolicy::Expanding(),
                                         Qt::SizePolicy::Expanding());
    this->screenshotLabel->setAlignment(Qt::AlignCenter());
    this->screenshotLabel->setMinimumSize(240, 160);

    this->createOptionsGroupBox();
    this->createButtonsLayout();

    this->setMainLayout( Qt::VBoxLayout() );
    this->mainLayout->addWidget(this->screenshotLabel);
    this->mainLayout->addWidget(this->optionsGroupBox);
    this->mainLayout->addLayout(this->buttonsLayout);
    this->setLayout(this->mainLayout);

    this->shootScreen();
    this->delaySpinBox->setValue(5);

    this->setWindowTitle(this->tr('Screenshot'));
    this->resize(300, 200);
}
# [0]

# [1]
sub resizeEvent
{
    my $scaledSize = this->originalPixmap->size();
    $scaledSize->scale(this->screenshotLabel->size(), Qt::KeepAspectRatio());
    if (!this->screenshotLabel->pixmap()
            || $scaledSize != this->screenshotLabel->pixmap()->size()) {
        this->updateScreenshotLabel();
    }
}
# [1]

# [2]
sub newScreenshot
{
    if (this->hideThisWindowCheckBox->isChecked()) {
        this->hide();
    }
    this->newScreenshotButton->setDisabled(1);

    Qt::Timer::singleShot(this->delaySpinBox->value() * 1000, this, SLOT 'shootScreen()');
}
# [2]

# [3]
sub saveScreenshot
{
    my $format = 'png';
    my $initialPath = Qt::Dir::currentPath() . this->tr('/untitled.') . $format;

    my $fileName = Qt::FileDialog::getSaveFileName(this, this->tr('Save As'),
                               $initialPath,
                       sprintf this->tr('%s Files (*.%s);;All Files (*)'),
                               uc($format),
                               $format);
    if ($fileName) {
        this->originalPixmap->save($fileName, $format);
    }
}
# [3]

# [4]
sub shootScreen
{
    if (this->delaySpinBox->value() != 0) {
        qApp->beep();
    }
# [4]
     # clear image for low memory situations on embedded devices.
    this->setOriginalPixmap( Qt::Pixmap() );
# [5]
    this->setOriginalPixmap( Qt::Pixmap::grabWindow(Qt::Application::desktop()->winId()) );
    this->updateScreenshotLabel();

    this->newScreenshotButton->setDisabled(0);
    if (this->hideThisWindowCheckBox->isChecked()) {
        this->show();
    }
}
# [5]

# [6]
sub updateCheckBox
{
    if (this->delaySpinBox->value() == 0) {
        this->hideThisWindowCheckBox->setDisabled(1);
    }
    else {
        this->hideThisWindowCheckBox->setDisabled(0);
    }
}
# [6]

# [7]
sub createOptionsGroupBox
{
    this->setOptionsGroupBox( Qt::GroupBox(this->tr('Options')) );

    this->setDelaySpinBox( Qt::SpinBox() );
    this->delaySpinBox->setSuffix(this->tr(' s'));
    this->delaySpinBox->setMaximum(60);
    this->connect(this->delaySpinBox, SIGNAL 'valueChanged(int)', this, SLOT 'updateCheckBox()');

    this->setDelaySpinBoxLabel( Qt::Label(this->tr('Screenshot Delay:')) );

    this->setHideThisWindowCheckBox( Qt::CheckBox(this->tr('Hide This Window')) );

    this->setOptionsGroupBoxLayout( Qt::GridLayout() );
    this->optionsGroupBoxLayout->addWidget(this->delaySpinBoxLabel, 0, 0);
    this->optionsGroupBoxLayout->addWidget(this->delaySpinBox, 0, 1);
    this->optionsGroupBoxLayout->addWidget(this->hideThisWindowCheckBox, 1, 0, 1, 2);
    this->optionsGroupBox->setLayout(this->optionsGroupBoxLayout);
}
# [7]

# [8]
sub createButtonsLayout
{
    this->setNewScreenshotButton( createButton(this->tr('New Screenshot'),
                                       this, SLOT 'newScreenshot()') );

    this->setSaveScreenshotButton( createButton(this->tr('Save Screenshot'),
                                        this, SLOT 'saveScreenshot()') );

    this->setQuitScreenshotButton( createButton(this->tr('Quit'), this, SLOT 'close()') );

    this->setButtonsLayout( Qt::HBoxLayout() );
    this->buttonsLayout->addStretch();
    this->buttonsLayout->addWidget(this->newScreenshotButton);
    this->buttonsLayout->addWidget(this->saveScreenshotButton);
    this->buttonsLayout->addWidget(this->quitScreenshotButton);
}
# [8]

# [9]
sub createButton
{
    my ($text, $receiver, $member) = @_;
    my $button = Qt::PushButton($text);
    $button->connect($button, SIGNAL 'clicked()', $receiver, $member);
    return $button;
}
# [9]

# [10]
sub updateScreenshotLabel
{
    this->screenshotLabel->setPixmap(this->originalPixmap->scaled(this->screenshotLabel->size(),
                                                     Qt::KeepAspectRatio(),
                                                     Qt::SmoothTransformation()));
}
# [10]

1;
