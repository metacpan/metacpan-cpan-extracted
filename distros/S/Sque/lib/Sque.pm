use strict;
use warnings;
package Sque;
$Sque::VERSION = '0.010';
use Any::Moose;
use Any::Moose '::Util::TypeConstraints';
use Net::Stomp;

use Sque::Job;
use Sque::Worker;

# ABSTRACT: Background job processing based on Resque, using Stomp

subtype 'Sugar::Stomp' => as class_type('Net::Stomp');

coerce 'Sugar::Stomp'
    => from 'Str'
    => via {
        my ( $host, $port ) = split /:/;
        my $stomp = Net::Stomp->new({ hostname => $host, port => $port });
        $stomp->connect;
        return $stomp;
    };

coerce 'Sugar::Stomp'
    => from 'ArrayRef[Str]'
    => via {
        my ($a) = @_;
        my $hosts = [];
        for ( @$a ) {
            my ( $host, $port ) = split /:/;
            push @$hosts, { hostname => $host, port => $port };
        }

        my $stomp = @$hosts > 1
            ? Net::Stomp->new({ hosts => $hosts })
            : Net::Stomp->new({
                    hostname => $hosts->[0]{hostname},
                    port     => $hosts->[0]{port}
                });

        $stomp->connect;
        return $stomp;
    };

has stomp => (
    is => 'ro',
    lazy => 1,
    coerce => 1,
    isa => 'Sugar::Stomp',
    default => sub { Net::Stomp->new->connect },
);

has namespace => ( is => 'rw', default => sub { 'sque' });

has worker => (
    is => 'ro',
    lazy => 1,
    default => sub { Sque::Worker->new( sque => $_[0] ) },
);

sub push {
    my ( $self, $queue, $job ) = @_;
    confess "Can't push an empty job." unless ( $job || ref $queue );
    if( ref $queue ){
        $job = $self->new_job($queue) unless ref $queue eq 'Sque::Job';
        $queue = $job->queue;
    } else {
        $job = $self->new_job($job) unless ref $job eq 'Sque::Job';
    }

    $self->stomp->send( {
        persistent => 'true',
        destination => $self->key( $queue ),
        body => $job->encode,
        %{ $job->headers },
    } );
}

sub pop {
    my ( $self ) = @_;
    my $frame = $self->stomp->receive_frame;
    return unless $frame;

    $self->new_job({
        frame => $frame,
        queue => $frame->destination,
    });
}

sub new_job {
    my ( $self, $job ) = @_;

    if ( $job && ref $job && ref $job eq 'HASH' ) {
        return Sque::Job->new({ sque => $self, %$job });
    }
    elsif ( $job ) {
        return Sque::Job->new({ sque => $self, payload => $job });
    }
    confess "Can't build an empty Sque::Job object.";
}

sub key {
    my $self = shift;
    '/queue/' . $self->namespace . '/' . shift;
}

__PACKAGE__->meta->make_immutable();

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Sque - Background job processing based on Resque, using Stomp

=head1 VERSION

version 0.010

=head1 SYNOPSIS

First you create a Sque instance where you configure the L<Stomp>
backend and then you can start sending jobs to be done by workers:

    use Sque;

    my $s = Sque->new( stomp => '127.0.0.1:61613' );
    # Or, for failover
    $s = Sque->new( stomp => [ '127.0.0.1:61613', '127.0.0.2:61613' ] );

    $s->push( my_queue => {
        class => 'My::Task',
        args => [ 'Hello world!' ]
    });

You can also send by just using:

    $s->push({
        class => 'My::Task',
        args => [ 'Hello world!' ]
    });

In this case, the queue will be set automatically automatically to the
job class name with colons removed, which in this
case would be 'MyTask'.

You can set custom C<STOMP> headers by passing them in as follows:

    $s->push( my_queue => {
        class => 'My::Task',
        args => [ 'Hello world!' ],
        headers => { header1 => 'val1', header2 => 'val2' }
    });

Additionally, the L<sque> command-line tool can be used to send messages:

    $ sque send -h 127.0.0.1 -p 61613 -c My::Task 'Hello world!'

Background jobs can be any perl module that implement a perform() function.
The L<Sque::Job> object is passed as the only argument to this function:

    package My::Task;
    use strict;
    use 5.10.0;

    sub perform {
        my ( $job ) = @_;
        say $job->args->[0];
    }

    1;

Background jobs can also be OO.  The perform function will still be called
with the L<Sque::Job> object as the only argument:

    package My::Task;
    use strict;
    use 5.10.0;
    use Moose;

    with 'Role::Awesome';

    has attr => ( is => 'ro', default => 'Where am I?' );

    sub perform {
        my ( $self, $job ) = @_;
        say $self->attr;
        say $job->args->[0];
    }

    1;

Finally, you run your jobs by instancing a L<Sque::Worker> and telling it
to listen to one or more queues:

    use Sque;

    my $w = Sque->new( stomp => '127.0.0.1:61613' )->worker;
    $w->add_queues('my_queue');
    $w->work;

Or you can simply use the L<sque> command-line tool which uses L<App::Sque>
like so:

    $ sque work --host 127.0.0.1 --port 61613 --workers 5 --lib ./lib --lib ./lib2 --queues Queue1,Queue2,Queue3

=head1 DESCRIPTION

This is a copy of L<resque-perl|https://github.com/diegok/resque-perl>
by L<Diego Kuperman|https://github.com/diegok> simplified a little bit
(for better or worse) and made to work with any stomp server rather than Redis.

=head1 ATTRIBUTES

=head2 stomp

A Stomp Client on this sque instance.

=head2 namespace

Namespace for queues, default is 'sque'

=head2 worker

A L<Sque::Worker> on this sque instance.

=head1 METHODS

=head2 push

Pushes a job onto a queue. Queue name should be a string and the
item should be a L<Sque::Job> object or a hashref containing:
class - The String name of the job class to run.
args - Any arrayref of arguments to pass the job.

Example:

    $sque->push( archive => { class => 'Archive', args => [ 35, 'tar' ] } )

=head2 pop

Pops a job off a queue. Queue name should be a string.
Returns a l<Sque::Job> object.

=head2 key

Concatenate C<$self->namespace> with the received array of names
to build a redis key name for this sque instance.

=head2 new_job

Build a L<Sque::Job> object on this system for the given
hashref(see L<Sque::Job>) or string(payload for object).

=head1 ATTRIBUTES

=head1 HELPER METHODS

=head1 TODO

=over 4

=item * Make App::Sque that will let you run sque and just pass it the
stomp server/port, queue list, lib directories (if needed), and
number of workers.

=item * More (real) tests.

=back

=head1 AUTHOR

William Wolf <throughnothing@gmail.com>

=head1 COPYRIGHT AND LICENSE


William Wolf has dedicated the work to the Commons by waiving all of his
or her rights to the work worldwide under copyright law and all related or
neighboring legal rights he or she had in the work, to the extent allowable by
law.

Works under CC0 do not require attribution. When citing the work, you should
not imply endorsement by the author.

=cut
