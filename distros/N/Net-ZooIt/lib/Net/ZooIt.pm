package Net::ZooIt;

use strict;
use warnings;

our $VERSION = '0.20';

use Sys::Hostname qw(hostname);
use Carp qw(croak);
use POSIX qw(strftime);
use Time::HiRes qw(time);
use feature ':5.10';

use Net::ZooKeeper qw(:all);

use base qw(Exporter);
our @EXPORT = qw(ZOOIT_DIE ZOOIT_ERR ZOOIT_WARN ZOOIT_INFO ZOOIT_DEBUG);

# Logging
sub ZOOIT_DIE { 0 }
sub ZOOIT_ERR { 1 }
sub ZOOIT_WARN { 2 }
sub ZOOIT_INFO { 3 }
sub ZOOIT_DEBUG { 4 }
my @log_levels = qw(ZOOIT_DIE ZOOIT_ERR ZOOIT_WARN ZOOIT_INFO ZOOIT_DEBUG);
my $log_level = 1;

sub set_log_level {
    my $level = shift;
    return unless $level =~ /^\d+$/;
    $log_level = $level;
}

sub logger {
    my ($level, $msg) = @_;
    return unless $level =~ /^\d+$/;
    return if $level > $log_level;
    $msg =~ s/\n$//;
    my $prefix = strftime '%Y-%m-%dT%H:%M:%SZ', gmtime;
    $prefix .= " $$";
    $prefix .= " $log_levels[$level]";
    print STDERR "$prefix $msg\n";
    croak $msg if $level == 0;
}

sub zdie { logger ZOOIT_DIE, @_ }
sub zerr { logger ZOOIT_ERR, @_ }
sub zwarn { logger ZOOIT_WARN, @_ }
sub zinfo { logger ZOOIT_INFO, @_ }
sub zdebug { logger ZOOIT_DEBUG, @_ }

sub zerr2txt {
    my $err = shift;
    our %code2name;
    unless (%code2name) {
        foreach my $name (@{$Net::ZooKeeper::EXPORT_TAGS{errors}}) {
            no strict "refs";
            my $code = &$name;
            use strict "refs";
            $code2name{$code} = $name;
        }
    }
    return $code2name{$err};
}

# Generate and split sequential znode names
sub gen_seq_name { hostname . ".PID.$$-" }
sub split_seq_name { shift =~ /^(.+-)(\d+)$/; $1, $2 }

# ZooKeeper recipe Lock
sub new_lock {
    my $class = shift;
    zerr "lock will be released immediately, new_lock called in void context"
        unless defined wantarray;
    my %p = @_;
    zdie "Param zk must be a connect Net::ZooKeeper object"
        unless ref $p{zk};
    zdie "Param path must be a valid ZooKeeper znode path"
        unless $p{path} =~ m|^/.+|;

    my $lockname = gen_seq_name;
    my $lock = $p{zk}->create(
        "$p{path}/$lockname" => 1,
        flags => ZOO_EPHEMERAL|ZOO_SEQUENCE,
        acl => ZOO_OPEN_ACL_UNSAFE,
    );
    unless ($lock) {
        zerr "Could not create $p{path}/$lockname: " . zerr2txt($p{zk}->get_error);
        return;
    }
    zinfo "Created lock $lock";
    # Create the blessed object now, for auto-deletion if next operations fail
    my $res = bless { lock => $lock, zk => $p{zk} }, $class;
    my $t0 = time;

    my ($basename, $n) = split_seq_name $res->{lock};
    while (1) {
        _gc($p{zk});

        my @locks = $p{zk}->get_children($p{path});
        my $err = $p{zk}->get_error;
        if ($err ne ZOK) {
            zerr "Could not get lock list: " . zerr2txt($err);
            return;
        }
        zdebug "Get lock list: @locks";
        # Look for other lock with highest sequence number lower than mine
        my ($lock_prev, $n_prev);
        foreach (@locks) {
            my ($basename_i, $n_i) = split_seq_name $_;
            next if $n_i >= $n;
            if (!defined $n_prev || $n_i > $n_prev) {
                $n_prev = $n_i;
                $lock_prev = $_;
            }
        }
        # If none found, the lock is mine
        unless (defined $n_prev) {
            zinfo "Take lock: $res->{lock}";
            return $res;
        }
        # I can't take lock, abort if timeout reached
        my $dt;
        if (defined $p{timeout}) {
            $dt = $t0 + $p{timeout} - time;
            if ($dt <= 0) {
                zinfo "Timeout reached, abort";
                return;
            }
        }
        # Wait for lock with highest seq number lower than mine to be deleted
        $dt //= 60;
        $dt *= 1000;
        my $w = $p{zk}->watch(timeout => $dt);
        $w->wait if $p{zk}->exists("$p{path}/$lock_prev", watch => $w);
    }
}

