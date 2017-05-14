package LicenseWizard;

use strict;
use warnings;

use constant {
    Page_Intro => 1,
    Page_Evaluate => 2,
    Page_Register => 3,
    Page_Details => 4,
    Page_Conclusion => 5
};

require Exporter;
my @ISA = qw(Exporter);
my @EXPORT_OK = qw( Page_Intro Page_Evaluate Page_Register Page_Details Page_Conclusion );

use QtCore4;
use QtGui4;
use QtCore4::isa qw( Qt::Wizard );
use QtCore4::slots
    showHelp => [];

package IntroPage;

use strict;
use warnings;

use QtCore4;
use QtGui4;
use QtCore4::isa qw( Qt::WizardPage );

# [16]
sub NEW {
    my ( $class, $parent ) = @_;
    $class->SUPER::NEW( $parent );

    this->setTitle(this->tr('Introduction'));
    this->setPixmap(Qt::Wizard::WatermarkPixmap(), Qt::Pixmap('images/watermark.png'));

    my $topLabel = Qt::Label(this->tr('This wizard will help you register your copy of ' .
                             '<i>Super Product One</i>&trade; or start ' .
                             'evaluating the product.'));
    this->{topLabel} = $topLabel;
    $topLabel->setWordWrap(1);

    my $registerRadioButton = Qt::RadioButton(this->tr('&Register your copy'));
    this->{registerRadioButton} = $registerRadioButton;
    my $evaluateRadioButton = Qt::RadioButton(this->tr('&Evaluate the product for 30 ' .
                                              'days'));
    this->{evaluateRadioButton} = $evaluateRadioButton;
    $registerRadioButton->setChecked(1);

    my $layout = Qt::VBoxLayout();
    $layout->addWidget($topLabel);
    $layout->addWidget($registerRadioButton);
    $layout->addWidget($evaluateRadioButton);
    this->setLayout($layout);
}
# [16] //! [17]

# [18]
sub nextId {
# [17] //! [19]
    my $evaluateRadioButton = this->{evaluateRadioButton};
    if ($evaluateRadioButton->isChecked()) {
        return LicenseWizard::Page_Evaluate;
    } else {
        return LicenseWizard::Page_Register;
    }
}
# [18] //! [19]

package EvaluatePage;

use strict;
use warnings;

use QtCore4;
use QtGui4;
use QtCore4::isa qw( Qt::WizardPage );

sub NEW {
    my ( $class, $parent ) = @_;
    $class->SUPER::NEW( $parent );
# [20]
    this->setTitle(this->tr('Evaluate <i>Super Product One</i>&trade;'));
    this->setSubTitle(this->tr('Please fill both fields. Make sure to provide a valid ' .
                   'email address (e.g., john.smith@example.com).'));

    my $nameLabel = Qt::Label(this->tr('N&ame:'));
    this->{nameLabel} = $nameLabel;
    my $nameLineEdit = Qt::LineEdit();
    this->{nameLineEdit} = $nameLineEdit;
# [20]
    $nameLabel->setBuddy($nameLineEdit);

    my $emailLabel = Qt::Label(this->tr('&Email address:'));
    this->{emailLabel} = $emailLabel;
    my $emailLineEdit = Qt::LineEdit();
    this->{emailLineEdit} = $emailLineEdit;
    $emailLineEdit->setValidator(Qt::RegExpValidator(Qt::RegExp('.*@.*'), this));
    $emailLabel->setBuddy($emailLineEdit);

# [21]
    this->registerField('evaluate.name*', $nameLineEdit);
    this->registerField('evaluate.email*', $emailLineEdit);
# [21]

    my $layout = Qt::GridLayout();
    $layout->addWidget($nameLabel, 0, 0);
    $layout->addWidget($nameLineEdit, 0, 1);
    $layout->addWidget($emailLabel, 1, 0);
    $layout->addWidget($emailLineEdit, 1, 1);
    this->setLayout($layout);
# [22]
}
# [22]

# [23]
sub nextId {
    return LicenseWizard::Page_Conclusion;
}
# [23]


package RegisterPage;

use strict;
use warnings;

use QtCore4;
use QtGui4;
use QtCore4::isa qw( Qt::WizardPage );

