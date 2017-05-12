package t::Utils;

use warnings;
use strict;

use Test::More;
use Test::Exception;
use Test::Exports;

use Exporter;
our @ISA = "Exporter";
our @EXPORT = (
    @Test::More::EXPORT,
    @Test::Exception::EXPORT,
    @Test::Exports::EXPORT,
    qw/
        is_defer is_plain try_forcing
        *Format
    /,

);

{   package PlainObject;
    sub new { bless $_[1] || [] }
}

{   package StrOverload;
    use overload q/""/ => sub { $_[0][0] };
    sub new { bless [$_[1]] }
}

{   package ScalarOverload;
    use overload q/${}/ => sub { \1 };
    sub new { bless [] }
}

{   package CodeOverload;
    use overload q/&{}/ => sub { sub { 1 } };
    sub new { bless [] }
}

{   package t::Subclass;
    our @ISA = "String::Defer";
}

format Format =
.

sub is_defer {
    my ($obj, $name) = @_;
    my $B = Test::More->builder;
    $B->ok(eval { $obj->isa("String::Defer") }, $name);
}

sub is_plain {
    my ($str, $name) = @_;
    my $B = Test::More->builder;
    $B->ok(!ref $str, $name);
}

sub try_forcing {
    my ($obj, $want, $name) = @_;
    my $B = Test::More->builder;

    for (
        [ forced        => eval { $obj->force } ],
        [ stringified   => eval { "$obj" }      ],
    ) {
        my ($what, $str) = @$_;
        $B->ok(defined $str,    "$name can be $what");
        $B->ok(!ref $str,       "$name $what gives a plain string");
        $B->is_eq($str, $want,  "$name $what gives correct contents");
    }
}

1;

