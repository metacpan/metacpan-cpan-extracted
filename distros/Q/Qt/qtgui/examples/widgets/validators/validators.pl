#!/usr/bin/perl

package ValidatorWidget;

use strict;
use warnings;

use QtCore4;
use QtGui4;
use Ui_ValidatorsForm;
use ValidatorsResources;
use QtCore4::isa qw( Qt::Widget Ui_ValidatorsForm );
use QtCore4::slots
    updateValidator => [],
    updateDoubleValidator => [],
    _setLocale => ['const QLocale &'];

sub _setLocale {
    my( $l ) = @_;
    this->setLocale($l);
    this->updateValidator();
    this->updateDoubleValidator();
}

sub validator() {
    return this->{validator};
}

sub doubleValidator() {
    return this->{doubleValidator};
}

sub NEW {
    my ( $class, $parent ) = @_;
    $class->SUPER::NEW( $parent );
    my $ui = this->{ui} = $class->setupUi(this);

    my $localeSelector = $ui->{localeSelector};
    this->connect($localeSelector, SIGNAL 'localeSelected(QLocale)', this, SLOT '_setLocale(QLocale)');

    my $minVal = $ui->{minVal};
    my $maxVal = $ui->{maxVal};
    my $editor = $ui->{editor};
    my $ledWidget = $ui->{ledWidget};
    this->connect($minVal, SIGNAL 'editingFinished()', this, SLOT 'updateValidator()');
    this->connect($maxVal, SIGNAL 'editingFinished()', this, SLOT 'updateValidator()');
    this->connect($editor, SIGNAL 'editingFinished()', $ledWidget, SLOT 'flash()');

    my $doubleMaxVal = $ui->{doubleMaxVal};
    my $doubleMinVal = $ui->{doubleMinVal};
    my $doubleDecimals = $ui->{doubleDecimals};
    my $doubleFormat = $ui->{doubleFormat};
    my $doubleEditor = $ui->{doubleEditor};
    my $doubleLedWidget = $ui->{doubleLedWidget};
    this->connect($doubleMaxVal, SIGNAL 'editingFinished()', this, SLOT 'updateDoubleValidator()');
    this->connect($doubleMinVal, SIGNAL 'editingFinished()', this, SLOT 'updateDoubleValidator()');
    this->connect($doubleDecimals, SIGNAL 'valueChanged(int)', this, SLOT 'updateDoubleValidator()');
    this->connect($doubleFormat, SIGNAL 'activated(int)', this, SLOT 'updateDoubleValidator()');
    this->connect($doubleEditor, SIGNAL 'editingFinished()', $doubleLedWidget, SLOT 'flash()');

    this->{validator} = 0;
    this->{doubleValidator} = 0;
    this->updateValidator();
    this->updateDoubleValidator();
}

sub updateValidator {
    my $ui = this->{ui};
    my $minVal = $ui->{minVal};
    my $maxVal = $ui->{maxVal};
    my $editor = $ui->{editor};
    my $v = Qt::IntValidator($minVal->value(), $maxVal->value(), this);
    $v->setLocale(this->locale());
    $editor->setValidator($v);
    this->{validator} = $v;
    my $validator = this->{validator};

    my $s = $editor->text();
    my $i = 0;
    if ($validator->validate($s, $i) == Qt::Validator::Invalid()) {
        $editor->clear();
    } else {
        $editor->setText($s);
    }
}

sub updateDoubleValidator {
    my $ui = this->{ui};
    my $doubleMinVal = $ui->{doubleMinVal};
    my $doubleMaxVal = $ui->{doubleMaxVal};
    my $doubleDecimals = $ui->{doubleDecimals};
    my $doubleFormat = $ui->{doubleFormat};
    my $v = Qt::DoubleValidator($doubleMinVal->value(), $doubleMaxVal->value(),
                                $doubleDecimals->value(), this);
    $v->setNotation($doubleFormat->currentIndex());
    $v->setLocale(this->locale());
    my $doubleEditor = $ui->{doubleEditor};
    $doubleEditor->setValidator($v);
    this->{doubleValidator} = $v;
    my $doubleValidator = this->{doubleValidator};

    my $s = $doubleEditor->text();
    my $i = 0;
    if ($doubleValidator->validate($s, $i) == Qt::Validator::Invalid()) {
        $doubleEditor->clear();
    } else {
        $doubleEditor->setText($s);
    }
}

1;

package main;

use strict;
use warnings;

use QtCore4;
use QtGui4;
use ValidatorWidget;

sub main {
    my $app = Qt::Application( \@ARGV );

    my $w = ValidatorWidget();
    $w->show();

    return $app->exec();
}

exit main();
