package MooseX::POE::Meta::Trait::Object;
{
  $MooseX::POE::Meta::Trait::Object::VERSION = '0.215';
}
# ABSTRACT: The base class role for MooseX::POE

use Moose::Role;
use POE::Session;

sub BUILD {
    my $self = shift;

    my $session = POE::Session->create(
        inline_states =>
            { _start => sub { POE::Kernel->yield('STARTALL', \$_[5] ) }, },
        object_states => [
            $self => {
                $self->meta->get_all_events,
                STARTALL => 'STARTALL',
                _stop    => 'STOPALL',
                _child   => 'CHILD',
                _parent  => 'PARENT',
                _call_kernel_with_my_session => '_call_kernel_with_my_session',
            },
        ],
        args => [$self],
        heap => ( $self->{heap} ||= {} ),
    );
    $self->{session_id} = $session->ID;
}

sub get_session_id {
    my ($self) = @_;
    return $self->meta->get_meta_instance->get_session_id($self);
}

sub yield { my $self = shift; POE::Kernel->post( $self->get_session_id, @_ ) }

sub call { my $self = shift; POE::Kernel->call( $self->get_session_id, @_ ) }

sub _call_kernel_with_my_session {
	my ( $self, $function, @args ) = @_[ OBJECT, ARG0..$#_ ];
	POE::Kernel->$function( @args );
}

sub delay { my $self = shift; $self->call( _call_kernel_with_my_session => 'delay' => @_ ) }
sub alarm { my $self = shift; $self->call( _call_kernel_with_my_session => 'alarm', @_ ) }
sub alarm_add { my $self = shift; $self->call( _call_kernel_with_my_session => 'alarm_add', @_ ) }
sub delay_add { my $self = shift; $self->call( _call_kernel_with_my_session => 'delay_add', @_ ) }
sub alarm_set { my $self = shift; $self->call( _call_kernel_with_my_session => 'alarm_set', @_ ) }
sub alarm_adjust { my $self = shift; $self->call( _call_kernel_with_my_session => 'alarm_adjust', @_ ) }
sub alarm_remove { my $self = shift; $self->call( _call_kernel_with_my_session => 'alarm_remove', @_ ) }
sub alarm_remove_all { my $self = shift; $self->call( _call_kernel_with_my_session => 'alarm_remove_all', @_ ) }
sub delay_set { my $self = shift; $self->call( _call_kernel_with_my_session => 'delay_set', @_ ) }
sub delay_adjust { my $self = shift; $self->call( _call_kernel_with_my_session => 'delay_adjust', @_ ) }

sub STARTALL {
    my ( $self, @params ) = @_;
    $params[4] = pop @params;
    foreach
        my $method ( reverse $self->meta->find_all_methods_by_name('START') )
    {
        $method->{code}->( $self, @params );
    }
}

sub STOPALL {
    my ( $self, $params ) = @_;
    foreach
        my $method ( reverse $self->meta->find_all_methods_by_name('STOP') ) {
        $method->{code}->( $self, $params );
    }
}

sub START  { }
sub STOP   { }
sub CHILD  { }
sub PARENT { }

# __PACKAGE__->meta->add_method( _stop => sub { POE::Kernel->call('STOP') } );

__PACKAGE__->meta->add_method(
    _default => __PACKAGE__->meta->get_method('DEFAULT') )
    if __PACKAGE__->meta->has_method('DEFAULT');

__PACKAGE__->meta->add_method(
    _child => __PACKAGE__->meta->get_method('CHILD') )
    if __PACKAGE__->meta->has_method('CHILD');

__PACKAGE__->meta->add_method(
    _parent => __PACKAGE__->meta->get_method('PARENT') )
    if __PACKAGE__->meta->has_method('PARENT');
	
no Moose::Role;

1;



=pod

=head1 NAME

MooseX::POE::Meta::Trait::Object - The base class role for MooseX::POE

=head1 VERSION

version 0.215

=head1 SYNOPSIS

    package Counter;
    use MooseX::Poe;

    has name => (
        isa     => 'Str',
        is      => 'rw',
        default => sub { 'Foo ' },
    );

    has count => (
        isa     => 'Int',
        is      => 'rw',
        lazy    => 1,
        default => sub { 0 },
    );

    sub START {
        my ($self) = @_;
        $self->yield('increment');
    }

    sub increment {
        my ($self) = @_;
        $self->count( $self->count + 1 );
        $self->yield('increment') unless $self->count > 3;
    }

    no MooseX::Poe;

=head1 DESCRIPTION

MooseX::POE::Meta::TraitObject is a role that is applied to the object base
classe (usually Moose::Object) that implements a POE::Session.

=head1 METHODS

=head2 get_session_id

Get the internal POE Session ID, this is useful to hand to other POE aware
functions.

=head2 yield

=head2 call

=head2 delay

=head2 alarm

=head2 alarm_add

=head2 delay_add

=head2 alarm_set

=head2 alarm_adjust

=head2 alarm_remove

=head2 alarm_remove_all

=head2 delay_set

=head2 delay_adjust

A cheap alias for the same POE::Kernel function which will gurantee posting to the object's session.

=head2 STARTALL

Along similar lines to Moose's C<BUILDALL> method which calls all the C<BUILD>
methods, this function will call all the C<START> methods in your inheritance
hierarchy automatically when POE first runs your session. (This corresponds to
the C<_start> event from POE.)

=head2 STOPALL

Along similar lines to C<STARTALL>, but for C<STOP> instead.

=head2 START

=head2 STOP

=head2 DEFAULT

=head2 CHILD

=head2 PARENT

=head1 DEFAULT METHODS

=head1 PREDEFINED EVENTS 

=head1 AUTHORS

=over 4

=item *

Chris Prather <chris@prather.org>

=item *

Ash Berlin <ash@cpan.org>

=item *

Chris Williams <chris@bingosnet.co.uk>

=item *

Yuval (nothingmuch) Kogman

=item *

Torsten Raudssus <torsten@raudssus.de> L<http://www.raudssus.de/>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Chris Prather, Ash Berlin, Chris Williams, Yuval Kogman, Torsten Raudssus.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__

