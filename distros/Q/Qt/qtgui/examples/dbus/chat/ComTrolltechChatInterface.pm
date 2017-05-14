package ComTrolltechChatInterface;

use strict;
use warnings;
use QtCore4;
use QtGui4;
use QtCore4::isa qw( Qt::DBusAbstractInterface );

sub staticInterfaceName {
    return 'com.trolltech.chat';
}

use QtCore4::signals
    action => ['const QString &', 'const QString &' ],
    message => ['const QString &', 'const QString &' ];

sub NEW
{
    my ($class, $service, $path, $connection, $parent) = @_;
    $class->SUPER::NEW($service, $path, staticInterfaceName(), $connection, $parent);
}

1;
