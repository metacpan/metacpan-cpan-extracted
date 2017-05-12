use strict; use warnings; use warnings (FATAL => qw(misc numeric uninitialized)); # use autodie;

use Test::Fatal;
use Test::More;

my $stuff = <<'END';
    has foo_array => (is => 'rw', traits => ['Array'], default => sub { [] }, omnitrigger => \&_capture_changes, handles => {

        foo_array_push    => 'push'   ,
        foo_array_pop     => 'pop'    ,
        foo_array_unshift => 'unshift',
        foo_array_shift   => 'shift'  ,
        foo_array_splice  => 'splice' ,
        foo_array_set     => 'set'    ,
        foo_array_delete  => 'delete' ,
        foo_array_insert  => 'insert' ,
        foo_array_clear   => 'clear'  ,
    });

    has foo_bool => (is => 'rw', traits => ['Bool'], default => 0, omnitrigger => \&_capture_changes, handles => {

        foo_bool_set    => 'set'   ,
        foo_bool_unset  => 'unset' ,
        foo_bool_toggle => 'toggle',
    });

    has foo_code => (is => 'rw', traits => ['Code'], default => sub { sub { 1 } }, omnitrigger => \&_capture_changes);

    has foo_counter => (is => 'rw', traits => ['Counter'], default => 0, omnitrigger => \&_capture_changes, handles => {

        foo_counter_set   => 'set'  ,
        foo_counter_inc   => 'inc'  ,
        foo_counter_dec   => 'dec'  ,
        foo_counter_reset => 'reset',
    });

    has foo_hash => (is => 'rw', traits => ['Hash'], default => sub { {} }, omnitrigger => \&_capture_changes, handles => {

        foo_hash_set    => 'set'   ,
        foo_hash_delete => 'delete',
        foo_hash_clear  => 'clear' ,
    });

    has foo_number => (is => 'rw', traits => ['Number'], default => 42, omnitrigger => \&_capture_changes, handles => {

        foo_number_set => 'set',
        foo_number_add => 'add',
        foo_number_sub => 'sub',
        foo_number_mul => 'mul',
        foo_number_div => 'div',
        foo_number_mod => 'mod',
        foo_number_abs => 'abs',
    });

    has foo_string => (is => 'rw', traits => ['String'], default => 'ABCDE', omnitrigger => \&_capture_changes, handles => {

        foo_string_inc     => 'inc'    ,
        foo_string_append  => 'append' ,
        foo_string_prepend => 'prepend',
        foo_string_replace => 'replace',
        foo_string_chop    => 'chop'   ,
        foo_string_chomp   => 'chomp'  ,
        foo_string_clear   => 'clear'  ,
        foo_string_substr  => 'substr' ,
    });

    has changes => (is => 'ro', isa => 'HashRef', default => sub { {} });

    sub _capture_changes {

        my ($self, $attr_name, $new, $old) = (shift, @_);

        $self->changes->{$attr_name} = [

            @$old ? $old->[0] : 'NOVAL',
            @$new ? $new->[0] : 'NOVAL',
        ];
    }
END

eval(<<"END");
{ package MyClass1; use Moose; use MooseX::OmniTrigger; $stuff; }

{ package MyRole1 ; use Moose::Role;                 use MooseX::OmniTrigger; $stuff; }
{ package MyRole2 ; use Moose::Role; with 'MyRole1';                                  }
{ package MyClass2; use Moose      ; with 'MyRole2';                                  }
END

{
    my $x = $@;

    is(exception { die($x) if $x }, undef, 'nothing blew up') or done_testing and exit;
}

