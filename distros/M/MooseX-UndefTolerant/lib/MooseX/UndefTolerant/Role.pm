package MooseX::UndefTolerant::Role;

our $VERSION = '0.21';

use Moose::Role;

sub composition_class_roles { 'MooseX::UndefTolerant::Composite' }

no Moose::Role;

1;
