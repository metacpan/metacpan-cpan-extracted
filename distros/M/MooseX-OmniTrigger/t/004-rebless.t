use strict; use warnings; use warnings (FATAL => qw(misc numeric uninitialized)); # use autodie;

use Test::Fatal;
use Test::More;

{ package MyClassA; use Moose; use MooseX::OmniTrigger;

    has foo => (is => 'rw', isa => 'Str', omnitrigger => sub { my $self = shift; $self->_capture_changes('foobar', @_); $self->bar('BAR'); }, omnitrig_sort_key => 1);
    has bar => (is => 'rw', isa => 'Str', omnitrigger => sub { my $self = shift; $self->_capture_changes('foobar', @_);                    }, omnitrig_sort_key => 2);

    has moo => (is => 'rw', isa => 'Str', default => 'MOO', clearer => '_clear_moo', omnitrigger => sub { my $self = shift; $self->_capture_changes('moogoo', @_); $self->goo('GOO'); });
    has goo => (is => 'rw', isa => 'Str',                   clearer => '_clear_goo', omnitrigger => sub { my $self = shift; $self->_capture_changes('moogoo', @_);                    });

    has pee => (is => 'rw', isa => 'Str', builder => '_build_pee', clearer => '_clear_pee', omnitrigger => sub { my $self = shift; $self->_capture_changes('peepoo', @_); $self->poo('POO'); });
    has poo => (is => 'rw', isa => 'Str',                          clearer => '_clear_poo', omnitrigger => sub { my $self = shift; $self->_capture_changes('peepoo', @_);                    });

    has biz => (is => 'rw', isa => 'Str', omnitrigger => sub { shift->_capture_changes('biz', @_) });
    has buz => (is => 'rw', isa => 'Str', omnitrigger => sub { shift->_capture_changes('buz', @_) });

    has ziz => (is => 'rw', isa => 'ArrayRef', omnitrigger => sub { ::is(ref($_[3][0]), 'ARRAY', 'old val is arrayref, in spite of auto_deref') if @{$_[3]} }, auto_deref => 1);

    has changes => (is => 'ro', isa => 'HashRef', default => sub { {} });

    sub _capture_changes {

        my ($self, $attr_group, $attr_name, $new, $old) = (shift, @_);

        push(@{$self->changes->{$attr_group}}, sprintf('%s=>%s',

            @$old ? $old->[0] : 'NOVAL',
            @$new ? $new->[0] : 'NOVAL',
        ));
    }

    sub _build_pee { 'PEE' }
}

{ package MyClassA::Extended; use Moose; extends 'MyClassA'; }

for my $class (qw(MyClassA)) {

    TEST: {

        print("# $class ", $class->meta->is_mutable ? 'MUTABLE' : 'IMMUTABLE', "\n");

        my $obj;

        is(exception { $obj = MyClassA->new({biz => 'TRANSFER_ME', buz => 'INITVAL', ziz => ['OLD']}) }, undef, 'nothing blew up') or last TEST;

        $obj->$_ for qw(_clear_moo _clear_goo _clear_pee _clear_poo);

        %{$obj->changes} = ();

        MyClassA::Extended->meta->rebless_instance($obj, foo => 'FOO', buz => 'BUZ', ziz => ['NEW']);

        is("@{$obj->changes->{foobar} || []}", 'NOVAL=>FOO NOVAL=>BAR', 'foo fired for initval during rebless, setting bar; bar fired');
        is("@{$obj->changes->{moogoo} || []}", 'NOVAL=>MOO NOVAL=>GOO', 'moo fired for default during rebless, setting goo; goo fired');
        is("@{$obj->changes->{peepoo} || []}", 'NOVAL=>PEE NOVAL=>POO', 'pee fired for builder during rebless, setting poo; poo fired');

        is(MooseX::OmniTrigger::State->singleton->slot($obj, 'biz')->{oldval_at_reset}[0], 'TRANSFER_ME', "biz's oldval at reset was 'TRANSFER_ME'");

        is($obj->changes->{biz}, undef, 'biz was NOT fired during rebless for val transfer');

        is("@{$obj->changes->{buz} || []}", 'INITVAL=>BUZ', 'buz was fired during rebless for initval');

        $obj = MyClassA->new({bar => 'TRANSFER_ME'});

        %{$obj->changes} = ();

        MyClassA::Extended->meta->rebless_instance($obj, foo => 'FOO');

        is(MooseX::OmniTrigger::State->singleton->slot($obj, 'bar')->{oldval_at_reset}[0], 'TRANSFER_ME', "bar's oldval at reset was 'TRANSFER_ME'");

        is("@{$obj->changes->{foobar} || []}", 'NOVAL=>FOO TRANSFER_ME=>BAR', 'foo triggered for initval during rebless, setting bar; bar triggered');

        $class->meta->make_immutable, redo TEST if $class->meta->is_mutable;
    }
}

done_testing;
