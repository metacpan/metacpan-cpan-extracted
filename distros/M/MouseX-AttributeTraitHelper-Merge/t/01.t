package Trait1;
use Mouse::Role;

has 'allow' => (isa => 'Int', default => 123);

no Mouse::Role;

package Trait2;
use Mouse::Role;

has 'allow' => (isa => 'Str', default => 'qwerty');

no Mouse::Role;

package ClassWithTrait;
use Mouse -traits => 'MouseX::AttributeTraitHelper::Merge';

has attrib => (
    is => 'rw',
    isa => 'Int',
    traits => ['Trait1', 'Trait2'],
);

has attrib2 => (
    is => 'rw',
    isa => 'Int',
    traits => ['Trait1', 'Trait2'],
);
no Mouse;
__PACKAGE__->meta->make_immutable();

package ClassWithOutTrait;
use Mouse -traits => 'MouseX::AttributeTraitHelper::Merge';

has attrib => (
    is => 'rw',
    isa => 'Int',
);

no Mouse;
__PACKAGE__->meta->make_immutable();

package MyRole::Trait;
use Mouse::Role;
use Mouse::Util;

sub add_field {
    my $self = shift;
    my $name = shift;
    my %args = @_;
    $args{traits} = ['Trait1', 'Trait2'];
    return $self->add_attribute($name => %args);
}
no Mouse::Role;

package MyRoleWithOutHelper;

use Mouse;

extends 'Mouse::Meta::Role';
with 'MyRole::Trait';

no Mouse;
__PACKAGE__->meta->make_immutable();

package MyRoleWithHelper;

use Mouse;

extends 'Mouse::Meta::Role';
with 'MyRole::Trait';
with 'MouseX::AttributeTraitHelper::Merge';

no Mouse;
__PACKAGE__->meta->make_immutable();

package main;
use Test::More;
ok(ClassWithTrait->meta->get_attribute('attrib')->{allow} eq 'qwerty', 'Merged');
ok(!exists(ClassWithOutTrait->meta->get_attribute('attrib')->{allow}), 'ClassWithOutTrait');
ok(ClassWithTrait->meta->get_attribute('attrib')->does('Trait1'), 'does');
ok(ClassWithTrait->meta->get_attribute('attrib')->does('Trait2'), 'does2');


my $name = 'MyResult';
my $rolemeta = MyRoleWithOutHelper->initialize("${name}::Role");
$rolemeta->add_field(attrib => (is => 'rw'));
my $meta = Mouse->init_meta(metaclass => 'Mouse::Meta::Class', for_class => $name);
eval {
    Mouse::Util::apply_all_roles($meta, $rolemeta);
};
ok($@ =~ /attribute conflict with/, 'Conflict');

$name = 'MyResultOk';
$rolemeta = MyRoleWithHelper->initialize("${name}::Role");
$rolemeta->add_field(attrib => (is => 'rw'));
$meta = Mouse->init_meta(metaclass => 'Mouse::Meta::Class', for_class => $name);
Mouse::Util::apply_all_roles($meta, $rolemeta);
ok(MyResultOk->meta->get_attribute('attrib')->{allow} eq 'qwerty', 'Merged 2');

done_testing();
