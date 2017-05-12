use strict; use warnings; use warnings (FATAL => qw(misc numeric uninitialized)); # use autodie;

use Test::Fatal;
use Test::More;

{ package MyClassA; use Moose; use MooseX::OmniTrigger;

    has foo => (is => 'rw', isa => 'Str', omnitrigger => \&_capture_changes);

    has changes => (is => 'ro', isa => 'HashRef', default => sub { {} });

    sub _capture_changes {

        my ($self, $attr_name, $new, $old) = (shift, @_);

        push(@{$self->changes->{$attr_name}}, sprintf('%s=>%s',

            @$old ? defined($old->[0]) ? $old->[0] : 'UNDEF' : 'NOVAL',
            @$new ? defined($new->[0]) ? $new->[0] : 'UNDEF' : 'NOVAL',
        ));
    }
}

{ package MyClassA::Extended; use Moose; extends 'MyClassA'; }

for my $class (qw(MyClassA)) {

    TEST: {

        print("# $class ", $class->meta->is_mutable ? 'MUTABLE' : 'IMMUTABLE', "\n");

        my $obj;

        is(exception { $obj = $class->new }, undef, 'nothing blew up') or last TEST;

        MyClassA::Extended->meta->rebless_instance($obj, foo => 'FRACK');

        my $clone = $obj->meta->clone_object($obj, foo => 'FRELL');

        is("@{$obj->changes->{foo} || []}", 'NOVAL=>FRACK FRACK=>FRELL', 'omnitrig fired correctly for cloning following reblessing');

        $class->meta->make_immutable, redo TEST if $class->meta->is_mutable;
    }
}

done_testing;
