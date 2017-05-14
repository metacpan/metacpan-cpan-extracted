package GeneralTab;

use strict;
use warnings;

use QtCore4;
use QtGui4;
use QtCore4::isa qw( Qt::Widget );

sub NEW {
    my ( $class, $fileInfo, $parent ) = @_;
    $class->SUPER::NEW( $parent );

    my $fileNameLabel = Qt::Label(this->tr('File Name:'));
    my $fileNameEdit = Qt::LineEdit($fileInfo->fileName());

    my $pathLabel = Qt::Label(this->tr('Path:'));
    my $pathValueLabel = Qt::Label($fileInfo->absoluteFilePath());
    $pathValueLabel->setFrameStyle(Qt::Frame::Panel() | Qt::Frame::Sunken());

    my $sizeLabel = Qt::Label(this->tr('Size:'));
    my $size = $fileInfo->size()/1024;
    my $sizeValueLabel = Qt::Label(this->tr(sprintf '%d K', $size));
    $sizeValueLabel->setFrameStyle(Qt::Frame::Panel() | Qt::Frame::Sunken());

    my $lastReadLabel = Qt::Label(this->tr('Last Read:'));
    my $lastReadValueLabel = Qt::Label($fileInfo->lastRead()->toString());
    $lastReadValueLabel->setFrameStyle(Qt::Frame::Panel() | Qt::Frame::Sunken());

    my $lastModLabel = Qt::Label(this->tr('Last Modified:'));
    my $lastModValueLabel = Qt::Label($fileInfo->lastModified()->toString());
    $lastModValueLabel->setFrameStyle(Qt::Frame::Panel() | Qt::Frame::Sunken());

    my $mainLayout = Qt::VBoxLayout;
    $mainLayout->addWidget($fileNameLabel);
    $mainLayout->addWidget($fileNameEdit);
    $mainLayout->addWidget($pathLabel);
    $mainLayout->addWidget($pathValueLabel);
    $mainLayout->addWidget($sizeLabel);
    $mainLayout->addWidget($sizeValueLabel);
    $mainLayout->addWidget($lastReadLabel);
    $mainLayout->addWidget($lastReadValueLabel);
    $mainLayout->addWidget($lastModLabel);
    $mainLayout->addWidget($lastModValueLabel);
    $mainLayout->addStretch(1);
    this->setLayout($mainLayout);
}

package PermissionsTab;

use strict;
use warnings;

use QtCore4;
use QtGui4;
use QtCore4::isa qw( Qt::Widget );

sub NEW {
    my ( $class, $fileInfo, $parent ) = @_;
    $class->SUPER::NEW( $parent );

    my $permissionsGroup = Qt::GroupBox(this->tr('Permissions'));

    my $readable = Qt::CheckBox(this->tr('Readable'));
    $readable->setChecked(1) if ($fileInfo->isReadable());
        
    my $writable = Qt::CheckBox(this->tr('Writable'));
    $writable->setChecked(1) if ( $fileInfo->isWritable() );

    my $executable = Qt::CheckBox(this->tr('Executable'));
    $executable->setChecked(1) if ( $fileInfo->isExecutable() );

    my $ownerGroup = Qt::GroupBox(this->tr('Ownership'));

    my $ownerLabel = Qt::Label(this->tr('Owner'));
    my $ownerValueLabel = Qt::Label($fileInfo->owner());
    $ownerValueLabel->setFrameStyle(Qt::Frame::Panel() | Qt::Frame::Sunken());

    my $groupLabel = Qt::Label(this->tr('Group'));
    my $groupValueLabel = Qt::Label($fileInfo->group());
    $groupValueLabel->setFrameStyle(Qt::Frame::Panel() | Qt::Frame::Sunken());

    my $permissionsLayout = Qt::VBoxLayout();
    $permissionsLayout->addWidget($readable);
    $permissionsLayout->addWidget($writable);
    $permissionsLayout->addWidget($executable);
    $permissionsGroup->setLayout($permissionsLayout);

    my $ownerLayout = Qt::VBoxLayout();
    $ownerLayout->addWidget($ownerLabel);
    $ownerLayout->addWidget($ownerValueLabel);
    $ownerLayout->addWidget($groupLabel);
    $ownerLayout->addWidget($groupValueLabel);
    $ownerGroup->setLayout($ownerLayout);

    my $mainLayout = Qt::VBoxLayout();
    $mainLayout->addWidget($permissionsGroup);
    $mainLayout->addWidget($ownerGroup);
    $mainLayout->addStretch(1);
    this->setLayout($mainLayout);
}

package ApplicationsTab;

use strict;
use warnings;

use QtCore4;
use QtGui4;
use QtCore4::isa qw( Qt::Widget );

sub NEW {
    my ( $class, $fileInfo, $parent ) = @_;
    $class->SUPER::NEW( $parent );

    my $topLabel = Qt::Label(this->tr('Open with:'));

    my $applicationsListBox = Qt::ListWidget();
    my @applications = map{ "Application $_" } ( 0..30 );

    $applicationsListBox->insertItems(0, \@applications);

    my $alwaysCheckBox;

    if (!$fileInfo->suffix()) {
        $alwaysCheckBox = Qt::CheckBox(this->tr('Always use this application to ' .
            'open this type of file'));
    }
    else {
        $alwaysCheckBox = Qt::CheckBox(this->tr('Always use this application to ' .
            'open files with the extension \'' . $fileInfo->suffix() . '\''));
    }

    my $layout = Qt::VBoxLayout();
    $layout->addWidget($topLabel);
    $layout->addWidget($applicationsListBox);
    $layout->addWidget($alwaysCheckBox);
    this->setLayout($layout);
}

package TabDialog;

use strict;
use warnings;

use QtCore4;
use QtGui4;
use QtCore4::isa qw( Qt::Dialog );
use GeneralTab;
use PermissionsTab;
use ApplicationsTab;

sub NEW {
    my ( $class, $fileName, $parent ) = @_;
    $class->SUPER::NEW( $parent );

    my $fileInfo = Qt::FileInfo($fileName);

    my $tabWidget = Qt::TabWidget();
    this->{tabWidget} = $tabWidget;
    $tabWidget->addTab(GeneralTab($fileInfo), this->tr('General'));
    $tabWidget->addTab(PermissionsTab($fileInfo), this->tr('Permissions'));
    $tabWidget->addTab(ApplicationsTab($fileInfo), this->tr('Applications'));

    my $buttonBox = Qt::DialogButtonBox(Qt::DialogButtonBox::Ok()
                                      | Qt::DialogButtonBox::Cancel());
    this->{buttonBox} = $buttonBox;

    this->connect($buttonBox, SIGNAL 'accepted()', this, SLOT 'accept()');
    this->connect($buttonBox, SIGNAL 'rejected()', this, SLOT 'reject()');

    my $mainLayout = Qt::VBoxLayout();
    $mainLayout->addWidget($tabWidget);
    $mainLayout->addWidget($buttonBox);
    this->setLayout($mainLayout);

    this->setWindowTitle(this->tr('Tab Dialog'));
}

1;
