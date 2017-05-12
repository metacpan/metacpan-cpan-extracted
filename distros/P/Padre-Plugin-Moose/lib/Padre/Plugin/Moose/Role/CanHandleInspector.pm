package Padre::Plugin::Moose::Role::CanHandleInspector;

use Moose::Role;

our $VERSION = '0.21';

requires 'read_from_inspector';
requires 'write_to_inspector';
requires 'get_grid_data';

no Moose::Role;
1;

__END__

=pod

=head1 NAME

Padre::Plugin::Moose::Role::CanHandleInspector - Something that can read from and write to the object inspector

=cut
