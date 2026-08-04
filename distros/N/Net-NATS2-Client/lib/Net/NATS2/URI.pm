package Net::NATS2::URI;

use strict;
use warnings;

use URI ();

require URI::_server;
require URI::_userpass;

our @ISA = qw(URI::_server URI::_userpass);

sub new {
    my ($class, $value) = @_;
    return bless URI->new($value), $class;
}

1;
