use strict;
use warnings;
use Moose::Util qw/find_meta/;
use Moose::Meta::Class;
use MooseX::MethodAttributes ();
use Test::More tests => 7;

{
    package My::Role;
    use Moose::Role -traits => 'MethodAttributes';

    sub foo : Bar {}
}
{
    package My::SuperClass;
    use Moose;

    sub bar {}
}

my $meta = Moose::Meta::Class->create_anon_class(
    superclasses => ['My::SuperClass'],
    roles => ['My::Role'],
    cache => 1
);

# FIXME - Note special move here, required
#         as you get the original metaclass
#         back, not the one with the roles
#         appled.
my $other_meta = find_meta($meta->name);

ok $other_meta;
my $classname = $other_meta->name;
isa_ok $classname->new, 'My::SuperClass';
isa_ok $classname->new, 'Moose::Object';
ok $classname->can('foo');
ok $classname->can('new');
ok $classname->can('bar');
my $attr = $other_meta->get_method_attributes( $classname->can('foo') );
is_deeply $attr, ['Bar'];

