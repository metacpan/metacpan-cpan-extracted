package ChatAdaptor;

use strict;
use warnings;
use QtCore4;
use QtGui4;
use QtDBus4;
use QtCore4::isa qw( Qt::DBusAbstractAdaptor );
use QtCore4::classinfo
    'D-Bus Interface' => 'com.trolltech.chat',
    'D-Bus Introspection' => '' .
"  <interface name=\'com.trolltech.chat\' >\n" .
"    <signal name=\'message\' >\n" .
"      <arg direction=\'out\' type=\'s\' name=\'nickname\' />\n" .
"      <arg direction=\'out\' type=\'s\' name=\'text\' />\n" .
"    </signal>\n" .
"    <signal name=\'action\' >\n" .
"      <arg direction=\'out\' type=\'s\' name=\'nickname\' />\n" .
"      <arg direction=\'out\' type=\'s\' name=\'text\' />\n" .
"    </signal>\n" .
"  </interface>\n" .
        '';
use QtCore4::signals
    action => ['const QString &', 'const QString &'],
    message => ['const QString &', 'const QString &'];

sub NEW
{
    my ($class, $parent) = @_;
    $class->SUPER::NEW($parent);
    this->setAutoRelaySignals(1);
}

1;
