package POSIX::RT::MQ;

# $Id: MQ.pm,v 1.12 2003/01/28 07:10:03 ilja Exp $

use 5.006;
use strict;
use warnings;
use Carp 'croak';
use Fcntl 'O_NONBLOCK';

require DynaLoader;

our @ISA = qw(DynaLoader);
our $VERSION = '0.03';

bootstrap POSIX::RT::MQ $VERSION;

sub open
{
    my $proto  = shift;
    (@_ >= 2 && @_ <= 4)
        or croak 'Usage: POSIX::RT::MQ->open(name, oflag [, mode [, attr]])';

    my @args = @_;
    $args[2] = 0666                 unless defined $args[2];
    $args[3] = attr_pack($args[3])  if     defined $args[3]; # pack attr
    
    defined(my $mqdes  = mq_open(@args))  or return undef;
    my $class  = ref($proto) || $proto;
    my $self   = bless { name=>$args[0], mqdes=>$mqdes }, $class;

    # get attributes and save for future references (in receive())
    $self->{_saved_attr_} = $self->attr  or return undef;
    
    $self;
}

sub unlink 
{ 
    my $self  = shift;
    if (ref $self)
    {
        (@_ == 0) or croak 'Usage: $mq->unlink()';
        my $rc = mq_unlink($self->{name});
        $self->{name} = undef  if defined $rc;
        return $rc;
    }
    else
    {
        (@_ == 1) or croak 'Usage: POSIX::RT::MQ->unlink(name)';
        return mq_unlink($_[0]);
    }
}

sub attr
{
    my $self = shift;
    (@_ >= 0 && @_ <= 1) or croak 'Usage: $mq->attr( [new_attr] )';
    my $attr_packed = mq_attr( $self->{mqdes}, map {attr_pack($_)} @_ );

    defined $attr_packed ? attr_unpack($attr_packed) : undef;
}

sub send
{ 
    my $self = shift;
    (@_ >= 1 && @_ <= 2) or croak 'Usage: $mq->send($msg ,[ $prio ])';
    mq_send( $self->{mqdes}, $_[0], ($_[1] || 0) );
}

sub receive 
{ 
    my $self = shift;
    (@_ == 0) or croak 'Usage: $mq->receive()';
    my @result = mq_receive($self->{mqdes}, $self->{_saved_attr_}{mq_msgsize});
    wantarray ? @result : $result[0];
}

sub notify
{ 
    my $self = shift;
    (@_ <= 1) or croak 'Usage: $mq->notify([ $signo ])';
    mq_notify( $self->{mqdes}, @_ );
}

sub blocking
{
    my $self = shift;
    (@_ <= 1) or croak 'Usage: $mq->blocking([ BOOL ])';

    my $a = $self->attr()  or return undef;
    my $old_blocking = ($a->{mq_flags} & O_NONBLOCK) ? 0 : 1;
    if (@_) 
    {
        if ($_[0]) { $a->{mq_flags} &= (~O_NONBLOCK); }
        else       { $a->{mq_flags} |= O_NONBLOCK;    }

        $self->attr($a) or $old_blocking = undef;;
    }

    $old_blocking;
}

sub name { $_[0]->{name} }

sub DESTROY 
{ 
    my $self  = shift;
    defined($self->{mqdes}) and mq_close($self->{mqdes});
    $self->{mqdes} = undef;
}    


sub attr_pack
{
    my $as_hash = shift;
    mq_attr_pack( map {defined $as_hash->{$_} ? $as_hash->{$_} : 0} 
                      qw/mq_flags mq_maxmsg mq_msgsize mq_curmsgs/ );
}


sub attr_unpack
{
    my @attr = mq_attr_unpack(shift);
    { mq_flags=>$attr[0], mq_maxmsg=>$attr[1], mq_msgsize=>$attr[2], mq_curmsgs=>$attr[3] };
}

1;

__END__

=head1 NAME