# ZooKeeper recipe Queue
sub new_queue {
    my $class = shift;
    my %p = @_;
    zdie "Param zk must be a connect Net::ZooKeeper object"
        unless ref $p{zk};
    zdie "Param path must be a valid ZooKeeper znode path"
        unless $p{path} =~ m|^/.+|;

    return bless { queue => $p{path}, zk => $p{zk} }, $class;
}

sub put_queue {
    my ($self, $data) = @_;
    my $itemname = gen_seq_name;
    my $item = $self->{zk}->create(
        "$self->{queue}/$itemname" => $data,
        flags => ZOO_SEQUENCE,
        acl => ZOO_OPEN_ACL_UNSAFE,
    );
    unless ($item) {
        zerr "Could not create $self->{queue}/$itemname: " . zerr2txt($self->{zk}->get_error);
        return;
    }
    zinfo "Created queue item $item";
    return 1;
}

sub get_queue {
    my $self = shift;
    my %p = @_;
    my $t0 = time;
    while (1) {
        _gc($self->{zk});

        my @items = $self->{zk}->get_children($self->{queue});
        my $err = $self->{zk}->get_error;
        if ($err ne ZOK) {
            zerr "Could not get queue items: " . zerr2txt($err);
            return;
        }
        zdebug "Get queue items: @items";
        # Look for queue item with lowest seq number
        my ($item_min, $n_min);
        foreach (@items) {
            my ($item_i, $n_i) = split_seq_name $_;
            if (!defined $n_min || $n_i < $n_min) {
                $n_min = $n_i;
                $item_min = $_;
            }
        }
        # If queue empty, wait for get_children, max timeout [s]
        unless (defined $n_min) {
            my $dt;
            if (defined $p{timeout}) {
                $dt = $t0 + $p{timeout} - time;
                if ($dt <= 0) {
                    zinfo "Timeout reached, abort";
                    return;
                }
            }
            $dt //= 60;
            $dt *= 1000;
            my $w = $self->{zk}->watch(timeout => $dt);
            $w->wait unless $self->{zk}->get_children("$self->{queue}", watch => $w);
            next;
        }
        # Get data, attempt to delete znode with lowest seq number
        zinfo "Attempt to get/delete $item_min";
        my $data = $self->{zk}->get("$self->{queue}/$item_min");
        $err = $self->{zk}->get_error;
        if ($err ne ZOK) {
            zerr "Could not get item data: " . zerr2txt($err);
            next;
        }
        if ($self->{zk}->delete("$self->{queue}/$item_min")) {
            return $data;
        }
        $err = $self->{zk}->get_error;
        if ($err ne ZNONODE) {
            zerr "Error deleting queue item: " . zerr2txt($err);
            return;
        } else {
            zinfo "Someone else deleted $item_min";
        }
    }
}

# Automatic deletion of znodes when ZooIt objects go out of scope
# Garbage collection for znodes deleted during ZCONNECTIONLOSS
my @garbage;

sub DESTROY {
    my $self = shift;
    if ($self->{lock}) {
        zinfo "DESTROY deleting lock: $self->{lock}";
        $self->{zk}->delete($self->{lock});
        my $err = zerr2txt($self->{zk}->get_error);
        if ($err ne 'ZOK') {
            push @garbage, $self->{lock};
            zerr "Could not delete $self->{lock}: $err";
        }
        delete $self->{lock};
    }
}

sub _gc {
    my $zk = shift;
    while (my $znode = shift @garbage) {
        zinfo "_gc deleting $znode";
        $zk->delete($znode);
        my $err = zerr2txt($zk->get_error);
        zdebug "  $err";
        if ($err eq 'ZOK' || $err eq 'ZNONODE') {
            zinfo "$znode deleted by _gc";
        } else {
            zerr "$znode could not be deleted by _gc: $err";
            unshift @garbage, $znode;
            last;
        }
    }
}

