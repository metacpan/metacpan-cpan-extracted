package IntroPage;

use strict;
use warnings;

use QtCore4;
use QtGui4;
use QtCore4::isa qw( Qt::WizardPage );

#! [7]
sub NEW {
    my ( $class, $parent ) = @_;
    $class->SUPER::NEW( $parent );
    this->setTitle(this->tr('Introduction'));
    this->setPixmap(Qt::Wizard::WatermarkPixmap(), Qt::Pixmap('images/watermark1.png'));

    my $label = Qt::Label(this->tr('This wizard will generate a skeleton C++ class ' .
                          'definition, including a few functions. You simply ' .
                          'need to specify the class name and set a few ' .
                          'options to produce a header file and an ' .
                          'implementation file for your new C++ class.'));
    this->{label} = $label;
    $label->setWordWrap(1);

    my $layout = Qt::VBoxLayout();
    $layout->addWidget($label);
    this->setLayout($layout);
}
#! [7]

package ClassInfoPage;

use strict;
use warnings;

use QtCore4;
use QtGui4;
use QtCore4::isa qw( Qt::WizardPage );

#! [8] //! [9]
sub NEW {
    my ( $class, $parent ) = @_;
    $class->SUPER::NEW( $parent );
#! [8]
    this->setTitle(this->tr('Class Information'));
    this->setSubTitle(this->tr('Specify basic information about the class for which you ' .
                   'want to generate skeleton source code files.'));
    this->setPixmap(Qt::Wizard::LogoPixmap(), Qt::Pixmap('images/logo1.png'));

#! [10]
    my $classNameLabel = Qt::Label(this->tr('&Class name:'));
    this->{classNameLabel} = $classNameLabel;
    my $classNameLineEdit = Qt::LineEdit();
    this->{classNameLineEdit} = $classNameLineEdit;
    $classNameLabel->setBuddy($classNameLineEdit);

    my $baseClassLabel = Qt::Label(this->tr('B&ase class:'));
    this->{baseClassLabel} = $baseClassLabel;
    my $baseClassLineEdit = Qt::LineEdit();
    this->{baseClassLineEdit} = $baseClassLineEdit;
    $baseClassLabel->setBuddy($baseClassLineEdit);

    my $qobjectMacroCheckBox = Qt::CheckBox(this->tr('Generate Q_OBJECT &macro'));
    this->{qobjectMacroCheckBox} = $qobjectMacroCheckBox;

#! [10]
    my $groupBox = Qt::GroupBox(this->tr('C&onstructor'));
    this->{groupBox} = $groupBox;
#! [9]

    my $qobjectCtorRadioButton = Qt::RadioButton(this->tr('&QObject-style constructor'));
    this->{qobjectCtorRadioButton} = $qobjectCtorRadioButton;
    my $qwidgetCtorRadioButton = Qt::RadioButton(this->tr('Q&Widget-style constructor'));
    this->{qwidgetCtorRadioButton} = $qwidgetCtorRadioButton;
    my $defaultCtorRadioButton = Qt::RadioButton(this->tr('&Default constructor'));
    this->{defaultCtorRadioButton} = $defaultCtorRadioButton;
    my $copyCtorCheckBox = Qt::CheckBox(this->tr('&Generate copy constructor and ' .
                                        'operator='));
    this->{copyCtorCheckBox} = $copyCtorCheckBox;

    $defaultCtorRadioButton->setChecked(1);

    this->connect($defaultCtorRadioButton, SIGNAL 'toggled(bool)',
            $copyCtorCheckBox, SLOT 'setEnabled(bool)');

#! [11] //! [12]
    this->registerField('className*', $classNameLineEdit);
    this->registerField('baseClass', $baseClassLineEdit);
    this->registerField('qobjectMacro', $qobjectMacroCheckBox);
#! [11]
    this->registerField('qobjectCtor', $qobjectCtorRadioButton);
    this->registerField('qwidgetCtor', $qwidgetCtorRadioButton);
    this->registerField('defaultCtor', $defaultCtorRadioButton);
    this->registerField('copyCtor', $copyCtorCheckBox);

    my $groupBoxLayout = Qt::VBoxLayout();
#! [12]
    $groupBoxLayout->addWidget($qobjectCtorRadioButton);
    $groupBoxLayout->addWidget($qwidgetCtorRadioButton);
    $groupBoxLayout->addWidget($defaultCtorRadioButton);
    $groupBoxLayout->addWidget($copyCtorCheckBox);
    $groupBox->setLayout($groupBoxLayout);

    my $layout = Qt::GridLayout();
    $layout->addWidget($classNameLabel, 0, 0);
    $layout->addWidget($classNameLineEdit, 0, 1);
    $layout->addWidget($baseClassLabel, 1, 0);
    $layout->addWidget($baseClassLineEdit, 1, 1);
    $layout->addWidget($qobjectMacroCheckBox, 2, 0, 1, 2);
    $layout->addWidget($groupBox, 3, 0, 1, 2);
    this->setLayout($layout);
#! [13]
}
#! [13]

