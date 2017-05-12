package MooseX::Observer::Role::Observable;
{
  $MooseX::Observer::Role::Observable::VERSION = '0.010';
}
# ABSTRACT: Adds methods an logic to a class, enabling instances changes to be observed

use MooseX::Role::Parameterized;
use Moose::Util::TypeConstraints;
use List::MoreUtils ();
 
{
    my $observerrole_type = role_type('MooseX::Observer::Role::Observer');
    subtype 'ArrayRefOfObservers'
        => as 'ArrayRef'
        => where { List::MoreUtils::all { $observerrole_type->check($_) } @$_ },
        => message { "The Object given must do the 'MooseX::Role::Observer' role." };
}
 
parameter notify_after => (isa => 'ArrayRef', default => sub { [] });

role {
    my $parameters = shift;
    my $notifications_after = $parameters->notify_after;

    my %args = @_;
    my $consumer = $args{consumer}; 
    
    has observers => (
        traits      => ['Array'],
        is          => 'bare',
        isa         => 'ArrayRefOfObservers',
        default     => sub { [] },
        writer      => '_observers',
        handles     => {
            add_observer            => 'push',
            count_observers         => 'count',
            all_observers           => 'elements',
            remove_all_observers    => 'clear',
            _filter_observers       => 'grep',
        },
    );

    for my $methodname (@{ $notifications_after }) {
        if ( $consumer->isa('Class::MOP::Class') ) {
            if ($consumer->find_attribute_by_name($methodname)) {
            
                after $methodname => sub {
                    my $self = shift;
                    $self->_notify(\@_, $methodname) if (@_);
                };
            
            } else {

                after $methodname => sub {
                    my $self = shift;
                    $self->_notify(\@_, $methodname);
                };
            
            }
        }
        elsif ( $consumer->isa('Moose::Meta::Role') ) {
            $consumer->add_after_method_modifier(
                $methodname,
                sub {
                    my $self = shift;
                    $self->_notify( \@_, $methodname );
                }
            );
        }
    }
    
    sub _notify {
        my ($self, $args, $eventname) = @_;
        $_->update($self, $args, $eventname) for ( $self->all_observers );
    }
    
    sub remove_observer {
        my ($self, $observer) = @_;
        my @filtered = $self->_filter_observers( sub { $_ ne $observer } );
        $self->_observers(\@filtered);
    }
};
 
1;


__END__
=pod

=head1 NAME

MooseX::Observer::Role::Observable - Adds methods an logic to a class, enabling instances changes to be observed

=head1 VERSION

version 0.010

=head1 SYNOPSIS

    ############################################################################
    package Counter;

    use Moose;

    has count => (
        traits  => ['Counter'],
        is      => 'rw',
        isa     => 'Int',
        default => 0,
        handles => {
            inc_counter => 'inc',
            dec_counter => 'dec',
        },
    );

    # apply the observable-role and
    # provide methodnames, after which the observers are notified of changes
    with 'MooseX::Observer::Role::Observable' => { notify_after => [qw~
        count
        inc_counter
        dec_counter
        reset_counter
    ~] };

    sub reset_counter { shift->count(0) }

    sub _utility_method { ... }

    ############################################################################
    package Display;

    use Moose;

    # apply the oberserver-role, tagging the class as observer and ...
    with 'MooseX::Observer::Role::Observer';

    # ... require an update-method to be implemented
    # this is called after the observed subject calls an observed method
    sub update {
        my ( $self, $subject, $args, $eventname ) = @_;
        print $subject->count;
    }

    ############################################################################
    package main;

    my $counter = Counter->new();
    # add an observer of type "Display" to our observable counter
    $counter->add_observer( Display->new() );

    # increments the counter to 1, afterwards its observers are notified of changes
    # Display is notified of a change, its update-method is called 
    $counter->inc_counter;  # Display prints 1
    $counter->dec_counter;  # Display prints 0

=head1 DESCRIPTION

This is a parameterized role, that is applied to your observed class. Usually
when applying this role, you provide a list of methodnames. After method
modifiers are installed for these methods. They call the _notify-method, which
in turn calls the update-method of all observers.

=head1 METHODS

=head2 add_observer($observer)

Adds an observer to the object. This Observer must do the
MooseX::Observer::Role::Observer role.

=head2 count_observers

Returns how many observers are attached to the object.

=head2 all_observers

Returns a list of all observers attached to the object.

=head2 remove_observer($observer)

Remove the given observer from the object.

=head2 remove_all_observers

Removes all observers from the object.

=head2 _notify($args, $eventname)

This private method notifies all observers, passing $self, $args and an
$eventname to the observers' update method.

=head1 INSTALLATION

See perlmodinstall for information and options on installing Perl modules.

=head1 SEE ALSO

Please see those modules/websites for more information related to this module.

=over 4

=item *

L<MooseX::Observer|MooseX::Observer>

=back

=head1 AUTHOR

Thomas Müller <tmueller@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Thomas Müller.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