POSIX::RT::MQ - Perl interface for POSIX Message Queues


=head1 SYNOPSIS

 use POSIX::RT::MQ;
 
 my $mqname = '/some_queue';
 
 my $attr = { mq_maxmsg  => 1024, mq_msgsize =>  256 };

 my $mq = POSIX::RT::MQ->open($mqname, O_RDWR|O_CREAT, 0600, $attr) 
     or die "cannot open $mqname: $!\n";
 
 $mq->send('some_message', 0) or die "cannot send: $!\n";

 my ($msg,  $prio)  = $mq->receive or die "cannot receive: $!\n";

=head1 DESCRIPTION

C<POSIX::RT::MQ> provides an OO-style interface to the POSIX
message queues (C<mq_open()> and friends), which are part of the
POSIX Realtime Extension. 

This documentation is B<not> a POSIX message queues tutorial.
It describes mainly the syntax of Perl interface, please consult 
your operating system's manpages for general information on 
underlying calls. More references are listed in L</SEE ALSO>.


=head1 CONSTRUCTOR

=over 4

=item open( $name, $oflag [, $mode [, $attr]] )

A wrapper for the C<mq_open()> function.

 $mq = open('/some_q1', O_RDWR);
 $mq = open('/some_q2', O_RDWR|O_CREAT, 0600);
 
 $attr = { mq_maxmsg=>1000, mq_msgsize=>2048 };
 $mq = open('/some_q3', O_RDWR|O_CREAT, 0600, $attr);

Opens a message queue C<$name> and returns a reference to a new object.

Two optional arguments C<$mode> and C<$attr> are used when a new
message queue is created. C<$mode> specifies permissions bits
set for the new queue and C<$attr> (a hash reference) specifies 
the message queue attributes for the new queue.

The C<$attr> represents the C<struct mq_attr>. The following keys are
recognized and their values are interpreted as the similary named structure 
fields:

  mq_flags
  mq_maxmsg
  mq_msgsize
  mq_curmsgs

Usually only C<mq_maxmsg> and C<mq_msgsize> are respected by the
underlying C<mq_open()> function, the other fields (if present) 
are just ignored.

On error returns C<undef>.

=back


=head1 DESTRUCTOR

=over 4

=item DESTROY

A wrapper for the C<mq_close()> function.

Usually there is no need to call it manually. When the objects 
created by C<open()> method is destroyed the underlying message
queue gets closed automatically by destructor.

=back



=head1 METHODS

=over 4

=item attr( [$new_attr] )

A wrapper for the C<mq_getattr()> and C<mq_setattr()> functions.

 $current_attr = $mq->attr();
 $old_attr = $mq->attr($new_attr);
 
 # set the non-blocking mode:
 $attr = $mq->attr();
 $attr->{mq_flags} |= O_NONBLOCK;
 $mq->attr($attr);

If called without arguments returns the message queue arrtibutes
as a hash reference.

If called with an argument (a hash reference) sets message queue 
attributes as per C<$new_attr> and returns the old attributes. 

The C<$attr> represents the C<struct mq_attr>. The following keys are
recognized and their values are interpreted as the similary named structure 
fields:

  mq_flags
  mq_maxmsg
  mq_msgsize
  mq_curmsgs

Usually only C<mq_flags> is respected by the underlying C<mq_setattr()> function,
the other fields (if present) are just ignored.

However the hash reference returned by C<attr()> will always contain all key/value
pairs listed above.

On error returns C<undef>.

See also the description of C<blocking()> method.

=item receive

A wrapper for the C<mq_receive()> function.

 $msg = $mq->receive();
 ($msg, $prio) = $mq->receive();

Gets a message from the queue.
In scalar context returns just the message, in list context
returns a two-element array which contains the message
as the first element and it's priority as the second.

On errror returns C<undef> or an empty list.

=item send( $msg [, $prio ] )

