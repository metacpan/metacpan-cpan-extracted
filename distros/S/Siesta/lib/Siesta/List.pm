# $Id: List.pm 1334 2003-08-13 13:07:42Z richardc $
use strict;
package Siesta::List;
use UNIVERSAL::require;
use Siesta::DBI;
use base 'Siesta::DBI';
use Carp qw( croak );
use POSIX qw( strftime );
__PACKAGE__->set_up_table('list');
__PACKAGE__->load_alias('name');
__PACKAGE__->has_a( owner => 'Siesta::Member' );
__PACKAGE__->has_many( members  => [ 'Siesta::Subscription' => 'member' ] );

# this is a bit funny, never mind
__PACKAGE__->has_many( _plugins => 'Siesta::Plugin', 'list',
                       { sort => 'rank' } );


=head1 NAME

Siesta::List - manipulate a list

=head1 METHODS

=head2 ->new ( %hash )

=cut

sub new { shift->create({ @_ }) }


=head2 ->name

the short name of the list

=head2 ->owner

the owner (a Siesta::Member)

=head2 ->post_address

the email address that people post to send to this list.

=cut

# the address to use to post to pipline $foo
sub address {
    my $self = shift;
    my $pipeline = shift;

    # XXX - hacky
    my $address = $self->post_address;
    return $address if !$pipeline || $pipeline eq 'post';
    $address =~ s/\@/-$pipeline\@/;
    return $address;
}

=head2 ->return_path

the email address that bounces should come back to

=head2 ->members

all of the L<Siesta::Member>s subscribed to this list

=head2 ->prefs

all of the preferences associated with this list

=head2 ->is_member( $member )

Returns true or false depending if member is a member of this
list.  This can take either a Member object or an email address.

=cut

sub is_member {
    my $self = shift;
    my $member = shift;

    $member = Siesta::Member->load( $member ) unless ref $member;
    return unless $member;
    Siesta::Subscription->search( member => $member, list => $self );
}


=head2 ->add_member( $member )

Adds a member to a list. This can take either a Member object
or an email address.

=cut

sub add_member {
    my $self = shift;
    my $member = shift;

    $member = Siesta::Member->find_or_create({ email => $member })
      unless ref $member;
    return if $self->is_member( $member );
    Siesta::Subscription->create({ member => $member, list => $self });
}


=head2 ->remove_member( $member )

Removes a member from a list. This can take either a Member
object or an email address.

=cut

sub remove_member {
    my $self = shift;
    my $member = shift;

    $member = Siesta::Member->load( $member ) unless ref $member;
    return unless $member;
    my ($record) = Siesta::Subscription->search( member => $member,
                                                 list => $self );
    return unless $record;
    $record->delete;
    return 1;
}


=head2 ->members

Returns a list of all the members in the list (as Member objects)

=head2 ->queues

Returns a list of all processing queues associated with this list.

=cut

sub queues {
    qw( post sub unsub );
}


=head2 ->plugins( [ $queue ] )

Returns a list of all the plugins for a list (as Plugin objects).

=cut

sub plugins {
    my $self = shift;
    my $queue = shift || 'post';
    # map from the raw accessor we set up into the correct classes
    return map { $_->promote } grep { $_->queue eq $queue } $self->_plugins;
}


=head2 ->add_plugin( $queue => $plugin )
=head2 ->add_plugin( $queue => $plugin, $position )

Add a plugin to this lists processing queue $queue.

$position is optional, and indiates the new index of the plugin.

=cut

sub add_plugin {
    my $self = shift;
    my $queue = shift;
    my $plugin = shift;
    my $pos = shift;

    my $personal = ($plugin =~ s/^\+//);
    my @existing = $self->plugins( $queue );
    croak "can only add 1 instance of a plugin to a queue"
      if grep { $_->name eq $plugin } @existing;

    if ( defined $pos && $existing[ $pos - 1 ] ) {
        for (@existing) { # shuffle the others up
            if ($_->rank >= $pos) {
                $_->rank( $_->rank + 1 );
                $_->update;
            }
        }
    }
    else {
        $pos = @existing + 1;
    }

    Siesta::Plugin->create({ queue    => $queue,
                             name     => $plugin,
                             rank     => $pos,
                             list     => $self,
                             personal => $personal,
                         });
}


=head2 ->set_plugins( $queue => @plugins)

Set the plugin processing queue for this list.

=cut

sub set_plugins {
    my $self = shift;
    my $queue = shift;
    my $i;
    my %new_rank = map { (my $name = $_) =~ s/^\+//;
                         $name => { personal => $_ ne $name,
                                    rank     => ++$i }
                     } @_;

    die "'$queue' doesn't look like an queue id" unless $queue =~ /^[a-z]+$/;

    # first, delete the plugins that don't exist in the new order
    for ($self->plugins($queue)) {
        $_->delete unless $new_rank{ $_->name };
    }

    # then just add new ones
    my %old = map { $_->name => 1 } $self->plugins($queue);
    for my $plugin (keys %new_rank) {
        next if $old{ $plugin };
        Siesta::Plugin->create({ name     => $plugin,
                                 list     => $self,
                                 queue    => $queue,
                                 rank     => 0,
                                 personal => 0,
                             });
    }

    # and reorder all of them
    for ($self->plugins($queue)) {
        $_->rank(     $new_rank{ $_->name }{rank} );
        $_->personal( $new_rank{ $_->name }{personal} );
        $_->update;
    }
    return 1;
}


=head2 ->alias [app name]

Returns a string which is can be used as an alias to post to a
list. If you pass in an app name then it will use that in the
description as

    created by <app name>

B<NB> I<assumes that the path to 'tequila' is the same as the path of
the script calling the method. This may be broken.>

=cut

sub alias {
    my $self = shift;
    my $app  = shift || "Siesta";

    ( my $path = $0 ) =~ s!^(.*[\\/]).*$!$1!;
    my $tequila = $path."tequila";
    return Siesta->bake('list_alias',
                        app     => $app,
                        list    => $self,
                        tequila => $path."tequila",
                       );
}


1;