package CodeStylePage;

use strict;
use warnings;

use QtCore4;
use QtGui4;
use QtCore4::isa qw( Qt::WizardPage );

#! [14]
sub NEW {
    my ( $class, $parent ) = @_;
    $class->SUPER::NEW( $parent );
    this->setTitle(this->tr('Code Style Options'));
    this->setSubTitle(this->tr('Choose the formatting of the generated code.'));
    this->setPixmap(Qt::Wizard::LogoPixmap(), Qt::Pixmap('images/logo2.png'));

    my $commentCheckBox = Qt::CheckBox(this->tr('&Start generated files with a ' .
                                       'comment'));
    this->{commentCheckBox} = $commentCheckBox;
#! [14]
    $commentCheckBox->setChecked(1);

    my $protectCheckBox = Qt::CheckBox(this->tr('&Protect header file against multiple ' .
                                       'inclusions'));
    this->{protectCheckBox} = $protectCheckBox;
    $protectCheckBox->setChecked(1);

    my $macroNameLabel = Qt::Label(this->tr('&Macro name:'));
    this->{macroNameLabel} = $macroNameLabel;
    my $macroNameLineEdit = Qt::LineEdit;
    this->{macroNameLineEdit} = $macroNameLineEdit;
    $macroNameLabel->setBuddy($macroNameLineEdit);

    my $includeBaseCheckBox = Qt::CheckBox(this->tr('&Include base class definition'));
    this->{includeBaseCheckBox} = $includeBaseCheckBox;
    my $baseIncludeLabel = Qt::Label(this->tr('Base class include:'));
    this->{baseIncludeLabel} = $baseIncludeLabel;
    my $baseIncludeLineEdit = Qt::LineEdit();
    this->{baseIncludeLineEdit} = $baseIncludeLineEdit;
    $baseIncludeLabel->setBuddy($baseIncludeLineEdit);

    this->connect($protectCheckBox, SIGNAL 'toggled(bool)',
            $macroNameLabel, SLOT 'setEnabled(bool)');
    this->connect($protectCheckBox, SIGNAL 'toggled(bool)',
            $macroNameLineEdit, SLOT 'setEnabled(bool)');
    this->connect($includeBaseCheckBox, SIGNAL 'toggled(bool)',
            $baseIncludeLabel, SLOT 'setEnabled(bool)');
    this->connect($includeBaseCheckBox, SIGNAL 'toggled(bool)',
            $baseIncludeLineEdit, SLOT 'setEnabled(bool)');

    this->registerField('comment', $commentCheckBox);
    this->registerField('protect', $protectCheckBox);
    this->registerField('macroName', $macroNameLineEdit);
    this->registerField('includeBase', $includeBaseCheckBox);
    this->registerField('baseInclude', $baseIncludeLineEdit);

    my $layout = Qt::GridLayout();
    $layout->setColumnMinimumWidth(0, 20);
    $layout->addWidget($commentCheckBox, 0, 0, 1, 3);
    $layout->addWidget($protectCheckBox, 1, 0, 1, 3);
    $layout->addWidget($macroNameLabel, 2, 1);
    $layout->addWidget($macroNameLineEdit, 2, 2);
    $layout->addWidget($includeBaseCheckBox, 3, 0, 1, 3);
    $layout->addWidget($baseIncludeLabel, 4, 1);
    $layout->addWidget($baseIncludeLineEdit, 4, 2);
#! [15]
    this->setLayout($layout);
}
#! [15]

#! [16]
sub initializePage {
    my $className = this->field('className')->toString();
    this->{macroNameLineEdit}->setText(uc $className . '_H');

    my $baseClass = this->field('baseClass')->toString();

    this->{includeBaseCheckBox}->setChecked($baseClass);
    this->{includeBaseCheckBox}->setEnabled($baseClass);
    this->{baseIncludeLabel}->setEnabled($baseClass);
    this->{baseIncludeLineEdit}->setEnabled($baseClass);

    if (!$baseClass) {
        this->{baseIncludeLineEdit}->clear();
    } elsif ( $baseClass =~ m/^Q[A-Z].*$/ ) {
        this->{baseIncludeLineEdit}->setText('<' . $baseClass . '>');
    } else {
        this->{baseIncludeLineEdit}->setText('\'' . lc ( $baseClass ) . '.h\'');
    }
}
#! [16]

