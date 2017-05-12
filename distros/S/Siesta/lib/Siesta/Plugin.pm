# $Id: Plugin.pm 1356 2003-08-14 15:24:00Z richardc $
package Siesta::Plugin;
use strict;
use Carp qw(croak);
use base 'Siesta::DBI';
__PACKAGE__->set_up_table('plugin');
__PACKAGE__->columns( TEMP => qw( member ));
__PACKAGE__->has_a(   list => 'Siesta::List' );
__PACKAGE__->has_many( prefs => 'Siesta::Pref' );

sub new {
    my $pkg = shift;
    my ($name) = $pkg =~ /:([^:]+)$/;
    $pkg->create({ name => $name, @_ });
}

=head1 NAME

Siesta::Plugin - base class for Siesta Plugins

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 Methods

=head2 ->list

=head2 ->user

=head2 ->personal

does this plugin also run in the personal queue.

=head2 ->process( $message );

C<$message> is a Siesta::Message

Return a true value to indicate "process no further plugins".  use
this for message rejection.

=cut

sub process { die "Siesta::Plugin::process called directly" }

=head2 ->options

Returns a hashref, the keys of which are the various config options a
plugin accepts.  These are:

 description - a short description of the option
 type        - string, number, list, hash, boolean (1 or 0)
 default     - the default value
 widget      - what widget should be used in a gui to represent this

This should be overridden by a deriving class.

=cut

sub options { +{} }


=head2 ->descripton

return a scalar which describes your plugin

=cut

sub description { die "virtual" }

=head2 ->pref( $name )
=head2 ->pref( $name, $value );

=cut

sub pref {
    my $self = shift;
    my $name = shift;

    my $config = $self->options->{$name}
      or croak "no such config option '$name'";

    for my $member ($self->member, 0) {
        next unless defined $member;
        my %crit = ( name   => $name,
                     plugin => $self,
                     member => $member,
                    );
        my ($pref) = Siesta::Pref->search(\%crit);
        if (@_) {
            $pref ||= Siesta::Pref->create(\%crit);
            $pref->value( shift );
            $pref->update;
        }
        return $pref->value if $pref;
    }
    return $config->{default};
}


=head2 promote

Return the Siesta::Plugin::* instance that relates to this object

=cut

sub promote {
    my $self = shift;
    my $class = "Siesta::Plugin::". $self->name;
    $class->require
      or die "error '$class' $UNIVERSAL::require::ERROR";
    $class->retrieve( $self->id );
}


1;

