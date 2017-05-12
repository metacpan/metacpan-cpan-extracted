package Storm::Meta::Class::Trait::AutoTable;
{
  $Storm::Meta::Class::Trait::AutoTable::VERSION = '0.240';
}
use Moose::Role;

around '_build_storm_table' => sub {
    my $orig = shift;
    my $self = shift;
    return (split /::/, $self->name)[-1];
};

package Moose::Meta::Class::Custom::Trait::AutoTable;
{
  $Moose::Meta::Class::Custom::Trait::AutoTable::VERSION = '0.240';
}
sub register_implementation { 'Storm::Meta::Class::Trait::AutoTable' };
1;