package OutputFilesPage;

use strict;
use warnings;

use QtCore4;
use QtGui4;
use QtCore4::isa qw( Qt::WizardPage );

sub NEW {
    my ( $class, $parent ) = @_;
    $class->SUPER::NEW( $parent );
    this->setTitle(this->tr('Output Files'));
    this->setSubTitle(this->tr('Specify where you want the wizard to put the generated ' .
                   'skeleton code.'));
    this->setPixmap(Qt::Wizard::LogoPixmap(), Qt::Pixmap('images/logo3.png'));

    my $outputDirLabel = Qt::Label(this->tr('&Output directory:'));
    this->{outputDirLabel} = $outputDirLabel;
    my $outputDirLineEdit = Qt::LineEdit();
    this->{outputDirLineEdit} = $outputDirLineEdit;
    $outputDirLabel->setBuddy($outputDirLineEdit);

    my $headerLabel = Qt::Label(this->tr('&Header file name:'));
    this->{headerLabel} = $headerLabel;
    my $headerLineEdit = Qt::LineEdit();
    this->{headerLineEdit} = $headerLineEdit;
    $headerLabel->setBuddy($headerLineEdit);

    my $implementationLabel = Qt::Label(this->tr('&Implementation file name:'));
    this->{implementationLabel} = $implementationLabel;
    my $implementationLineEdit = Qt::LineEdit();
    this->{implementationLineEdit} = $implementationLineEdit;
    $implementationLabel->setBuddy($implementationLineEdit);

    this->registerField('outputDir*', $outputDirLineEdit);
    this->registerField('header*', $headerLineEdit);
    this->registerField('implementation*', $implementationLineEdit);

    my $layout = Qt::GridLayout();
    $layout->addWidget($outputDirLabel, 0, 0);
    $layout->addWidget($outputDirLineEdit, 0, 1);
    $layout->addWidget($headerLabel, 1, 0);
    $layout->addWidget($headerLineEdit, 1, 1);
    $layout->addWidget($implementationLabel, 2, 0);
    $layout->addWidget($implementationLineEdit, 2, 1);
    this->setLayout($layout);
}

#! [17]
sub initializePage {
    my $className = this->field('className')->toString();
    this->{headerLineEdit}->setText(lc $className . '.h');
    this->{implementationLineEdit}->setText(lc $className . '.cpp');
    this->{outputDirLineEdit}->setText(Qt::Dir::toNativeSeparators(Qt::Dir::tempPath()));
}
#! [17]

package ConclusionPage;

use strict;
use warnings;

use QtCore4;
use QtGui4;
use QtCore4::isa qw( Qt::WizardPage );

sub NEW {
    my ( $class, $parent ) = @_;
    $class->SUPER::NEW( $parent );
    this->setTitle(this->tr('Conclusion'));
    this->setPixmap(Qt::Wizard::WatermarkPixmap(), Qt::Pixmap('images/watermark2.png'));

    my $label = Qt::Label();
    this->{label} = $label;
    $label->setWordWrap(1);

    my $layout = Qt::VBoxLayout();
    $layout->addWidget($label);
    this->setLayout($layout);
}

sub initializePage {
    my $finishText = this->wizard()->buttonText(Qt::Wizard::FinishButton());
    $finishText =~ s/&//g;
    this->{label}->setText(this->tr("Click $finishText to generate the class skeleton."));
}

package ClassWizard;

use strict;
use warnings;

use QtCore4;
use QtGui4;
use QtCore4::isa qw( Qt::Wizard );
use IntroPage;
use ClassInfoPage;
use CodeStylePage;
use OutputFilesPage;
use ConclusionPage;

#! [0] //! [1]
sub NEW {
    my ( $class, $parent ) = @_;
    $class->SUPER::NEW( $parent );

    this->addPage(IntroPage());
    this->addPage(ClassInfoPage());
    this->addPage(CodeStylePage());
    this->addPage(OutputFilesPage());
    this->addPage(ConclusionPage());
#! [0]

    this->setPixmap(Qt::Wizard::BannerPixmap(), Qt::Pixmap('images/banner.png'));
    this->setPixmap(Qt::Wizard::BackgroundPixmap(), Qt::Pixmap('images/background.png'));

    this->setWindowTitle(this->tr('Class Wizard'));
#! [2]
}
#! [1] //! [2]

