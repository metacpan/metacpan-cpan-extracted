#!/usr/bin/perl -c

package MooseX::GlobRef::Role::Meta::Instance;

=head1 NAME

MooseX::GlobRef::Role::Meta::Instance - Instance metaclass for MooseX::GlobRef

=head1 SYNOPSIS

  Moose::Util::MetaRole::apply_metaclass_roles(
      for_class => $caller,
      instance_metaclass_roles =>
          [ 'MooseX::GlobRef::Role::Meta::Instance' ],
  );

=head1 DESCRIPTION

This instance metaclass allows to store Moose object in glob reference of
file handle.  It is applied by L<MooseX::GlobRef>.

=cut

use 5.006;
use strict;
use warnings;

our $VERSION = '0.0701';

use Moose::Role;


# Use weaken
use Scalar::Util ();


=head1 METHODS

=over

=item <<override>> B<create_instance>(I<>) : Object

=cut

override 'create_instance' => sub {
    my ($self) = @_;

    # create anonymous file handle
    select select my $fh;

    # initialize hash slot of file handle
    %{*$fh} = ();

    return bless $fh => $self->_class_name;
};


=item <<override>> B<clone_instance>( I<instance> : Object ) : Object

=cut

override 'clone_instance' => sub {
    my ($self, $instance) = @_;

    # create anonymous file handle
    select select my $fh;

    # initialize hash slot of file handle
    %{*$fh} = ( %{*$instance} );

    return bless $fh => $self->_class_name;
};

=item <<override>> B<get_slot_value>( I<instance> : Object, I<slot_name> : Str ) : Any

=cut

override 'get_slot_value' => sub {
    my ($self, $instance, $slot_name) = @_;
    return *$instance->{$slot_name};
};


=item <<override>> B<set_slot_value>( I<instance> : Object, I<slot_name> : Str, I<value> : Any ) : Any

=cut

override 'set_slot_value' => sub {
    my ($self, $instance, $slot_name, $value) = @_;
    return *$instance->{$slot_name} = $value;
};


=item <<override>> B<deinitialize_slot>( I<instance> : Object, I<slot_name> : Str ) : Any

=cut

override 'deinitialize_slot' => sub {
    my ($self, $instance, $slot_name) = @_;
    return delete *$instance->{$slot_name};
};


=item <<override>> B<is_slot_initialized>( I<instance> : Object, I<slot_name> : Str ) : Bool

=cut

override 'is_slot_initialized' => sub {
    my ($self, $instance, $slot_name) = @_;
    return exists *$instance->{$slot_name};
};


=item <<override>> B<weaken_slot_value>( I<instance> : Object, I<slot_name> : Str )

=cut

override 'weaken_slot_value' => sub {
    my ($self, $instance, $slot_name) = @_;
    return Scalar::Util::weaken *$instance->{$slot_name};
};


=item <<override>> B<inline_create_instance>( I<class_variable> : Str ) : Str

=cut

override 'inline_create_instance' => sub {
    my ($self, $class_variable) = @_;
    return 'do { select select my $fh; %{*$fh} = (); bless $fh => ' . $class_variable . ' }';
};


=item <<override>> B<inline_slot_access>( I<instance_variable> : Str, I<slot_name> : Str ) : Str

The methods overridden by this class.

=back

=cut

override 'inline_slot_access' => sub {
    my ($self, $instance_variable, $slot_name) = @_;
    return '*{' . $instance_variable . '}->{' . $slot_name . '}';
};


no Moose::Role;

1;


=head1 SEE ALSO

L<MooseX::GlobRef>, L<Moose::Meta::Instance>, L<Moose>.

=head1 AUTHOR

Piotr Roszatycki <dexter@cpan.org>

=head1 LICENSE

Copyright (c) 2007, 2008, 2009, 2010 Piotr Roszatycki <dexter@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as perl itself.

See L<http://dev.perl.org/licenses/artistic.html>
