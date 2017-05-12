package Term::YAP::iThread;
$Term::YAP::iThread::VERSION = '0.07';
use strict;
use warnings;
use threads 2.01;
use Thread::Queue 3.05;
use Types::Standard 1.000005 qw(InstanceOf Bool);
use Moo 2.000002;
use namespace::clean 0.26;

extends 'Term::YAP';

=head1 NAME

Term::YAP::iThread - subclass of Term::YAP implemented with ithreads

=cut

=head1 SYNOPSIS

See parent class.

=head1 DESCRIPTION

Subclass of L<Term::YAP> implemented with ithreads. The pun with it's name is intended.

Despite the limitation of L<http://perldoc.perl.org/threads.html#WARNING|'ithreads'> some platforms (like Microsoft Windows) does not work well
with process handling of Perl. If you in this case, this implementation of L<Term::YAP> might help you.

If you program code does not handle C<ithreads> correctly, consider initiation a Term::YAP::iThread object in a C<BEGIN> block to avoid loading
the code that does not support C<ithreads>.

=head1 ATTRIBUTES

Additionally to all attributes from superclass, this class also has the C<queue> attribute.

=head2 queue

Keeps a reference of a L<Thread::Queue> instance. This instance is created automatically during L<Term::YAP::iThread> creation.

=cut

has queue => (
    is      => 'rw',
    isa     => InstanceOf ['Thread::Queue'],
    reader  => 'get_queue',
    builder => sub { Thread::Queue->new() }
);

=head2 detach

A "private" attribute. Used to control when the created thread is expected to exists it's infinite loop after C<start_pulse> method invocation.

=cut

has detach => (
    is      => 'rw',
    isa     => Bool,
    reader  => '_no_detach',
    writer  => '_set_detach',
    default => 1
);

=head1 METHODS

The following methods are overriden from parent class:

=over

=item start

=item stop

=back

=head2 get_queue

Getter for the C<queue> attribute.

=head2 BUILD

Creates a thread right after object instantiation.

The thread will start only after C<start> method is called. 

=cut

sub BUILD {

    my $self = shift;
    my $thread = threads->create( sub { $self->_keep_pulsing() } );
    $thread->detach();

}

around start => sub {

    my ( $orig, $self ) = ( shift, shift );
    $self->get_queue()->enqueue('start');
    $self->_sleep();
    my $status = $self->get_queue()->pending();

    if ( $status == 0 ) {
        $self->_set_running(1);    #thread dequeued the start string
    }
    else {
        $self->_set_running(0);
    }
    $self->$orig;

};

around _keep_pulsing => sub {

    my ( $orig, $self ) = ( shift, shift );

    while ( $self->_no_detach() ) {

        my $task = $self->get_queue()->dequeue();

        if ( $task eq 'start' ) {

            $self->$orig(@_);

        }

    }

};

around _is_enough => sub {

    my ( $orig, $self ) = ( shift, shift );

    my $message = $self->get_queue()->dequeue_nb();

    if ( ( defined($message) ) and ( $message eq 'stop' ) ) {

        return 1;

    }
    else {

        return 0;

    }

};

around stop => sub {

    my ( $orig, $self ) = ( shift, shift );
    $self->get_queue()->enqueue('stop');
    $self->$orig;

};

=pod

=head2 DEMOLISH

This method will take care to "terminated" the L<Thread::Queue> object used to provide communication with the thread.

=cut

sub DEMOLISH {

    my $self = shift;
    $self->get_queue()->end();

}

=pod

=head1 CAVEATS

To enable usage of this module with code that does not supports L<threads>, this class will create a detached thread as soon as the object
was created. This thread will remain active until the end of the program, waiting to receive a command to start the pulse (or stop it).

That said, the class will not try to create new threads and will not check if the created thread exited successfully (but it does check if
the thread is retrieving items from the L<Thread::Queue> object created).

=head1 SEE ALSO

=over

=item *

L<Term::Pulse>

=item *

L<Moo>

=item *

L<Term::YAP::Pulse>

=item *

L<threads>

=item *

L<Thread::Queue>

=back

=head1 AUTHOR

Alceu Rodrigues de Freitas Junior, E<lt>arfreitas@cpan.orgE<gt>

L<Term::Pulse> was originally created by Yen-Liang Chen, E<lt>alec at cpan.comE<gt>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 of Alceu Rodrigues de Freitas Junior, E<lt>arfreitas@cpan.orgE<gt>

This file is part of Term-YAP distribution.

Term-YAP is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

Term-YAP is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with Term-YAP. If not, see <http://www.gnu.org/licenses/>.

=cut

1;