#! [3]
sub accept {
#! [3] //! [4]
    my $className = this->field('className')->toString();
    my $baseClass = this->field('baseClass')->toString();
    my $macroName = this->field('macroName')->toString();
    my $baseInclude = this->field('baseInclude')->toString();

    my $outputDir = this->field('outputDir')->toString();
    my $header = this->field('header')->toString();
    my $implementation = this->field('implementation')->toString();
#! [4]

    my $block;

    if (this->field('comment')->toBool()) {
        $block .= "/*\n";
        $block .= '    ' . $header . "\n";
        $block .= "*/\n";
        $block .= "\n";
    }
    if (this->field('protect')->toBool()) {
        $block .= '#ifndef ' . $macroName . "\n";
        $block .= '#define ' . $macroName . "\n";
        $block .= "\n";
    }
    if (this->field('includeBase')->toBool()) {
        $block .= '#include ' . $baseInclude . "\n";
        $block .= "\n";
    }

    $block .= 'class ' . $className;
    if ($baseClass) {
        $block .= ' : public ' . $baseClass;
    }
    $block .= "\n";
    $block .= "{\n";

    # qmake ignore Q_OBJECT */

    if (this->field('qobjectMacro')->toBool()) {
        $block .= "    Q_OBJECT\n";
        $block .= "\n";
    }
    $block .= "public:\n";

    if (this->field('qobjectCtor')->toBool()) {
        $block .= '    ' . $className . "(QObject *parent = 0);\n";
    } elsif (this->field('qwidgetCtor')->toBool()) {
        $block .= '    ' . $className . "(QWidget *parent = 0);\n";
    } elsif (this->field('defaultCtor')->toBool()) {
        $block .= '    ' . $className . "();\n";
        if (this->field('copyCtor')->toBool()) {
            $block .= '    ' . $className . '(const ' . $className . " &other);\n";
            $block .= "\n";
            $block .= '    ' . $className . ' &operator=' . '(const ' . $className
                     . " &other);\n";
        }
    }
    $block .= "};\n";

    if (this->field('protect')->toBool()) {
        $block .= "\n";
        $block .= "#endif\n";
    }

    my $headerFile = Qt::File($outputDir . '/' . $header);
    if (!$headerFile->open(Qt::File::WriteOnly() | Qt::File::Text())) {
        Qt::MessageBox::warning(0, Qt::Object::this->tr('Simple Wizard'),
                             Qt::Object::this->tr('Cannot write file ' . 
                             $headerFile->fileName() . ":\n" .
                             $headerFile->errorString()));
        return;
    }
    $headerFile->write(Qt::ByteArray($block));
    $headerFile->close();

    $block = '';

    if (this->field('comment')->toBool()) {
        $block .= "/*\n";
        $block .= '    ' . $implementation . "\n";
        $block .= "*/\n";
        $block .= "\n";
    }
    $block .= '#include "' . $header . "\"\n";
    $block .= "\n";

    if (this->field('qobjectCtor')->toBool()) {
        $block .= $className . '::' . $className . "(QObject *parent)\n";
        $block .= '    : ' . $baseClass . "(parent)\n";
        $block .= "{\n";
        $block .= "}\n";
    } elsif (this->field('qwidgetCtor')->toBool()) {
        $block .= $className . '::' . $className . "(QWidget *parent)\n";
        $block .= '    : ' . $baseClass . "(parent)\n";
        $block .= "{\n";
        $block .= "}\n";
    } elsif (this->field('defaultCtor')->toBool()) {
        $block .= $className . '::' . $className . "()\n";
        $block .= "{\n";
        $block .= "    // missing code\n";
        $block .= "}\n";

        if (this->field('copyCtor')->toBool()) {
            $block .= "\n";
            $block .= $className . '::' . $className . '(const ' . $className
                     . " &other)\n";
            $block .= "{\n";
            $block .= "    *this = other;\n";
            $block .= "}\n";
            $block .= "\n";
            $block .= $className . ' &' . $className . '::operator=(const '
                     . $className . " &other)\n";
            $block .= "{\n";
            if ($baseClass) {
                $block .= '    ' . $baseClass . "::operator=(other);\n";
            }
            $block .= "    // missing code\n";
            $block .= "    return *this;\n";
            $block .= "}\n";
        }
    }

    my $implementationFile = Qt::File($outputDir . '/' . $implementation);
    if (!$implementationFile->open(Qt::File::WriteOnly() | Qt::File::Text())) {
        Qt::MessageBox::warning(0, Qt::Object::this->tr('Simple Wizard'),
                             Qt::Object::this->tr('Cannot write file ' . 
                             $implementationFile->fileName() . ":\n" .
                             $implementationFile->errorString()));
        return;
    }
    $implementationFile->write(Qt::ByteArray($block));
    $implementationFile->close();

#! [5]
    this->SUPER::accept();
#! [5] //! [6]
}
#! [6]

1;
