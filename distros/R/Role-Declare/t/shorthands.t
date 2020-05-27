use strict;
use warnings;
use Test::Most;

sub Some::Object::new  { bless {}, $_[0] }
sub Other::Object::new { bless {}, $_[0] }

package Some::Interface {
    use Role::Declare;
    use Types::Standard qw[ Bool Int ];

    instance_method _return_maybe              (Bool $good) :ReturnMaybe(Int) {}
    instance_method _return_maybe_undef        (Bool $good) :ReturnMaybe(Int) {}
    instance_method _return_self               (Bool $good) :ReturnSelf {}
    instance_method _return_maybe_self         (Bool $good) :ReturnMaybeSelf {}
    instance_method _return_maybe_self_undef   (Bool $good) :ReturnMaybeSelf {}
    instance_method _return_object             (Bool $good) :ReturnObject {}
    instance_method _return_maybe_object       (Bool $good) :ReturnMaybeObject {}
    instance_method _return_maybe_object_undef (Bool $good) :ReturnMaybeObject {}
    instance_method _return_instance_of        (Bool $good) :ReturnInstanceOf(Some::Object) {}
    instance_method _return_maybe_instance_of  (Bool $good) :ReturnMaybeInstanceOf(Some::Object) {}
    instance_method _return_maybe_instance_of_undef (Bool $good) :ReturnMaybeInstanceOf(Some::Object) {}
}

package Implementation {
    use Role::Tiny::With;
    with 'Some::Interface';

    sub new { bless {}, $_[0] }

    sub _return_maybe {
        my ($self, $good) = @_;
        return 42 if $good;
        return 'Str';
    }

    sub _return_maybe_undef {
        my ($self, $good) = @_;
        return if $good;
        return 'Str';
    }

    sub _return_self {
        my ($self, $good) = @_;
        return $self if $good;
        return (ref $self)->new();
    }

    sub _return_maybe_self { goto &_return_self }

    sub _return_maybe_self_undef {
        my ($self, $good) = @_;
        return if $good;
        return 12;
    }

    sub _return_object {
        my ($self, $good) = @_;
        return Some::Object->new() if $good;
        return 'Some::Object';
    }

    sub _return_maybe_object { goto &_return_object }

    sub _return_maybe_object_undef {
        my ($self, $good) = @_;
        return if $good;
        return 'Some::Object';
    }

    sub _return_instance_of       {
        my ($self, $good) = @_;
        return Some::Object->new() if $good;
        return Other::Object->new();
    }

    sub _return_maybe_instance_of { goto &_return_instance_of }

    sub _return_maybe_instance_of_undef {
        my ($self, $good) = @_;
        return if $good;
        return Other::Object->new();
    }
}

my $obj     = Implementation->new();
my @methods = sort grep { $obj->can($_) and /^_return/ } keys %Implementation::;

plan tests => 2 * @methods;
foreach my $method (@methods) {
    my $retval_good;
    lives_ok { $retval_good = $obj->$method(1) } "$method (correct return value)"
      or diag explain $retval_good;

    my $retval_bad;
    dies_ok { $retval_bad = $obj->$method(0) } "$method (wrong return value)"
        or diag explain $retval_bad;
}
