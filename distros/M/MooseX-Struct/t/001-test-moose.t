#!perl -T

use Test::More;
use Test::Moose;

use MooseX::Struct;

my $scalar = 'Foo';
my %hash   = ( 'Bar' => 'Baz' );
my @array  = ( 1, 2, 3 );

my @types = MooseX::Struct::_types();

plan tests => 2 + (scalar @types) * 2;

my %attr_list;

my $attr_name = 'a';

foreach my $type (@types) {
   $attr_list{$attr_name++} = $type;
}

struct 'MyObject' => %attr_list;

no warnings;
my %type_examples = (
   'Value'     => 'Foo',
   'ScalarRef' => \$scalar,
   'ArrayRef'  => \@array,
   'HashRef'   => \%hash,
   'GlobRef'   => \*hash,
   'Num'       => 42,
   'Int'       => 2,
   'Str'       => 'String',
   'RegexpRef' => qr/^.*$/,
   'CodeRef'   => sub {return 1},
   'Any'       => 'Thing',
   'Bool'      => 1,
);
use warnings;

my $object;

ok($object = new MyObject, 'Object creation');

meta_ok($object, "Meta object created successfully");

foreach my $attr_name (sort keys %attr_list) {
   has_attribute_ok($object,$attr_name, "Attribute '$attr_name' exists");
}

foreach my $attr_name (sort keys %attr_list) {
   my $real_type = MooseX::Struct::_types($attr_list{$attr_name});
   if (!$real_type->{isa}) {
      if ($real_type->{is} eq 'ro') {
         ok(!eval{$object->$attr_name('foo')}, "Inable to set read only attribute");
      } else {
         ok($object->$attr_name(rand 100), "Setting arbitrary type ok");   
      }
   } else {
      my $type_value = $type_examples{$real_type->{isa}};
      ok($object->$attr_name($type_value), "Setting $real_type->{isa} OK ('$attr_list{$attr_name}')");
   }
}

