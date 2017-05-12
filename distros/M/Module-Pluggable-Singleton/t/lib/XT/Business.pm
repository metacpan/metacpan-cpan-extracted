package XT::Business;
use strict;
use warnings;
#use Moose;
#use Module::Pluggable::Object;
#use MooseX::Types::Moose qw/Undef Str ArrayRef HashRef Bool/;

#extends 'Me::Plugin';
#use base qw/Me::Plugin/;
#use Me::Plugin;
#use Module::Pluggable::Singleton search_path => 'XT::Business::Logic';
use Module::Pluggable::Singleton;

#use parent 'Module::Pluggable::Singleton';

#has 'namespace' => (
#    is          => 'ro',
#    isa         => Str,
#    default     => sub{ 'XT::Business::Logic' },
#);
#
#has 'plugin_prefix' => (
#    is          => 'rw',
#    isa         => Str,
#    default     => sub{ '' },
#);
#has search_path => (
#    is          => 'rw',
#    isa         => ArrayRef|Str,
#    default     => sub { [qw/XT::Business::Logic/] },
#    required    => 1,
#);



=head2 find_plugin

Given dbix channel row, and the name of the component ie 'OrderImporter' it will
see if there is a module for the given business/component combo. Returns undef
otherwise

=cut
#sub find_plugin {
#    my($self,$channel,$component) = @_;
#
#    if (ref($channel) !~ /Public::Channel$/) {
#        die __PACKAGE__ .": parameter is not dbix channel row";
#    }
#
#    return $self->find(
#        $channel->business->short_name
#        ."::" .$component);
#
#    
#}
1;
