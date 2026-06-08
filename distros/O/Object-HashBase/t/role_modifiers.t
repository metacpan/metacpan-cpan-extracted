use strict;
use warnings;
use Test::More;

# Role::Tiny loads Class::Method::Modifiers only when a method modifier
# (around/before/after) is actually used. A 'use' statement runs at compile
# time regardless of any runtime guard, so the modifier test lives in its own
# file that can skip_all before anything is compiled. This keeps install/test
# unblocked on smokers that have Role::Tiny but not Class::Method::Modifiers.
BEGIN {
    eval { require Role::Tiny; 1 } or plan skip_all => 'Role::Tiny required';
    plan skip_all => 'Role::Tiny 1.003000 or newer required (is_role missing)'
        unless Role::Tiny->can('is_role');
    plan skip_all => "& prefix requires perl 5.10+" if $] < 5.010;
    eval { require Class::Method::Modifiers; 1 }
        or plan skip_all => 'Class::Method::Modifiers required for method modifiers';
}

# Method modifier (around) sees consumer method (deferred compose)
BEGIN {
    package My::AroundRole;
    use Role::Tiny;
    use Object::HashBase qw/wrapped/;
    around 'do_it' => sub {
        my ($orig, $self, @args) = @_;
        return "wrapped(" . $self->$orig(@args) . ")";
    };
    $INC{'My/AroundRole.pm'} = __FILE__;
}

BEGIN {
    package My::AroundConsumer;
    use Object::HashBase qw/&My::AroundRole/;
    sub do_it { 'inner' }
}

is(My::AroundConsumer->new->do_it, 'wrapped(inner)',
    'around modifier wraps consumer method (deferred compose worked)');

done_testing;
