package LanguageChooser;

use strict;
use warnings;

# Since we lack qHash, use md5
use Digest::MD5 qw(md5_hex);

use QtCore4;
use QtGui4;
use QtCore4::isa qw( Qt::Dialog );
use QtCore4::slots
    checkBoxToggled => [],
    showAll => [],
    hideAll => [];
use MainWindow;

sub groupBox() {
    return this->{groupBox};
}

sub buttonBox() {
    return this->{buttonBox};
}

sub showAllButton() {
    return this->{showAllButton};
}

sub hideAllButton() {
    return this->{hideAllButton};
}

sub qmFileForCheckBoxMap() {
    return this->{qmFileForCheckBoxMap};
}

sub mainWindowForCheckBoxMap() {
    return this->{mainWindowForCheckBoxMap};
}

sub NEW {
    my ( $class, $parent ) = @_;
    $class->SUPER::NEW( $parent, Qt::WindowStaysOnTopHint());
    my $groupBox = Qt::GroupBox('Languages');
    this->{groupBox} = $groupBox;

    my $groupBoxLayout = Qt::GridLayout();

    my $qmFiles = this->findQmFiles();
    for (my $i = 0; $i < $#{$qmFiles}; ++$i) {
        my $languageName = this->languageName($qmFiles->[$i]);
        my $checkBox = Qt::CheckBox( $languageName );
        $checkBox->setObjectName( $languageName );
        this->{qmFileForCheckBoxMap}->{$languageName} = [$checkBox, $qmFiles->[$i]];
        this->connect($checkBox, SIGNAL 'toggled(bool)', this, SLOT 'checkBoxToggled()');
        $groupBoxLayout->addWidget($checkBox, $i / 2, $i % 2);
    }
    $groupBox->setLayout($groupBoxLayout);

    my $buttonBox = Qt::DialogButtonBox();
    this->{buttonBox} = $buttonBox;

    my $showAllButton = buttonBox->addButton('Show All',
                                         Qt::DialogButtonBox::ActionRole());
    this->{showAllButton} = $showAllButton;
    my $hideAllButton = buttonBox->addButton('Hide All',
                                         Qt::DialogButtonBox::ActionRole());
    this->{hideAllButton} = $hideAllButton;

    this->connect($showAllButton, SIGNAL 'clicked()', this, SLOT 'showAll()');
    this->connect($hideAllButton, SIGNAL 'clicked()', this, SLOT 'hideAll()');

    my $mainLayout = Qt::VBoxLayout();
    $mainLayout->addWidget($groupBox);
    $mainLayout->addWidget($buttonBox);
    this->setLayout($mainLayout);

    this->setWindowTitle('I18N');
}

sub eventFilter {
    my ($object, $event) = @_;
    if ($event->type() == Qt::Event::Close()) {
        # TODO Write support for qobject_cast
        my $window = bless $object, ' MainWindow';
        if ($window->inherits( 'QMainWindow' ) ) {
            my $checkBox = this->mainWindowForCheckBoxMap->{$window->objectName()}->{checkBox};
            if ($checkBox) {
                $checkBox->setChecked(0);
            }
        }
    }
    return this->SUPER::eventFilter($object, $event);
}

sub closeEvent {
    qApp->quit();
}

sub checkBoxToggled {
    my $checkBox = this->sender();
    if( $checkBox->inherits( 'QCheckBox' ) ) {
        $checkBox = bless $checkBox, ' Qt::CheckBox';
    }
    else {
        return;
    }
    my $window = this->{mainWindowForCheckBoxMap}->{$checkBox->objectName()}->{window};
    if (!$window) {
        my $translator = Qt::Translator();
        $translator->load(this->qmFileForCheckBoxMap->{$checkBox->objectName()}->[1]);
        qApp->installTranslator($translator);

        $window = MainWindow();
        $window->setObjectName( $checkBox->objectName() );
        $window->setPalette(Qt::Palette(this->colorForLanguage($checkBox->text())));

        $window->installEventFilter(this);
        this->mainWindowForCheckBoxMap->{$checkBox->objectName()}->{window} = $window;
        this->mainWindowForCheckBoxMap->{$checkBox->objectName()}->{checkBox} = $checkBox;
    }
    $window->setVisible($checkBox->isChecked());
}

sub showAll {
    foreach my $language (keys %{this->qmFileForCheckBoxMap} ) {
        my $checkBox = this->qmFileForCheckBoxMap->{$language}->[0];
        $checkBox->setChecked(1);
    }
}

sub hideAll {
    foreach my $language ( keys %{this->qmFileForCheckBoxMap} ) {
        my $checkBox = this->qmFileForCheckBoxMap->{$language}->[0];
        $checkBox->setChecked(0);
    }
}

sub findQmFiles {
    my $dir = Qt::Dir('translations');
    my $fileNames = $dir->entryList(['*.qm'], Qt::Dir::Files(), Qt::Dir::Name());
    return [] unless ref $fileNames eq 'ARRAY';
    foreach my $i ( @{$fileNames} ) {
        $i = $dir->filePath($i);
    }
    return $fileNames;
}

sub languageName {
    my ($qmFile) = @_;
    my $translator = Qt::Translator();
    $translator->load($qmFile);

    return $translator->translate('MainWindow', 'English');
}

sub colorForLanguage {
    my ($language) = @_;
    # Since we lack qHash, use md5
    utf8::encode($language);
    my $hashValue = md5_hex($language);
    $hashValue = eval( '0x'.substr( $hashValue, 0, 6 ) );

    my $red = 156 + ($hashValue & 0x3F);
    my $green = 156 + (($hashValue >> 6) & 0x3F);
    my $blue = 156 + (($hashValue >> 12) & 0x3F);
    return Qt::Color($red, $green, $blue);
}

1;