sub NEW {
    my ( $class, $parent ) = @_;
    $class->SUPER::NEW( $parent );

    this->setTitle(this->tr('Register Your Copy of <i>Super Product One</i>&trade;'));
    this->setSubTitle(this->tr('If you have an upgrade key, please fill in ' .
                   'the appropriate field.'));

    my $nameLabel = Qt::Label(this->tr('N&ame:'));
    this->{nameLabel} = $nameLabel;
    my $nameLineEdit = Qt::LineEdit();
    this->{nameLineEdit} = $nameLineEdit;
    $nameLabel->setBuddy($nameLineEdit);

    my $upgradeKeyLabel = Qt::Label(this->tr('&Upgrade key:'));
    this->{upgradeKeyLabel} = $upgradeKeyLabel;
    my $upgradeKeyLineEdit = Qt::LineEdit();
    this->{upgradeKeyLineEdit} = $upgradeKeyLineEdit;
    $upgradeKeyLabel->setBuddy($upgradeKeyLineEdit);

    this->registerField('register.name*', $nameLineEdit);
    this->registerField('register.upgradeKey', $upgradeKeyLineEdit);

    my $layout = Qt::GridLayout();
    $layout->addWidget($nameLabel, 0, 0);
    $layout->addWidget($nameLineEdit, 0, 1);
    $layout->addWidget($upgradeKeyLabel, 1, 0);
    $layout->addWidget($upgradeKeyLineEdit, 1, 1);
    this->setLayout($layout);
}

# [24]
sub nextId {
    if (!this->{upgradeKeyLineEdit}->text()) {
        return LicenseWizard::Page_Details;
    } else {
        return LicenseWizard::Page_Conclusion;
    }
}
# [24]


package DetailsPage;

use strict;
use warnings;

use QtCore4;
use QtGui4;
use QtCore4::isa qw( Qt::WizardPage );

sub NEW {
    my ( $class, $parent ) = @_;
    $class->SUPER::NEW( $parent );
    this->setTitle(this->tr('Fill In Your Details'));
    this->setSubTitle(this->tr('Please fill all three fields. Make sure to provide a valid ' .
                   'email address (e.g., tanaka.aya@example.co.jp).'));

    my $companyLabel = Qt::Label(this->tr('&Company name:'));
    this->{companyLabel} = $companyLabel;
    my $companyLineEdit = Qt::LineEdit();
    this->{companyLineEdit} = $companyLineEdit;
    $companyLabel->setBuddy($companyLineEdit);

    my $emailLabel = Qt::Label(this->tr('&Email address:'));
    this->{emailLabel} = $emailLabel;
    my $emailLineEdit = Qt::LineEdit();
    this->{emailLineEdit} = $emailLineEdit;
    $emailLineEdit->setValidator(Qt::RegExpValidator(Qt::RegExp('.*@.*'), this));
    $emailLabel->setBuddy($emailLineEdit);

    my $postalLabel = Qt::Label(this->tr('&Postal address:'));
    this->{postalLabel} = $postalLabel;
    my $postalLineEdit = Qt::LineEdit();
    this->{postalLineEdit} = $postalLineEdit;
    $postalLabel->setBuddy($postalLineEdit);

    this->registerField('details.company*', $companyLineEdit);
    this->registerField('details.email*', $emailLineEdit);
    this->registerField('details.postal*', $postalLineEdit);

    my $layout = Qt::GridLayout();
    $layout->addWidget($companyLabel, 0, 0);
    $layout->addWidget($companyLineEdit, 0, 1);
    $layout->addWidget($emailLabel, 1, 0);
    $layout->addWidget($emailLineEdit, 1, 1);
    $layout->addWidget($postalLabel, 2, 0);
    $layout->addWidget($postalLineEdit, 2, 1);
    this->setLayout($layout);
}

# [25]
sub nextId {
    return LicenseWizard::Page_Conclusion;
}
# [25]

package ConclusionPage;

use strict;
use warnings;

use QtCore4;
use QtGui4;
use QtCore4::isa qw( Qt::WizardPage );
use QtCore4::slots
    printButtonClicked => [];

sub NEW {
    my ( $class, $parent ) = @_;
    $class->SUPER::NEW( $parent );
    this->setTitle(this->tr("Complete Your Registration"));
    this->setPixmap(Qt::Wizard::WatermarkPixmap(), Qt::Pixmap("images/watermark.png"));

    my $bottomLabel = Qt::Label();
    this->{bottomLabel} = $bottomLabel;
    $bottomLabel->setWordWrap(1);

    my $agreeCheckBox = Qt::CheckBox(this->tr("I agree to the terms of the license"));
    this->{agreeCheckBox} = $agreeCheckBox;

    this->registerField("conclusion.agree*", $agreeCheckBox);

    my $layout = Qt::VBoxLayout();
    $layout->addWidget($bottomLabel);
    $layout->addWidget($agreeCheckBox);
    this->setLayout($layout);
}

# [26]
sub nextId {
    return -1;
}
# [26]

