package Queue::Dir;
# $Id: Dir.pm,v 1.13 2003/03/09 16:18:48 lem Exp $

require 5.005_62;

use strict;
use IO::Dir;
use IO::File;
use warnings;
use Sys::Hostname;
use Fcntl qw(:flock);
use Params::Validate qw(:all);

our $Debug = 0;
our $hires = 'gettimeofday';

eval "use Time::HiRes qw(gettimeofday);";

if ($@) { $hires = 'time' }

use vars qw($a $b);

our $VERSION = 0.01;

=pod

=head1 NAME

Queue::Dir - Manage queue directories where each object is a file

=head1 SYNOPSIS

  use Queue::Dir;

  my $q = new Queue::File (
			   -id => $my_process_id,
			   -paths => [ '/var/path/to/queue1', ... ],
			   -promiscuous => 1,
			   -sort => 'sortsub',
			   -filter => sub { ... },
			   -lockdir => 'lock',
			   -lockmax => 300,
			   );
  
  my ($fh, $qid) = $q->store($oid);

  my $qid = $q->next();

  my $fh = $q->visit($mode, $qid);

  my $status = $q->done($qid);

  my $name = $q->name($qid);

=head1 DESCRIPTION

C<Queue::Dir> allows the manipulation of objects placed in a
queue. The queue is implemented as a directory where each object is
stored as a file.

=head2 METHODS

The following methods are defined:

=over 4

=item C<my $q = new Queue::File (...)>

B<-id> assigns a unique process-id to this queue object. Defaults to
something built from the serialization of the object + C<$$> or
something similar.

B<-paths> specifies a list of paths to use as storage points for the
queue files. If more than one are supplied, round-robin will be used
to store objects there.

When B<-promiscuous> is true (the default), objects stored with any
other C<Queue::File> object are accessible. If set to false, only
files whose id matches the value for B<-id> are visible.

B<-sort> allows for the specification of a sorting function, used to
decide the order in which the queue files will be used. The function
is invoked in the same fashion as C<sort>, getting two variables
(C<$a> and C<$b>) and returning -1, 0 or 1 depending on
comparison. C<$a> and C<$b> are hash references whose first element is
the queue id of the object and the second element is a the full
pathname of such object.

The C<sub { ... }> passed in the B<-filter> parameter can control
which files in a given directory to consider as queue objects. By
default, all files will be considered part of the queue. This function
is called with a reference of the invoking object and the full
pathname of each file. A true return value causes the given file to be
included in the queue. Note that this is only called if
B<-promiscuous> is set to a false value.

B<-lockdir> and B<-lockmax> control an optional locking mechanism that
reduces the chance of multiple collaborating instances of
C<Queue::Dir> objects, from picking the same object from the
queue. B<-lockdir>, when present, defines the name of the directory
(within each queue directory) to use for storing the lock files. The
B<-lockmax> parameter, which defaults to 300 seconds, control for how
long the locks are honored.

Note that locking is disabled by default.

=cut

sub new 
{
    my $name	= shift;
    my $class	= ref($name) || $name;

    warn "Queue::Dir::new()\n" if $Debug;

    my %self = validate_with 
	( 
	  params	=> \@_,
	  ignore_case	=> 1,
	  strip_leading	=> '-',
	  spec => 
	  {
	      id => 
	      { 
		  type => SCALAR, 
		  default => hostname . $$,
	      },
	      paths => 
	      { 
		  type => ARRAYREF,
		  callbacks => 
		  {
		      directory => sub { $_ = shift; @$_ == grep { -d } @$_; }
		  }
	      },
	      promiscuous => 
	      { 
		  type => SCALAR | BOOLEAN,
		  default => 1,
	      },
	      sort => 
	      { 
		  type => SCALAR,
		  default => 'Queue::Dir::_sort',
	      },
	      lockdir =>
	      {
		  type => SCALAR,
		  default => undef,
	      },
	      lockmax =>
	      {
		  type => SCALAR,
		  default => 300,
		  callbacks =>
		  {
		      numeric => sub { shift =~ /^\d+$/ },
		      positive => sub { shift > 0 },
		  },
	      },
	      filter => 
	      { 
		  type => CODEREF,
		  default => sub 
		  {
		      my $self = shift;
		      my $long = shift;
		      
		      return 0 unless $long;

		      my ($path, $id) = (File::Spec->splitpath($long))[1,2];
		      
		      for my $p (@{$self->{paths}})
		      {
			  if (substr($p->[0], $path, 0) == 0
			      and -f $p->[0] . '/' . $id
			      and $id =~ m!^\d+\.\d+\.$self->{id}\.\d+$!)
			  {
			      return 1;
			  }
		      }
		      
		      return 0;
		  },
	      },
	  });
    
    @{$self{paths}} = sort { $a cmp $b } @{$self{paths}};

    $_ = [$_, new IO::Dir $_] for @{$self{paths}};

    if (grep { ! defined $_->[1] } @{$self{paths}}) {
	warn "One of the queue paths seems invalid\n";
	return;
    }

				# Prime the object with an empty file
				# inventory.
    $self{_files}	= [];
    
				# We store objects in round-robin.
    $self{_rr}		= 0;
    $self{_current}	= [0, 0];

    my $self = bless \%self, $class;
    
    $self->_clean_locks if $self->{lockdir};

    return $self->_refresh;
}

