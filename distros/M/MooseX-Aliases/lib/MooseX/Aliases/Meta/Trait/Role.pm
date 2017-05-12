package MooseX::Aliases::Meta::Trait::Role;
BEGIN {
  $MooseX::Aliases::Meta::Trait::Role::AUTHORITY = 'cpan:DOY';
}
{
  $MooseX::Aliases::Meta::Trait::Role::VERSION = '0.11';
}
use Moose::Role;

sub composition_class_roles { 'MooseX::Aliases::Meta::Trait::Role::Composite' }

no Moose::Role;

=begin Pod::Coverage

composition_class_roles

=end Pod::Coverage

=cut

1;
