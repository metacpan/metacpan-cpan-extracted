package Panda::URI;
use parent 'Panda::Export';
use 5.012;
use CPP::panda::lib;

our $VERSION = '1.1.5';

use Panda::Export {
    ALLOW_LEADING_AUTHORITY => 1,
    PARAM_DELIM_SEMICOLON   => 2,
};

require Panda::XSLoader;
Panda::XSLoader::bootstrap();

require overload;
overload->import(
    '""'     => \&to_string,
    'eq'     => sub {
        return ($_[0]->to_string eq $_[1]) unless ref $_[1];
        return $_[0]->equals($_[1]);
    },
    'bool'   => \&to_bool,
    fallback => 1,
);

sub connect_port {
    my $self = shift;
    my $msg = '$uri->connect_port is deprecated, use $uri->port instead.';
    warn "\e[95m$msg\e[0m";
    return $self->port;
}

sub connect_location {
    my $self = shift;
    my $msg = '$uri->connect_location is deprecated, use $uri->location instead.';
    warn "\e[95m$msg\e[0m";
    return $self->location;
}

package # hide from PAUSE
    Panda::URI::_userpass;
our @ISA = 'Panda::URI';

package Panda::URI::http;
our @ISA = 'Panda::URI';

package Panda::URI::https;
our @ISA = 'Panda::URI::http';

package Panda::URI::ftp;
our @ISA = 'Panda::URI::_userpass';

1;
