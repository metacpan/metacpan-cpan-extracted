#!/usr/bin/perl

package HelpContextSensitiveHelpTest;

use strict;
use warnings;

use QtCore4;
use QtGui4;
use QtTest4 qw( QVERIFY );
use WateringConfigDialog;
use QtCore4::isa qw(Qt::Object);
use QtCore4::slots
    private => 1,
    testFocusSwitch => [],
    initTestCase => [];
use Test::More;

sub NEW {
    my ($class, $parent) = @_;
    $class->SUPER::NEW();
}

sub testFocusSwitch {
    my $dialog = this->{dialog};
    my $filterCheckBox = $dialog->{m_ui}->filterCheckBox();
    
    my @widgets = (
        $dialog->{m_ui}->plantComboBox(),
        $dialog->{m_ui}->temperatureCheckBox(),
        $dialog->{m_ui}->temperatureSpinBox(),
        $dialog->{m_ui}->rainCheckBox(),
        $dialog->{m_ui}->rainSpinBox(),
        $dialog->{m_ui}->startTimeEdit(),
        $dialog->{m_ui}->amountSpinBox(),
        $dialog->{m_ui}->sourceComboBox(),
        $dialog->{m_ui}->filterCheckBox(),
    );

    my %msgHash = (
        $widgets[0] => 'Different kind of plants need different amounts of water. Here\'s a short overview over the most common grown plants and their avarage need of water: 

Kind
Amount
Squash
2000
Bean
1500
Carrot
1200
Strawberry
1300
Raspberry
1000
Blueberry
1100


Warning: Watering them too much or too little will cause irreversible damage! ',
        $widgets[1] => 'Depending on the temperature, the plants need more or less water. The higher the temperature the higher the need for water. If the temperature does not reach a certain level, maybe no automatic watering should be done at all.
Before setting this parameter for good, you should also take the amount of rain into account. ',
        $widgets[2] => 'Depending on the temperature, the plants need more or less water. The higher the temperature the higher the need for water. If the temperature does not reach a certain level, maybe no automatic watering should be done at all.
Before setting this parameter for good, you should also take the amount of rain into account. ',
        $widgets[3] => 'Depending on the rain fall, the automated watering system should not be switched on at all. Also, the temperature should be considered. ',
        $widgets[4] => 'Depending on the rain fall, the automated watering system should not be switched on at all. Also, the temperature should be considered. ',
        $widgets[5] => 'Starting the watering too early may be ineffective since most water will evaporate. ',
        $widgets[6] => 'Depending on the plant, temperature and rain fall the amount needs to be larger or smaller. On a really hot day without rain, the suggested amount can be increased by about 10%. ',
        $widgets[7] => 'The current pipe system connects to four different sources. Be aware that only a limited amount of water can be taken from some sources. 

Source
Amount
Fountain
4000
River
6000
Lake
10000
Public Water System
unlimited
',
        $widgets[8] => 'Depending on the source of water, it needs to be filtered or not. Filtering is strongly recommened for the river and lake. ',
    );

    foreach my $widget ( @widgets ) {
        my $msg = $msgHash{$widget};
        Qt::Test::mouseClick( $widget, Qt::LeftButton() );
        is( $dialog->{m_ui}->helpBrowser->toPlainText(), $msg, 'Help message update ' . $widget->objectName() );
        Qt::Test::qWait(10);
    }
}

sub initTestCase {
    my $dialog = WateringConfigDialog();
    $dialog->show();
    Qt::Test::qWaitForWindowShown( $dialog );
    this->{dialog} = $dialog;
    pass( 'Window shown' );
}

package main;

use strict;
use warnings;

use QtCore4;
use QtGui4;
use QtTest4 qw(QTEST_MAIN);
use HelpContextSensitiveHelpTest;
use Test::More tests => 10;

exit QTEST_MAIN('HelpContextSensitiveHelpTest');