sub _sort { $a->[0] cmp $b->[0]; }
sub _timestamp { no strict "refs"; return join '', &$hires; }

				# Update the inventory of queue
				# objects, if required.
sub _refresh 
{
    my $self = shift;

    warn "Queue::Dir::_refresh()\n" if $Debug;

#    warn "_files ", scalar @{$self->{_files}}, " _current[0] ", 
#    $self->{_current}->[0], "\n";

    unless (@{$self->{_files}} or $self->{_current}->[0])
    {
	warn "Queue::Dir::_refresh() running\n" if $Debug;

	for my $p (@{$self->{paths}})
	{
#	    warn "p\n";
	    $p->[1]->rewind;
	    while (defined (my $f = $p->[1]->read))
	    {
		next if $f eq '.' or $f eq '..';
		next unless -f $p->[0] . '/' . $f;
#		warn "f\n";
		my $t = [$f, $p->[0] . '/' . $f];
		if (!$self->{promiscuous}
		    and !$self->{filter}->($t->[1]))
		{
		    next;
		}
		push @{$self->{_files}}, $t;
	    }
	}
				# XXX - I seem unable to specify the sort
				# function directly.
	my $sort = $self->{sort};
	@{$self->{_files}} = sort $sort @{$self->{_files}};
#	$self->{_current} = shift @{$self->{_files}} || [0,0];
    }

    return $self;
}

				# Give a $qid, fetch pathname
sub _name
{
    my $self	= shift;
    my $qid	= shift || $self->{_current}->[0] || $self->next;

				# First, try to find this object in
				# out cached structures

    for my $t (($self->{_current}->[1] ? $self->{_current} : ()), 
	       @{$self->{_files}})
    {
	if ($qid eq $t->[0]) { return $t->[1]; }
    }

				# As a last resort, attempt to find
				# the objext in the fs

    for my $p (@{$self->{paths}})
    {
	$p->[1]->rewind;
	while (my $n = $p->[1]->read)
	{
	    if ($n eq $qid) 
	    {
		return $p->[0] . '/' . $n;
	    }
	}
    }

				# Otherwise, we have to fail...

    return;
}

sub _clean_locks
{
    my $self	= shift;
    
    return unless $self->{lockdir};

    for my $p (@{$self->{paths}})
    {
	my $lock = $p->[0] . '/' . $self->{lockdir};
	mkdir $lock;
	my $d = new IO::Dir $lock;
	while (my $f = $d->read)
	{
	    next if $f eq '.' or $f eq '..';
	    my $name = $lock . '/' . $f;
	    if ((stat($name))[9] + $self->{lockmax} < time)
	    {
		unlink $name;
	    }
	}
    }

}

				# The test below might seem redundant, but
				# it's an attempt to improve in a lot of
				# broken NFS locking implementations.

