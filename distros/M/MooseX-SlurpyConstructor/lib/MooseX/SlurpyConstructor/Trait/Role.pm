package MooseX::SlurpyConstructor::Trait::Role;

our $VERSION = '1.30';

use Moose::Role;

sub composition_class_roles { 'MooseX::SlurpyConstructor::Trait::Composite' }

no Moose::Role;

1;
