package test::class::cookies;

use strict;

use RPC::ExtDirect  Action => 'test',
                    before => \&before_hook,
                    ;
use RPC::ExtDirect::Event;
use Test::More;

our %cookies;

sub before_hook {
    my ($class, %params) = @_;

    my $env = $params{env};

    %cookies = map { $_ => $env->cookie($_) } $env->cookie;

    return 1;
}

sub ordered : ExtDirect(0) {
    my $ret  = { %cookies };
    %cookies = ();

    return $ret;
}

sub form : ExtDirect(formHandler) {
    my $ret  = { %cookies };
    %cookies = ();

    return $ret;
}

sub poll : ExtDirect(pollHandler) {
    return RPC::ExtDirect::Event->new(
        'cookies',
        { %cookies },
    );
}

1;

