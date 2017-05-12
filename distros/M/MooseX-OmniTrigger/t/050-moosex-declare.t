use strict; use warnings; use warnings (FATAL => qw(misc numeric uninitialized)); # use autodie;

use Test::More;
use Test::Fatal;

BEGIN {

    eval("use MooseX::Declare");

    plan skip_all => "MooseX::Declare isn't installed or wouldn't load" if $@;
}

class MyClass1 {

    use MooseX::OmniTrigger;

    has foo => (is => 'rw', isa => 'Str', omnitrigger => \&_capture_changes);

    has changes => (is => 'ro', isa => 'HashRef', default => sub { {} });

    method _capture_changes (Str $attr_name!, ArrayRef $new_val!, ArrayRef $old_val!) {

        push(@{$self->changes->{$attr_name}}, sprintf('%s=>%s',

            @$old_val ? defined($old_val->[0]) ? $old_val->[0] : 'UNDEF' : 'NOVAL',
            @$new_val ? defined($new_val->[0]) ? $new_val->[0] : 'UNDEF' : 'NOVAL',
        ));
    }
}

{
    my $obj;

    is(exception { $obj = MyClass1->new({foo => 'INITVAL'}) }, undef, 'obj constructed for class consuming MooseX::OmniTrigger');

    is("@{$obj->changes->{foo} || []}", 'NOVAL=>INITVAL');
}


role MyRole1 {

    use MooseX::OmniTrigger;

    has foo => (is => 'rw', isa => 'Str', omnitrigger => \&_capture_changes);

    has changes => (is => 'ro', isa => 'HashRef', default => sub { {} });

    method _capture_changes (Str $attr_name!, ArrayRef $new_val!, ArrayRef $old_val!) {

        push(@{$self->changes->{$attr_name}}, sprintf('%s=>%s',

            @$old_val ? defined($old_val->[0]) ? $old_val->[0] : 'UNDEF' : 'NOVAL',
            @$new_val ? defined($new_val->[0]) ? $new_val->[0] : 'UNDEF' : 'NOVAL',
        ));
    }
}

class MyClass2 with MyRole1 { }

{
    my $obj;

    is(exception { $obj = MyClass2->new({foo => 'INITVAL'}) }, undef, 'obj constructed for class consuming role consuming MooseX::OmniTrigger');

    is("@{$obj->changes->{foo} || []}", 'NOVAL=>INITVAL');
}


role MyRole2 with MyRole1 { }

class MyClass3 with MyRole2 { }

{
    my $obj;

    is(exception { $obj = MyClass3->new({foo => 'INITVAL'}) }, undef, 'obj constructed for class consuming role consuming role consuming MooseX::OmniTrigger');

    is("@{$obj->changes->{foo} || []}", 'NOVAL=>INITVAL');
}

done_testing;
