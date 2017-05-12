#!perl -w
use strict;
use Test::More;
use Project::Libs;
use Sub::Inspector;
use C;
use Path::Class;
use Test::Exception;
use Data::Dumper;

subtest 'exception' => sub {
    throws_ok(
        sub { Sub::Inspector->new(undef) },
        qr(isn't a subroutine reference)
    );
    for my $method (qw(file line name proto prototype attrs attributes)) {
        throws_ok(
            sub { Sub::Inspector->$method(undef) },
            qr(isn't a subroutine reference)
        );
    }
};

subtest 'file, line, name' => sub {
    _test(C->can('parent_method'), (
        ['file', file(__FILE__)->dir->subdir('lib')->file('ParentClass.pm')->absolute],
        ['line', 5],
        ['name', 'parent_method'],
    ));
};

subtest 'proto' => sub {
    _test(C->can('try'), (
        ['proto',     '&;@'],
        ['prototype', '&;@'],
    ));
    _test(C->can('plain'), (
        ['proto',     undef],
        ['prototype', undef],
    ));
};

subtest 'attr' => sub {
    _test_array(C->can('has_attr'), (
        ['attrs',      [qw(lvalue)]],
        ['attributes', [qw(lvalue)]],
    ));
    _test_array(C->can('has_multi_attrs'), (
        ['attrs',      [qw(lvalue method)]],
        ['attributes', [qw(lvalue method)]],
    ));
    _test_array(C->can('plain'), (
        ['attrs',      []],
        ['attributes', []],
    ));
};

sub _test {
    my ($code, @data) = @_;
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    my $ins = Sub::Inspector->new($code);
    for (@data) {
        my ($method, $expected) = @{$_};
        is($ins->$method,                  $expected);
        is(Sub::Inspector->$method($code), $expected);
    }
}

sub _test_array {
    my ($code, @data) = @_;
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    local $Data::Dumper::Indent = 1;
    local $Data::Dumper::Terse  = 1;
    my $is_deeply2 = sub { is(Dumper($_[0]), Dumper($_[1])) };
    my $ins = Sub::Inspector->new($code);
    for (@data) {
        my ($method, $expected) = @{$_};
        is_deeply([$ins->$method],                  $expected);
        is_deeply([Sub::Inspector->$method($code)], $expected);
    }
}

done_testing;