A wrapper for the C<mq_send()> function.

 $msg = 'some message';
 $mq->send($msg);

Sends the content of C<$msg> to the queue as a message of priority C<$prio>.
If C<$prio> is omitted it will be set to C<0>.

Returns true on success, C<undef> on error.

=item unlink( [$name] )

A wrapper for the C<mq_unlink()> function.

 POSIX::RT::MQ->unlink($name);
 $mq->unlink();

When called as C<POSIX::RT::MQ-E<gt>unlink($name)> unlinks the message queue C<$name>. 

When called as C<$mq-E<gt>unlink()> unlinks the queue which corresponds to the
$mq object (the one that was supplied to C<open()> at $mq creation).
Note that the queue will be not closed, only unlinked. It will remain
functional (but 'anonymous') until closed by all current users. Also,
subsequent calls to C<$mq-E<gt>name> will return C<undef> if C<$mq-E<gt>unlink>
completes successfully.

On errror returns C<undef>.

=item notify([ $signo ])

A limited wrapper for the C<mq_notify()> function.

    my $got_usr1 = 0;
    local $SIG{USR1} = sub { $got_usr1 = 1 };
    $mq->notify(SIGUSR1)  or  warn "cannot notify(SIGUSR1): $!\n";

If called with an argument C<$signo> this method registers the calling process
to be notified of message arrival at an empty message queue in question.
At any time, only one process may be registered for notification by a specific
message queue. 

If called without arguments and the process is currently registered for notification 
by the message queue in question, the existing registration is removed.

Return true on success, C<undef> on error.

Currently this module dosn't support the full C<mq_notify()> semantic and doesn't
let the user to provide his own C<struct sigevent>.

The semantic of C<$mq-E<gt>notify($signo)> is equivalent in C to:
        
        struct sigevent sigev;
        sigev.sigev_notify = SIGEV_SIGNAL;
        sigev.sigev_signo  = $signo
        sigev.sigev_value.sival_int = 0;
        mq_notify(mqdes, &sigev);

The semantic of C<$mq-E<gt>notify()> is equivalent in C to:

        mq_notify(mqdes, NULL);

Please refer to documents listed in L</SEE ALSO> for a complete description of notifications.

=item blocking([ BOOL ])

A covinience method.

 $mq->blocking(0);
 # now in non-blocking mode
 ...
 $mq->blocking(1);
 # now in blocking mode

If called with an argument C<blocking()> will turn on non-blocking behavior of
the message queue in question if C<BOOL> is false, and turn it off if C<BOOL> is true.

C<blocking()> will return the value of the previous setting, or the current setting 
if C<BOOL> is not given.

On errror returns C<undef>.

You may get the same results by using the C<attr()> method.
                          
=item name

A covinience method.
 
 $name = $mq->name();

Returns either the queue name as it was supplied to C<open()>
or C<undef> if C<$mq-E<gt>unlink> was (successfully) called before.

=back

           
=head1 CONSTANTS

=over 4

=item MQ_OPEN_MAX

Access to the MQ_OPEN_MAX constant.

 $open_max = POSIX::RT::MQ::MQ_OPEN_MAX;     

=item MQ_PRIO_MAX

Access to the MQ_PRIO_MAX constant.

 $prio_max = POSIX::RT::MQ::MQ_PRIO_MAX;     

=back

           
=head1 BUGS

C<mq_notify()> function is not fully supported.


=head1 AUTHOR

Ilja Tabachnik E<lt>billy@arnis-bsl.comE<gt>

=head1 SEE ALSO

L<mq_open>, L<mq_close>, L<mq_unlink>, L<mq_getattr>, L<mq_setattr>, L<mq_send>, L<mq_receive>, L<mq_notify>

The Single UNIX Specification, Version 2 (http://www.unix.org/version2/)

The Single UNIX Specification, Version 3 (http://www.unix.org/version3/)

The Base Definitions volume of IEEE Std 1003.1-2001.

=cut
