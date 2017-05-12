use strict; use warnings; use warnings (FATAL => qw(misc numeric uninitialized)); # use autodie;

use Test::More;
use Test::Fatal;

{ package MyClass;

    use Moose; use MooseX::OmniTrigger;

    has foo => (is => 'rw', isa => 'Str', omnitrigger => sub { die('recursion bomb') if (local $_[0]->_depth->{$_[1]} = ($_[0]->_depth->{$_[1]} || 0) + 1) > 1; $_[0]->foo("$_[2][0]+"); });

    has bar => (is => 'rw', isa => 'Str', omnitrigger => sub { die('recursion bomb') if (local $_[0]->_depth->{$_[1]} = ($_[0]->_depth->{$_[1]} || 0) + 1) > 1; $_[0]->baz($_[0]->baz . '+'); });
    has baz => (is => 'rw', isa => 'Str', omnitrigger => sub { die('recursion bomb') if (local $_[0]->_depth->{$_[1]} = ($_[0]->_depth->{$_[1]} || 0) + 1) > 1; $_[0]->bar($_[0]->bar . '+'); });

    has _depth => (is => 'rw', isa => 'HashRef', default => sub { {} });
}

for my $class (qw(MyClass)) {

    TEST: {

        print("# $class ", $class->meta->is_mutable ? 'MUTABLE' : 'IMMUTABLE', "\n");

        my $obj;

        is(exception { $obj = MyClass->new({foo => 'FOO', bar => 'BAR', baz => 'BAZ'}) }, undef, 'nothing blew up') or last TEST;

        is($obj->foo, 'FOO+', "attr's val was set from inside its own omnitrig via accessor");

        is($obj->bar, 'BAR+', "attr's val was set from inside its own omnitrig via accessor");

        is($obj->baz, 'BAZ+', "attr's val was set from inside its own omnitrig via accessor");

        $class->meta->make_immutable, redo TEST if $class->meta->is_mutable;
    }
}

done_testing;
