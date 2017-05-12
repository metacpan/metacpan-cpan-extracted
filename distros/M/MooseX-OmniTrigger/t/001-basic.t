use strict; use warnings; use warnings (FATAL => qw(misc numeric uninitialized)); # use autodie;

use Test::Fatal;
use Test::More;

use Moose::Util::TypeConstraints;

subtype 'Exciting',
    as 'Str',
        where { /!$/ };

coerce 'Exciting',
    from 'Str',
        via { "$_!" };

no Moose::Util::TypeConstraints;

my $stuff = <<'END';
    has poo => (is => 'rw', isa => 'Str', omnitrigger => sub {

        my ($self_aka_instance, $attr_name, $new_val, $old_val) = (shift, @_);

        ::isa_ok($self_aka_instance, $class, '1st arg to omnitrigger');

        ::is($attr_name, 'poo', '2nd arg to omnitrigger is the attribute name');

        ::isa_ok($new_val, 'ARRAY', '3rd arg to omnitrigger');
        ::isa_ok($old_val, 'ARRAY', '4th arg to omnitrigger');
    });

    has foo => (is => 'rw', isa => 'Exciting', coerce => 1,                          clearer => '_clear_foo', omnitrigger => \&_capture_changes);
    has bar => (is => 'rw', isa => 'Exciting', coerce => 1, default => 'DEFAULT'   ,                          omnitrigger => \&_capture_changes);
    has baz => (is => 'rw', isa => 'Exciting', coerce => 1, builder => '_build_bar',                          omnitrigger => \&_capture_changes);

    has blo => (is => 'ro', isa => 'Exciting', coerce => 1, default => 'DEFAULT', omnitrigger => \&_capture_changes);

    has goo => (is => 'rw', isa => 'Exciting', coerce => 1, default => 'DEFAULT'   , lazy => 1, clearer => '_clear_goo', omnitrigger => \&_capture_changes);
    has moo => (is => 'rw', isa => 'Exciting', coerce => 1, builder => '_build_bar', lazy => 1, clearer => '_clear_moo', omnitrigger => \&_capture_changes);

    has changes => (is => 'ro', isa => 'HashRef', default => sub { {} });

    has biz => (is => 'rw', isa => 'ArrayRef', weak_ref => 1,                                              omnitrigger => \&_capture_weaklings);
    has buz => (is => 'rw', isa => 'ArrayRef', weak_ref => 1, default => sub { $arrayref_buz }, lazy => 1, omnitrigger => \&_capture_weaklings);
    has bez => (is => 'rw', isa => 'ArrayRef', weak_ref => 1, default => sub { $arrayref_bez }, lazy => 1, omnitrigger => \&_capture_weaklings);

    has weaklings => (is => 'ro', isa => 'HashRef', default => sub { {} });

    has ziz => (is => 'rw', isa => 'Exciting', coerce => 1,

        initializer => sub {

            my ($self, $value, $set, $attr) = @_;

            $set->("$value-INITIALIZER");
        },

        omnitrigger => sub {

            my ($self_aka_instance, $attr_name, $new_val, $old_val) = (shift, @_);

            $self_aka_instance->meta->get_attribute('ziz')->set_raw_value($self_aka_instance, "$new_val->[0]-OMNITRIG");
        },
    );

    sub _capture_changes {

        my ($self, $attr_name, $new, $old) = (shift, @_);

        push(@{$self->changes->{$attr_name}}, sprintf('%s=>%s',

            @$old ? defined($old->[0]) ? $old->[0] : 'UNDEF' : 'NOVAL',
            @$new ? defined($new->[0]) ? $new->[0] : 'UNDEF' : 'NOVAL',
        ));
    }

    sub _capture_weaklings { $_[0]->weaklings->{$_[1]} = Scalar::Util::isweak($_[0]{$_[1]}) }

    sub _build_bar { 'BUILDER' }
END

my $class;

my $arrayref_buz;
my $arrayref_biz;
my $arrayref_bez;

eval(qq[
    { package MyRoleA; use Moose::Role;                 use MooseX::OmniTrigger; $stuff; }
    { package MyRoleB; use Moose::Role; with 'MyRoleA';                                  }
    { package MyRoleC; use Moose::Role; with 'MyRoleB';                                  }
    { package MyRoleZ; use Moose::Role;                                                  }

    { package MyClassA; use Moose; use MooseX::OmniTrigger; $stuff; }

    { package MyClassB; use Moose; with 'MyRoleA'; }
    { package MyClassC; use Moose; with 'MyRoleC'; }

    { package MyClassD; use Moose; with 'MyRoleA'; with 'MyRoleZ'; }
    { package MyClassE; use Moose; with 'MyRoleZ'; with 'MyRoleA'; }

    { package MyClassF; use Moose; with qw(MyRoleA MyRoleZ); }
]);

{
    my $x = $@;

    is(exception { die($x) if $x }, undef, 'nothing blew up') or done_testing and exit;
}