sub _lock
{
    my $self	= shift;
    my $qid	= shift;

    $self->{lockfh} = new IO::File;

    warn "_lock $qid\n" if $Debug;

    return 1 unless $self->{lockdir};

    $self->{lockfile}	= $self->{paths}->[(split(/\./, $qid))[1]]->[0];

    return unless $self->{lockfile};

    $self->{_key}	= $self->{id} . '-' . $$ . '-' . int(rand(10000));
    $self->{lockfile}	.= '/' . $self->{lockdir} . '/' . $qid;

    warn "_lock lockfile is $self->{lockfile}\n" if $Debug;

    if (-f $self->{lockfile})
    {
	if ((stat(_))[9] + $self->{lockmax} < time)
	{
	    warn "_lock forcing unlink (stale) lockfile\n" if $Debug;
	    unlink $self->{lockfile};
	}
	else
	{
	    warn "_lock failing due to previous lock\n" if $Debug;
	    return;
	}
    }
				# Store our key in the lock file

    $self->{lockfh}->open($self->{lockfile}, O_RDWR | O_CREAT) or return;
    $self->{lockfh}->autoflush(1);

    unless (flock $self->{lockfh}, LOCK_EX | LOCK_NB)
    {
	$self->{lockfh}->close;
	$self->{lockfh} = undef;
	unlink $self->{lockfile};
	$self->{lockfile} = undef;
	return;
    }
    $self->{lockfh}->print($self->{_key});

    warn "_lock key $self->{_key} stored\n" if $Debug;

				# Verify that the key is indeed in the
				# lock file

    $self->{lockfh}->seek(0, 0);
    chomp(my $rkey = $self->{lockfh}->getline);

    warn "_lock key $rkey recovered\n" if $Debug;

    unless ($rkey eq $self->{_key})
    {	
	$self->{lockfh}->close;
	$self->{lockfh} = undef;
	unlink $self->{lockfile};
	$self->{lockfile} = undef;
	return;
    }

    warn "_lock key matched\n" if $Debug;

				# If all this passed, the lock is ours
    return 1;
}

=pod

=item C<my ($fh, $qid) = $q-E<gt>store();>

Store a file in the queue. Returns an array whose first element is an
C<IO::Handle> object for writing to the file. The second element is
the identifier of the object in the queue.

If you created the C<Queue::Dir> object with locking enabled, you must
call C<-E<gt>unlock> after closing the file handle.

=cut

sub store 
{
    my $self	= shift;
    my $fh	= new IO::File;
    my $queue	= $self->{paths}->[$self->{_rr}];
    my $qid	= _timestamp . '.' . $self->{_rr} . '.' . $self->{id};
    my $counter	= 0;
    my $pname;

    warn "Queue::Dir::store() qid=$qid\n" if $Debug;

    $self->{_rr} ++;
    $self->{_rr} %= @{$self->{paths}};

    while (-f ($pname = $queue->[0] . '/' . $qid . '.' . $counter))
    {
	++ $counter;
    }

    $qid .= '.' . $counter;

    $fh->open($pname, "w") or return;
    $self->{_current} = [$qid, $pname];

    $self->_lock($qid);

    return ($fh, $qid);
}

=pod

=item C<my $qid = $q-E<gt>next();>

Returns the queue identifier of the next file to be processed. When
the queue is empty, returns undef. 

Note that if multiple consumers are working on the same queues in
promiscuous mode, the file referenced by the returned id might be
removed at any time so care must be used.

Entries will be returned in an arbitrary order.

=cut

sub next 
{
    my $self	= shift;

    $self->_refresh unless @{$self->{_files}};

    $self->{_current} = shift @{$self->{_files}} || [0, 0];

    warn "Queue::Dir::next() current=", $self->{_current}->[0], "\n" if $Debug;

#    warn "next: Current queue has\n";
#    foreach (@{$self->{_files}})
#    {
#	warn "  $_->[1]\n";
#    }

    unless ($self->{_current}->[0])
    {
	$self->_refresh;
	return;
    }

    return $self->{_current}->[0];
}

=pod

=item C<my $fh = $q-E<gt>visit($mode, $qid);>

On success, returns an C<IO::Handle> object, opened according to the
specified C<$mode> for the file with C<$qid>. If C<$mode> is not
specified, it defaults to a read from the start of the file. If
C<$qid> is not specified, it defaults to the next entry, as if
C<-E<gt>next()> were called. In order for the file to be eligible,
either the C<Queue::Dir> object is not created with locking enabled or
the file in the queue is not locked.

It can fail in a number of situations. The obvious one, is when the
queue is empty. The second one, happens when the desired file is no
longer in the queue, which can happen if multiple consumers are
accessing the queue in promiscuous mode.

To help disambiguate both scenarios, undef will be returned on an
empty queue. A defined but false value will be returned when the
desired file is missing but others remain in the queue.

