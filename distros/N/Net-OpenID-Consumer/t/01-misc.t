#!/usr/bin/perl

use strict;
use Test::More tests => 2;
use Net::OpenID::Consumer;

my $csr = Net::OpenID::Consumer->new;
ok($csr, "instantiated");
ok($csr->args(CGI::Subclass->new), "can set CGI subclass as args");

package CGI::Subclass;
use base 'CGI';

package CGI;
no warnings 'redefine';

sub new {
    my ($class) = @_;
    return bless {}, $class;
}

1;