for (qw(MyClassA MyClassB MyClassC MyClassD MyClassE MyClassF)) {

    $class = $_;

    TEST: {

        print("# $class ", $class->meta->is_mutable ? 'MUTABLE' : 'IMMUTABLE', "\n");

        $arrayref_buz = [];
        $arrayref_biz = [];
        $arrayref_bez = [];

        my $obj;

        is(exception { $obj = $class->new({foo => 'INITVAL', biz => $arrayref_biz, ziz => 'INITVAL'}) }, undef, 'nothing blew up') or last TEST;

        $obj->poo('Piss off, World.');

        is("@{$obj->changes->{foo} || []}", 'NOVAL=>INITVAL!',          'initval causes omnitrigger to fire; val is coerced'); # set_initial_value (<= initialize_instance_slot <= _construct_instance <= new_object)
        is("@{$obj->changes->{bar} || []}", 'NOVAL=>DEFAULT!', 'non-lazy default causes omnitrigger to fire; val is coerced'); # set_initial_value (<= initialize_instance_slot <= _construct_instance <= new_object)
        is("@{$obj->changes->{baz} || []}", 'NOVAL=>BUILDER!', 'non-lazy builder causes omnitrigger to fire; val is coerced'); # set_initial_value (<= initialize_instance_slot <= _construct_instance <= new_object)

        is($obj->changes->{goo}, undef, 'lazy default does not cause omnitrigger to fire during construction');
        is($obj->changes->{moo}, undef, 'lazy builder does not cause omnitrigger to fire during construction');

        %{$obj->changes} = ();

        my $attr_foo = $obj->meta->get_attribute('foo');

        $attr_foo->set_raw_value($obj, 'Hmph.');

        is($obj->changes->{foo}, undef, "set_raw_value doesn't fire omnitrigger");

        $attr_foo->set_value($obj, 'Yay');

        is("@{$obj->changes->{foo} || []}", 'Hmph.=>Yay!', 'set_value fires omnitrigger; raw oldval remains uncoerced');

        %{$obj->changes} = ();

        $obj->$_('Hooray') for $attr_foo->get_write_method_ref->body;

        is("@{$obj->changes->{foo} || []}", 'Yay!=>Hooray!', 'writer from get_write_method_ref (where a writer existed) fires omnitrigger');

        %{$obj->changes} = ();

        $attr_foo->clear_value($obj);

        is("@{$obj->changes->{foo} || []}", 'Hooray!=>NOVAL', 'clear_value fires omnitrigger');

        %{$obj->changes} = ();

        $obj->_clear_foo;

        is("@{$obj->changes->{foo} || []}", 'NOVAL=>NOVAL', 'clearer fires omnitrigger');

        $obj->$_('Booyah') for $obj->meta->get_attribute('blo')->get_write_method_ref->body;

        is("@{$obj->changes->{blo} || []}", 'DEFAULT!=>Booyah!', "writer from get_write_method_ref (where a writer didn't exist) fires omnitrigger");

        $obj->meta->get_attribute('goo')->get_value($obj);

        is("@{$obj->changes->{goo} || []}", 'NOVAL=>DEFAULT!', 'lazy default fires omnitrigger on get_value; val is coerced'); # set_initial_value (<= get_value)

        $obj->meta->get_attribute('moo')->get_value($obj);

        is("@{$obj->changes->{moo} || []}", 'NOVAL=>BUILDER!', 'lazy builder fires omnitrigger on get_value; val is coerced'); # set_initial_value (<= get_value)

        $obj->_clear_goo;
        $obj->_clear_moo;

        %{$obj->changes} = ();

        $obj->goo;

        is("@{$obj->changes->{goo} || []}", 'NOVAL=>DEFAULT!', 'lazy default fires omnitrigger on access; val is coerced'); # _inline_instance_set (<= _inline_init_slot <= _inline_init_from_default <= _inline_check_lazy <= _inline_get_value)

        $obj->moo;

        is("@{$obj->changes->{moo} || []}", 'NOVAL=>BUILDER!', 'lazy builder fires omnitrigger on access; val is coerced'); # _inline_instance_set (<= _inline_init_slot <= _inline_init_from_default <= _inline_check_lazy <= _inline_get_value)

        cmp_ok($obj->weaklings->{biz}, '==', 1, 'val is weak at omnitrigger firing where _fire_omnitrig wraps set_initial_value (<= initialize_instance_slot <= _construct_instance <= new_object)');

        $obj->meta->get_attribute('buz')->get_value($obj);

        cmp_ok($obj->weaklings->{buz}, '==', 1, 'val is weak at omnitrigger firing where _fire_omnitrig wraps set_initial_value (<= get_value)');

        $obj->bez;

        cmp_ok($obj->weaklings->{bez}, '==', 1, 'val is weak at omnitrigger firing where _fire_omnitrig wraps _inline_instance_set (<= _inline_init_slot <= _inline_init_from_default <= _inline_check_lazy <= _inline_get_value)');

        TODO: {

            local $TODO = "swell if this works, but really don't care";

            is($obj->ziz, 'INITVAL!-INITIALIZER!-OMNITRIG', 'initializer-ization seems to happen at the right time (consistent with Moose)');
        }

        $class->meta->make_immutable, redo TEST if $class->meta->is_mutable;
    }
}

done_testing;