The object in the queue will be automatically locked if this option is
enabled when C<-E<gt>new> was called. In this case, you should call
the C<-E<gt>unlock> method.

=cut

sub visit 
{
    my $self	= shift;
    my $mode	= shift || "r";
    my $qid	= shift || $self->{_current}->[0] || $self->next;

    warn "Queue::Dir::visit() qid=$qid\n" if $Debug;

    return unless $qid;

    my $fh	= new IO::File;
    my $name;
    
    until ($name = $self->_name($qid) 
	   and -f $name 
	   and $self->_lock($qid)
	   and $fh->open($name, $mode))
    {
	unless ($qid = $self->next)
	{
	    if (@{$self->{_files}}) 
	    {
		warn "Queue::Dir::visit() ret undef\n" if $Debug;
		return undef;
	    }
	    else
	    {
		warn "Queue::Dir::visit() ret 0\n" if $Debug;
		return 0;
	    }
	}
    }

    return $fh;
}

=pod

=item C<$q-E<gt>done($qid);>

Disposes the queue file whose C<$qid> matches the given identifier as
well as its potential lock. If none is specified, defaults to the last
one used in a C<-E<gt>visit()>.

It is a bad idea (or at least rough manners) to C<unlink()> the file
without invoking C<-E<gt>done>. Besides, C<-E<gt>done> will do it for
you.

=cut

sub done 
{
    my $self = shift;
    my $qid  = shift || $self->{_current}->[0];
    my $wipe = 0;

    warn "Queue::Dir::done() qid=$qid\n" if $Debug;

    return if $qid eq 0;

    my $name = $self->_name($qid);

    return unless $name;

    $self->unlock($qid);

    unlink $name;

    for (my $i = 0;
	 $i < @{$self->{_files}};
	 $i ++)
    {
	if ($self->{_files}->[$i]->[0] eq $qid)
	{
	    splice(@{$self->{_files}}, $i, 1);
	    return;
	}
    }

}

=pod

=item C<my $fname = $q-E<gt>name($qid);>

Returns the full pathname of the queue file whose id matches
C<$qid>. If none is supplied, defaults to the last one obtained
through a C<-E<gt>store()>, C<-E<gt>next()> or C<-E<gt>visit()>.

It could return C<undef> is the queue object no longer exists.

=cut

sub name 
{
    my $self	= shift;
    my $qid	= shift || $self->{_current}->[0] || $self->next;
    warn "Queue::Dir::name() qid=$qid\n" if $Debug;
    return $self->_name($qid);
}

=pod

=item C<-E<gt>unlock($qid)>

Removes any locks outstanding in the file identified by C<$qid>, or
the last C<visit()>ed file. Use of this method is only required if the
object is created with locking enabled.

=cut

sub unlock
{
    my $self	= shift;
    my $qid	= shift || $self->{_current}->[0];
    my $fh	= new IO::File;

    warn "unlock $qid\n" if $Debug;

    return 1 unless $self->{lockdir};
    return 1 unless $self->{lockfh};

    close $self->{lockfh};
    $self->{lockfh} = undef;

    unlink $self->{lockfile};
    $self->{lockfile} = undef;

    return 1;
}

1;
__END__

=pod

=back

=head2 EXPORT

None by default.

=head1 HISTORY

$Id: Dir.pm,v 1.13 2003/03/09 16:18:48 lem Exp $

$Log: Dir.pm,v $
Revision 1.13  2003/03/09 16:18:48  lem
Added more fixes for lock()/unlock(). We should not lose locks provided a working flock()

Revision 1.12  2003/01/19 15:01:09  lem
Added fcntl(LOCK_UN) to unlock() to free the lock

Revision 1.11  2002/12/09 22:53:58  lem
Added flock() locking in addition to our own locking scheme

Revision 1.10  2002/12/09 22:36:34  lem
->visit() has better decoupling. Added some tests

Revision 1.9  2002/12/08 04:23:05  lem
->visit must return an object as soon as available. Added tests for this too.

Revision 1.8  2002/12/08 01:00:18  lem
Added locking + tests


=over 8

=item 0.01

Original version; created by h2xs 1.2 with options

  -ACOXcfkmn
	Queue::Dir
	-v
	0.01

=back


=head1 AUTHOR

Luis E. Muñoz <luismunoz@cpan.org>

=head1 SEE ALSO

perl(1).

=cut