# [27]
sub initializePage {
    my $licenseText;

    if (this->wizard()->hasVisitedPage(LicenseWizard::Page_Evaluate)) {
        $licenseText = this->tr('<u>Evaluation License Agreement:</u> ' .
                         'You can use this software for 30 days and make one ' .
                         'backup, but you are not allowed to distribute it.');
    } elsif (this->wizard()->hasVisitedPage(LicenseWizard::Page_Details)) {
        $licenseText = this->tr('<u>First-Time License Agreement:</u> ' .
                         'You can use this software subject to the license ' .
                         'you will receive by email.');
    } else {
        $licenseText = this->tr('<u>Upgrade License Agreement:</u> ' .
                         'This software is licensed under the terms of your ' .
                         'current license.');
    }
    this->{bottomLabel}->setText($licenseText);
}
# [27]

# [28]
sub setVisible {
    my ( $visible ) = @_;
    this->SUPER::setVisible($visible);

    if ($visible) {
# [29]
        this->wizard()->setButtonText(Qt::Wizard::CustomButton1(), this->tr("&Print"));
        this->wizard()->setOption(Qt::Wizard::HaveCustomButton1(), 1);
        this->connect(this->wizard(), SIGNAL 'customButtonClicked(int)',
                this, SLOT 'printButtonClicked()');
# [29]
    } else {
        this->wizard()->setOption(Qt::Wizard::HaveCustomButton1(), 0);
        this->disconnect(this->wizard(), SIGNAL 'customButtonClicked(int)',
                   this, SLOT 'printButtonClicked()');
    }
}
# [28]

sub printButtonClicked {
    my $printer = Qt::Printer();
    my $dialog = Qt::PrintDialog($printer, this);
    if ($dialog->exec()) {
        Qt::MessageBox::warning(this, this->tr('Print License'),
                             this->tr('As an environmentally friendly measure, the ' .
                                'license text will not actually be printed.'));
    }
}

package LicenseWizard;

use IntroPage;
use EvaluatePage;
use RegisterPage;
use DetailsPage;
use ConclusionPage;

my $lastHelpMessage;

sub NEW {
    my ( $class, $parent ) = @_;
    $class->SUPER::NEW( $parent );
# [0]
    this->setPage(Page_Intro, IntroPage());
    this->setPage(Page_Evaluate, EvaluatePage());
    this->setPage(Page_Register, RegisterPage());
    this->setPage(Page_Details, DetailsPage());
    this->setPage(Page_Conclusion, ConclusionPage());
# [1]

    this->setStartId(Page_Intro);
# [2]

# [3]
# [3] //! [4]
    this->setWizardStyle(Qt::Wizard::ModernStyle());
# [4] //! [5]
    this->setOption(Qt::Wizard::HaveHelpButton(), 1);
# [5] //! [6]
    this->setPixmap(Qt::Wizard::LogoPixmap(), Qt::Pixmap('images/logo.png'));

# [7]
    this->connect(this, SIGNAL 'helpRequested()', this, SLOT 'showHelp()');
# [7]

    this->setWindowTitle(this->tr("License Wizard"));
# [8]
}
# [6] //! [8]

# [9] //! [10]
sub showHelp {
# [9] //! [11]

    my $message;

    if ( this->currentId() == Page_Intro ) {
        $message = this->tr('The decision you make here will affect which page you ' .
                     'get to see next.');
# [10] //! [11]
    } elsif ( this->currentId() == Page_Evaluate ) {
        $message = this->tr('Make sure to provide a valid email address, such as ' .
                     'toni.buddenbrook@example.de.');
    } elsif ( this->currentId() == Page_Register ) {
        $message = this->tr('If you don\'t provide an upgrade key, you will be ' .
                     'asked to fill in your details.');
    } elsif ( this->currentId() == Page_Details ) {
        $message = this->tr('Make sure to provide a valid email address, such as ' .
                     'thomas.gradgrind@example.co.uk.');
    } elsif ( this->currentId() == Page_Conclusion ) {
        $message = this->tr('You must accept the terms and conditions of the ' .
                     'license to proceed.');
# [12] //! [13]
    } else {
        $message = this->tr('This help is likely not to be of any help.');
    }
# [12]

    if ($lastHelpMessage == $message) {
        $message = this->tr('Sorry, I already gave what help I could. ' .
                     'Maybe you should try asking a human?');
    }

# [14]
    Qt::MessageBox::information(this, this->tr('License Wizard Help'), $message);
# [14]

    $lastHelpMessage = $message;
# [15]
}
# [13] //! [15]

1;
