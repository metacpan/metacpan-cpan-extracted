package Padre::Plugin::Moose::Role::CanProvideHelp;

use Moose::Role;

our $VERSION = '0.21';

requires 'provide_help';

no Moose::Role;
1;

__END__

=pod

=head1 NAME

Padre::Plugin::Moose::Role::CanProvideHelp - Something that can provide help about itself

=cut
