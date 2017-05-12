use strict; use warnings; use warnings (FATAL => qw(misc numeric uninitialized)); # use autodie;

use Test::Fatal;
use Test::More;

my @CHANGES;

{ package MyClass; use Moose; use MooseX::OmniTrigger;

    has foo => (is => 'rw', isa => 'Str', omnitrigger => sub { shift->_capture_changes(@_); MyClass->new({bar => 'Then me.'}); });
    has bar => (is => 'rw', isa => 'Str', omnitrigger => sub { shift->_capture_changes(@_);                                    });

    sub _capture_changes {

        my ($self, $attr_name, $new, $old) = (shift, @_);

        push(@CHANGES, sprintf('%s:%s=>%s',

            $attr_name,

            @$old ? defined($old->[0]) ? $old->[0] : 'UNDEF' : 'NOVAL',
            @$new ? defined($new->[0]) ? $new->[0] : 'UNDEF' : 'NOVAL',
        ));
    }
}

for my $class (qw(MyClass)) {

    TEST: {

        print("# $class ", $class->meta->is_mutable ? 'MUTABLE' : 'IMMUTABLE', "\n");

        @CHANGES = ();

        my $obj;

        is(exception { $obj = $class->new(foo => 'Me first.') }, undef, 'nothing blew up') or last TEST;

        is("@CHANGES", 'foo:NOVAL=>Me first. bar:NOVAL=>Then me.', 'omnitrigger fires correctly for object constructed inside omnitrigger callback called during construction of object of same class');

        $class->meta->make_immutable, redo TEST if $class->meta->is_mutable;
    }
}

done_testing;
