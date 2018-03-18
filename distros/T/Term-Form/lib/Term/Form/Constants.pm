package # hide from PAUSE
Term::Form::Constants;

use warnings;
use strict;
use 5.008003;

our $VERSION = '0.315';

use Exporter qw( import );

our @EXPORT_OK = qw(
        NEXT_get_key
        CONTROL_A CONTROL_B CONTROL_D CONTROL_E CONTROL_F CONTROL_H CONTROL_K CONTROL_U KEY_BTAB KEY_TAB
        KEY_ENTER KEY_ESC KEY_BSPACE
        VK_CODE_END VK_CODE_HOME VK_CODE_LEFT VK_CODE_UP VK_CODE_RIGHT VK_CODE_DOWN VK_CODE_DELETE VK_CODE_PAGE_UP VK_CODE_PAGE_DOWN
        VK_END      VK_HOME      VK_LEFT      VK_UP      VK_RIGHT      VK_DOWN      VK_DELETE      VK_PAGE_UP      VK_PAGE_DOWN
);

our %EXPORT_TAGS = (
    rl => [ qw(
        NEXT_get_key
        CONTROL_A CONTROL_B CONTROL_D CONTROL_E CONTROL_F CONTROL_H CONTROL_K CONTROL_U KEY_BTAB KEY_TAB
        KEY_ENTER KEY_ESC KEY_BSPACE
        VK_END VK_HOME VK_LEFT VK_UP VK_RIGHT VK_DOWN VK_DELETE VK_PAGE_UP VK_PAGE_DOWN
    ) ],
    linux  => [ qw(
        NEXT_get_key
        KEY_BTAB KEY_ESC
        VK_END VK_HOME VK_LEFT VK_UP VK_RIGHT VK_DOWN VK_DELETE VK_PAGE_UP VK_PAGE_DOWN
    ) ],
    win32  => [ qw(
        NEXT_get_key
        VK_CODE_END VK_CODE_HOME VK_CODE_LEFT VK_CODE_UP VK_CODE_RIGHT VK_CODE_DOWN VK_CODE_DELETE VK_CODE_PAGE_UP VK_CODE_PAGE_DOWN
        VK_END      VK_HOME      VK_LEFT      VK_UP      VK_RIGHT      VK_DOWN      VK_DELETE      VK_PAGE_UP      VK_PAGE_DOWN
    ) ]
);


use constant {
    NEXT_get_key => -1,

    CONTROL_A  => 0x01,
    CONTROL_B  => 0x02,
    CONTROL_D  => 0x04,
    CONTROL_E  => 0x05,
    CONTROL_F  => 0x06,
    CONTROL_H  => 0x08,
    KEY_BTAB   => 0x08,
    KEY_TAB    => 0x09,
    CONTROL_K  => 0x0b,
    KEY_ENTER  => 0x0d,
    CONTROL_U  => 0x15,
    KEY_ESC    => 0x1b,
    KEY_BSPACE => 0x7f,

    VK_PAGE_UP   => 333,
    VK_PAGE_DOWN => 334,
    VK_END       => 335,
    VK_HOME      => 336,
    VK_LEFT      => 337,
    VK_UP        => 338,
    VK_RIGHT     => 339,
    VK_DOWN      => 340,
    VK_DELETE    => 346,

    VK_CODE_PAGE_UP   => 33,
    VK_CODE_PAGE_DOWN => 34,
    VK_CODE_END       => 35,
    VK_CODE_HOME      => 36,
    VK_CODE_LEFT      => 37,
    VK_CODE_UP        => 38,
    VK_CODE_RIGHT     => 39,
    VK_CODE_DOWN      => 40,
    VK_CODE_DELETE    => 46,
};



1;

__END__
