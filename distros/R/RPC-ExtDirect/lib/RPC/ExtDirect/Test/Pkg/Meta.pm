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
    RPC::ExtDirect::Test::Pkg::Meta;

use strict;
use warnings;

use RPC::ExtDirect;

sub arg0 : ExtDirect(0, metadata => { len => 2, arg => 0 }) {
    my ($class, $meta) = @_;

    return { meta => $meta };
}

sub arg1_last : ExtDirect(1, metadata => { len => 1, arg => 99, }) {
    my ($class, $arg1, $meta) = @_;

    return { arg1 => $arg1, meta => $meta };
}

sub arg1_first : ExtDirect(1, metadata => { len => 2, arg => 0 }) {
    my ($class, $meta, $arg1) = @_;
    
    return { arg1 => $arg1, meta => $meta };
}

sub arg2_last : ExtDirect(2, metadata => { len => 1, arg => 99, }) {
    my ($class, $arg1, $arg2, $meta) = @_;

    return { arg1 => $arg1, arg2 => $arg2, meta => $meta };
}

sub arg2_middle : ExtDirect(2, metadata => { len => 2, arg => 1 }) {
    my ($class, $arg1, $meta, $arg2) = @_;

    return { arg1 => $arg1, arg2 => $arg2, meta => $meta };
}

sub named_default : ExtDirect(params => [], metadata => { len => 1 }) {
    my ($class, %arg) = @_;

    my $meta = delete $arg{metadata};

    return { %arg, meta => $meta };
}

# One line declarations are intentional; Perls below 5.12 have trouble
# parsing attributes spanning multiple lines
sub named_arg : ExtDirect(params => [], metadata => { len => 1, arg => 'foo' }) {
    my ($class, %arg) = @_;

    my $meta = delete $arg{foo};

    return { %arg, meta => $meta };
}

sub named_strict : ExtDirect(params => [], metadata => { params => ['foo'] }) {
    my ($class, %arg) = @_;
    
    my $meta = delete $arg{metadata};

    return { %arg, meta => $meta };
}

sub named_unstrict : ExtDirect(params => [], metadata => { params => [], strict => !1, arg => '_meta' }) {
    my ($class, %arg) = @_;

    my $meta = delete $arg{_meta};

    return { %arg, meta => $meta };
}

sub form_ordered : ExtDirect(formHandler, metadata => { len => 1 }) {
    my ($class, %arg) = @_;
    
    return { %arg };
}

sub form_named : ExtDirect(formHandler, metadata => { arg => '_m', strict => !1, }) {
    my ($class, %arg) = @_;
    
    return { %arg };
}

sub aux_hook {
    my ($class, %arg) = @_;
    
    my $method_arg = $arg{arg};
    
    push @$method_arg, $arg{aux_data};
    
    return 1;
}

sub aux : ExtDirect(0, before => \&aux_hook) {
    my ($class, $aux) = @_;
    
    return { aux => $aux };
}

1;
