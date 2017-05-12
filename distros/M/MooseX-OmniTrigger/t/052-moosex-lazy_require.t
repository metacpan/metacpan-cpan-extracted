use strict; use warnings; use warnings (FATAL => qw(misc numeric uninitialized)); # use autodie;

use Test::More;
use Test::Fatal;

BEGIN {

    eval("use MooseX::LazyRequire");

    plan skip_all => "MooseX::LazyRequire isn't installed or wouldn't load" if $@;
}

{ package MyClass; use Moose; use MooseX::LazyRequire; use MooseX::OmniTrigger;

    has foo => (lazy_required => 1, is => 'rw', isa => 'Str', omnitrigger => \&_capture_changes);

    has changes => (is => 'ro', isa => 'ArrayRef', default => sub { [] });

    sub _capture_changes {

        my ($self, $attr_name, $new, $old) = (shift, @_);

        push(@{$self->changes}, sprintf('%s:%s=>%s',

            $attr_name,

            @$old ? defined($old->[0]) ? $old->[0] : 'UNDEF' : 'NOVAL',
            @$new ? defined($new->[0]) ? $new->[0] : 'UNDEF' : 'NOVAL',
        ));
    }
}

for my $class (qw(MyClass)) {

    TEST: {

        print("# $class ", $class->meta->is_mutable ? 'MUTABLE' : 'IMMUTABLE', "\n");

        my $obj;

        is(exception { $obj = MyClass->new }, undef, 'nothing blew up -- LazyRequire must have worked') or last TEST;

        $obj->foo('POW');

        is("@{$obj->changes}", 'foo:NOVAL=>POW', 'omnitrigger fired');

        $class->meta->make_immutable, redo TEST if $class->meta->is_mutable;
    }
}

done_testing;