CLASS: for my $class (qw(MyClass1 MyClass2)) {

    TEST: {

        print("# $class ", $class->meta->is_mutable ? 'MUTABLE' : 'IMMUTABLE', "\n");

        my $obj;

        is(exception { $obj = $class->new }, undef, 'nothing blew up') or next CLASS;

        # Array

        $obj->foo_array_push(1, 2, 3);

        is_deeply($obj->changes->{foo_array}, [[] => [1, 2, 3]], 'omnitrigger fires for Array.push; oldval is shallow clone');

        $obj->foo_array_pop;

        is_deeply($obj->changes->{foo_array}, [[1, 2, 3] => [1, 2]], 'omnitrigger fires for Array.pop; oldval is shallow clone');

        $obj->foo_array_unshift(0);

        is_deeply($obj->changes->{foo_array}, [[1, 2] => [0, 1, 2]], 'omnitrigger fires for Array.unshift; oldval is shallow clone');

        $obj->foo_array_shift;

        is_deeply($obj->changes->{foo_array}, [[0, 1, 2] => [1, 2]], 'omnitrigger fires for Array.shift; oldval is shallow clone');

        $obj->foo_array_splice(1, 0, 1.5);

        is_deeply($obj->changes->{foo_array}, [[1, 2] => [1, 1.5, 2]], 'omnitrigger fires for Array.splice; oldval is shallow clone');

        $obj->foo_array_set(0, 'ONE');

        is_deeply($obj->changes->{foo_array}, [[1, 1.5, 2] => ['ONE', 1.5, 2]], 'omnitrigger fires for Array.set; oldval is shallow clone');

        $obj->foo_array_delete(1);

        is_deeply($obj->changes->{foo_array}, [['ONE', 1.5, 2] => ['ONE', 2]], 'omnitrigger fires for Array.delete; oldval is shallow clone');

        $obj->foo_array_insert(2, 3);

        is_deeply($obj->changes->{foo_array}, [['ONE', 2] => ['ONE', 2, 3]], 'omnitrigger fires for Array.insert; oldval is shallow clone');

        $obj->foo_array_clear;

        is_deeply($obj->changes->{foo_array}, [['ONE', 2, 3] => []], 'omnitrigger fires for Array.clear; oldval is shallow clone');

        # Bool

        $obj->foo_bool_set;

        is_deeply($obj->changes->{foo_bool}, [0 => 1], 'omnitrigger fires for Bool.set');

        $obj->foo_bool_unset;

        is_deeply($obj->changes->{foo_bool}, [1 => 0], 'omnitrigger fires for Bool.unset');

        $obj->foo_bool_toggle;

        is_deeply($obj->changes->{foo_bool}, [0 => 1], 'omnitrigger fires for Bool.toggle');

        # Counter

        $obj->foo_counter_set(99);

        is_deeply($obj->changes->{foo_counter}, [0 => 99], 'omnitrigger fires for Counter.set');

        $obj->foo_counter_inc;

        is_deeply($obj->changes->{foo_counter}, [99 => 100], 'omnitrigger fires for Counter.inc');

        $obj->foo_counter_dec;

        is_deeply($obj->changes->{foo_counter}, [100 => 99], 'omnitrigger fires for Counter.dec');

        $obj->foo_counter_reset;

        is_deeply($obj->changes->{foo_counter}, [99 => 0], 'omnitrigger fires for Counter.reset');

        # Hash

        $obj->foo_hash_set(one => 1, two => 2, three => 3);

        is_deeply($obj->changes->{foo_hash}, [{} => {one => 1, two => 2, three => 3}], 'omnitrigger fires for Hash.set; oldval is shallow clone');

        $obj->foo_hash_delete('two');

        is_deeply($obj->changes->{foo_hash}, [{one => 1, two => 2, three => 3} => {one => 1, three => 3}], 'omnitrigger fires for Hash.delete; oldval is shallow clone');

        $obj->foo_hash_clear;

        is_deeply($obj->changes->{foo_hash}, [{one => 1, three => 3} => {}], 'omnitrigger fires for Hash.clear; oldval is shallow clone');

        # Number

        $obj->foo_number_add(1);

        is_deeply($obj->changes->{foo_number}, [42 => 43], 'omnitrigger fires for Number.add');

        $obj->foo_number_sub(1);

        is_deeply($obj->changes->{foo_number}, [43 => 42], 'omnitrigger fires for Number.sub');

        $obj->foo_number_mul(.5);

        is_deeply($obj->changes->{foo_number}, [42 => 21], 'omnitrigger fires for Number.mul');

        $obj->foo_number_div(-.5);

        is_deeply($obj->changes->{foo_number}, [21 => -42], 'omnitrigger fires for Number.div');

        $obj->foo_number_abs;

        is_deeply($obj->changes->{foo_number}, [-42 => 42], 'omnitrigger fires for Number.abs');

        $obj->foo_number_mod(5);

        is_deeply($obj->changes->{foo_number}, [42 => 2], 'omnitrigger fires for Number.mod');

        # String

        $obj->foo_string_inc;

        is_deeply($obj->changes->{foo_string}, [ABCDE => 'ABCDF'], 'omnitrigger fires for String.inc');

        $obj->foo_string_append('Z');

        is_deeply($obj->changes->{foo_string}, [ABCDF => 'ABCDFZ'], 'omnitrigger fires for String.append');

        $obj->foo_string_prepend('~');

        is_deeply($obj->changes->{foo_string}, [ABCDFZ => '~ABCDFZ'], 'omnitrigger fires for String.prepend');

        $obj->foo_string_replace(qr/Z/, "\n\n");

        is_deeply($obj->changes->{foo_string}, ['~ABCDFZ' => "~ABCDF\n\n"], 'omnitrigger fires for String.replace');

        $obj->foo_string_chop;

        is_deeply($obj->changes->{foo_string}, ["~ABCDF\n\n" => "~ABCDF\n"], 'omnitrigger fires for String.chop');

        $obj->foo_string_chomp;

        is_deeply($obj->changes->{foo_string}, ["~ABCDF\n" => '~ABCDF'], 'omnitrigger fires for String.chomp');

        $obj->foo_string_substr(2, 2, '');

        is_deeply($obj->changes->{foo_string}, ['~ABCDF' => '~ADF'], 'omnitrigger fires for String.substr');

        $obj->foo_string_clear;

        is_deeply($obj->changes->{foo_string}, ['~ADF' => ''], 'omnitrigger fires for String.clear');

        $class->meta->make_immutable, redo TEST if $class->meta->is_mutable;
    }
}

done_testing;
