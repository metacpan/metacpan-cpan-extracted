#
# WARNING WARNING WARNING
#
# DO NOT CHANGE ANYTHING IN THIS MODULE. OTHERWISE, A LOT OF API 
# AND OTHER TESTS MAY BREAK.
#
# This module is here to test certain behaviors. If you need
# to test something else, add another test module.
# It's that simple.
#

# This does not need to be indexed by PAUSE
package
    RPC::ExtDirect::Test::Pkg::Env;

use strict;
use warnings;
no  warnings 'uninitialized';

use RPC::ExtDirect class => 'Env';

sub http_list : ExtDirect(0, env_arg => 1) {
    my ($class, $env) = @_;

    my @list = sort map lc, $env->http();

    return [ @list ];
}

sub http_header : ExtDirect(1, env_arg => 1) {
    my ($class, $header, $env) = @_;

    return $env->http($header);
}

sub param_list : ExtDirect(0, env_arg => 1) {
    my ($class, $env) = @_;

    my @list = sort map lc, $env->param();

    return [ @list ];
}

sub param_get : ExtDirect(1, env_arg => 1) {
    my ($class, $name, $env) = @_;

    return $env->param($name);
}

sub cookie_list : ExtDirect(0, env_arg => 1) {
    my ($class, $env) = @_;

    my @cookies = sort map lc, $env->cookie();

    return [ @cookies ];
}

sub cookie_get : ExtDirect(1, env_arg => 1) {
    my ($class, $name, $env) = @_;

    return $env->cookie($name);
}

1;

