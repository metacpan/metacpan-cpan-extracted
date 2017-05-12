package MooX::Role::Pluggable::Constants;
$MooX::Role::Pluggable::Constants::VERSION = '1.002002';
use strictures 2;

sub EAT_NONE   () { 1 }
sub EAT_CLIENT () { 2 }
sub EAT_PLUGIN () { 3 }
sub EAT_ALL    () { 4 }

use parent 'Exporter';

our @EXPORT = qw/
  EAT_NONE
  EAT_CLIENT
  EAT_PLUGIN
  EAT_ALL
/;


1;

=pod

=begin Pod::Coverage

EAT.+

=end Pod::Coverage

=head1 NAME

MooX::Role::Pluggable::Constants - MooX::Role::Pluggable EAT values

=head1 SYNOPSIS

  ## Import EAT_NONE, EAT_CLIENT, EAT_PLUGIN, EAT_ALL :
  use MooX::Role::Pluggable::Constants;

=head1 DESCRIPTION

Exports constants used by L<MooX::Role::Pluggable/"_pluggable_process">:

  EAT_NONE   => 1
  EAT_CLIENT => 2
  EAT_PLUGIN => 3
  EAT_ALL    => 4

These are used by plugins to control the lifetime of a plugin-processed 
event. See L<MooX::Role::Pluggable/"_pluggable_process"> for details.

=head1 AUTHOR

Jon Portnoy <avenj@cobaltirc.org>, borrowing from 
L<Object::Pluggable::Constants>

=cut