1;

__END__

=head1 NAME

Net::ZooIt - High level recipes for Apache Net::ZooKeeper

=head1 SYNOPSIS

  use Net::ZooKeeper;
  use Net::ZooIt;

  Net::ZooIt::set_log_level(ZOOIT_DEBUG);

  my $zk = Net::ZooKeeper->new('localhost:7000');
  while (1) {
      my $lock = Net::ZooIt->new_lock(zk => $zk, path => '/election');
      last unless $lock;
      do_stuff_when_elected();
  }

=head1 DESCRIPTION

Net::ZooIt provides high level recipes for working with ZooKeeper in Perl,
like locks or leader election.

=head2 Net::ZooKeeper Handles

Net::ZooIt methods always take a Net::ZooKeeper handle object as a parameter
and delegate their creation to the user. Rationale: enterprises often have
customised ways to create those handles, Net::ZooIt aims to be instantly
usable without such customisation.

=head2 Automatic Cleanup

Net::ZooIt constructors return a Net::ZooIt object, which automatically
clean up their znodes when they go out of scope at the end of the enclosing
block. If you want to clean up earlier, call

  $zooit_obj->DESTROY;

Implication: if you call Net::ZooIt constructors in void context, the
created object goes out of scope immediately, and your znodes are deleted.
Net::ZooIt logs a ZOOIT_ERR message in this case.

=head2 Error Handling

Net::ZooIt constructors return nothing in case of errors during creation.

Once you hold a lock or other resource, you're not notified of connection
loss errors. If you need to take special action, check your Net::ZooKeeper
handle.

If you give up Net::ZooIt resources during connection loss, your znodes
cannot be cleaned up immediately, they will enter a garbage collection queue
and Net::ZooIt will clean them up once connection is resumed.

=head2 Logging

Net::ZooIt logs to STDERR.
Log messages are prefixed with Zulu military time, PID and the level of
the current message: ZOOIT_DIE ZOOIT_ERR ZOOIT_WARN ZOOIT_INFO ZOOIT_DEBUG.

If Net::ZooIt throws an exception, it prints a ZOOIT_DIE level message
before dying. This allows seeing the original error message even if
an eval {} block swallows it.

=head1 METHODS

=over 4

=item new_lock()

  my $lock = Net::ZooIt->new_lock(zk => $zk, path => '/lock');
  my $lock = Net::ZooIt->new_lock(zk => $zk, path => '/lock', timeout => 1);

Blocks by default until the lock is acquired.
Returns a lock object on success, which automatically cleans up its
znodes when the object goes out of scope at the end of the enclosing block.

Returns nothing on errors, or when the acquisition of the lock did not
succeed before the specified timeout. Nonblocking lock can be achieved
with timeout => 0.

The method is not reentrant, calling it in a recursive function causes
a deadlock.

Use the same method for leader election.

=item new_queue()

  my $queue = Net::ZooIt->new_queue(zk => $zk, path => '/queue');

Returns a queue object. DISCLAIMER! Please do not abuse ZooKeeper queues.
They store items in a flat way under your /queue znode,
which does not scale well.

=item put_queue()

  my $success = $queue->put_queue($data);

Create queue item storing data. Returns true on success, nothing on failure.

=item get_queue()

  my $data = $queue->get_queue;
  my $data = $queue->get_queue(timeout => 5);

Get an item from queue. Returns data in queue item, or nothing on errors
or after timeout [s] has elapsed.

=back

=head1 FUNCTIONS

=over 4

=item set_log_level()

  Net::ZooIt::set_log_level($level);

=back

=head1 EXPORTS

Net::ZooIt exports its log_level constants by default:
ZOOIT_DIE ZOOIT_ERR ZOOIT_WARN ZOOIT_INFO ZOOIT_DEBUG.

=head1 SEE ALSO

The Apache ZooKeeper project's home page at
L<http://zookeeper.apache.org/> provides a wealth of detail
on how to develop applications using ZooKeeper.

=head1 AUTHOR

SZABO Gergely, E<lt>szg@subogero.comE<gt>

=head1 LICENSE

This file is licensed to you under the Apache License, Version 2.0.
You may not use this file except in compliance with the License.
See a copy of the License in COPYING, distributed along with this file,
or obtain a copy at

  http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

=cut
