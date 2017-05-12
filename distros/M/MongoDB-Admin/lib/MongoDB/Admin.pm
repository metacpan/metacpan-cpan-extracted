#
#  Copyright 2010, 2011  David Burley.
#
#  Licensed under the Apache License, Version 2.0 (the "License");
#  you may not use this file except in compliance with the License.
#  You may obtain a copy of the License at
#
#  http://www.apache.org/licenses/LICENSE-2.0
#
#  Unless required by applicable law or agreed to in writing, software
#  distributed under the License is distributed on an "AS IS" BASIS,
#  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#  See the License for the specific language governing permissions and
#  limitations under the License.
#

package MongoDB::Admin;
our $VERSION = '0.03';

use Any::Moose;
use MongoDB;

sub BUILD {
    my ($self) = @_;
}

has connection => (
    is       => 'ro',
    isa      => 'MongoDB::Connection',
    required => 1,
);

=head1 NAME

MongoDB::Admin - A collection of MongoDB administrative functions

=head1 SYNOPSIS

    use MongoDB;
    use MongoDB::Admin;

    my $connection = MongoDB::Connection->new(host => 'localhost', port => 27017);
    my $admin = MongoDB::Admin->new('connection' => $connection);

    my $ops = $admin->current_op();
    my $locked = $admin->fsync_lock_check();
    $admin->fsync_lock();
    $admin->fsync_unlock();

    $admin->killOp($opid);


=head1 METHODS

=cut
=head2 current_op()

    my $result = $database->current_op()

Print out the current operations running on the MongoDB server. akin to 
db.currentOp() at the mongo shell

=cut
sub current_op {
    my ($self) = @_;
    return $self->{connection}->get_database('local')->get_collection('$cmd.sys.inprog')->find_one();
}

=head2 fsync_lock_check()

    my $result = $conn->fsync_lock_check()

Checks if a fsync lock is in place, returning 1 if present, 0 otherwise.

=cut

sub fsync_lock_check {
    my ($self) = @_;

    my $result = $self->current_op();
    if(exists($result->{fsyncLock}) && $result->{fsyncLock} == 1) {
        return 1;
    } else {
        return 0;
    }
}

=head2 fsync_lock()

    my $result = $conn->fsync_lock()

Force a fsync and then lock the database to write operations, does nothing if
writes are already locked.

=cut

sub fsync_lock {
    my ($self) = @_;
    $self->fsync_lock_check() or
        $self->{connection}->get_database('admin')->run_command(Tie::IxHash->new('fsync' => 1, 'lock' => 1));
    return 1;
}

=head2 unlock()

    my $result = $conn->unlock()

Unlock's MongoDB from a prior fsync_lock operation.

=cut

sub unlock {
    my ($self) = @_;
    my $result = $self->{connection}->get_database('admin')->get_collection('$cmd.sys.unlock')->find_one();
    if(exists($result->{'ok'}) && $result->{'ok'} == 1) {
        return 1;
    }
    return 0;
}

=head2 killOp()

    my $result = $conn->killOp($opid)

Kill MongoDB Query with opid $opid

=cut

sub killOp {
    my ($self, $opid) = @_;
    my $result = $self->{connection}->get_database('admin')->get_collection('$cmd.sys.killop')->find_one(Tie::IxHash->new('op' => $opid));
    if(exists($result->{'info'}) && $result->{'info'} eq 'attempting to kill op') {
        return 1;
    }
    return 0;
}


=head2 serverStatus()

    my $result = $conn->serverStatus()

Return the MongoDB server status detail

=cut

sub serverStatus {
    my ($self) = @_;    
    my $result = $self->{connection}->get_database('admin')->get_collection('$cmd')->find_one(Tie::IxHash->new('serverStatus' => 1));
    if(exists($result->{'ok'}) && $result->{'ok'} == 1) {
        return $result;
    }
    return undef;
}


=head2 stats($db)

    my $result = $conn->stats($db)

Return the stats detail for the database named $db

=cut
sub stats {
    my ($self, $db) = @_; 
    $db = 'admin' unless(defined($db));
    my $result = $self->{connection}->get_database($db)->get_collection('$cmd')->find_one(Tie::IxHash->new('dbstats' => 1));
    if(exists($result->{'ok'}) && $result->{'ok'} == 1) {
        return $result;
    }
    return undef;
}

=head2 serverBuildInfo()

    my $result = $conn->serverBuildInfo()
    print $result->{version};

Return the MongoDB server build info.

=cut

sub serverBuildInfo {
    my ($self) = @_;
    my $result = $self->{connection}->get_database('admin')->get_collection('$cmd')->find_one(Tie::IxHash->new('buildinfo' => 1));
    if(exists($result->{'ok'}) && $result->{'ok'} == 1) {
        return $result;
    }
    return undef;
}

=head2 version()

    my $result = $conn->version()

Return the MongoDB server version.

=cut
sub version {
    my ($self) = @_;
    my $result = $self->{connection}->get_database('admin')->get_collection('$cmd')->find_one(Tie::IxHash->new('buildinfo' => 1));
    if(exists($result->{'ok'}) && exists($result->{'version'}) && $result->{'ok'} == 1) {
        return $result->{'version'};
    }
    return undef; 
}

# Replicaset Commands


=head2 rs_status()

    my $result = $conn->rs_status()

Return the replica set status.

=cut
sub rs_status {
    my ($self) = @_;
    my $result = $self->{connection}->get_database('admin')->get_collection('$cmd')->find_one(Tie::IxHash->new('replSetGetStatus' => 1));
    if(exists($result->{'ok'}) && $result->{'ok'} == 1) {
        return $result;
    }
    return undef;
}

=head2 rs_stepDown([$secs])

    my $result = $conn->rs_stepDown()

Step down as the master server, 60 second duration for new election on default.

=cut
sub rs_stepDown {
    my ($self, $secs) = @_;
    $secs = 60 unless(defined($secs));
    my $result = $self->{connection}->get_database('admin')->get_collection('$cmd')->find_one(Tie::IxHash->new('replSetStepDown' => $secs));
    if(exists($result->{'ok'}) && $result->{'ok'} == 1) {
        return $result;
    }
    warn $result->{'errmsg'};
    return undef;
}

=head2 rs_freeze([$secs])

    my $result = $conn->rs_freeze()

Freeze the replica member from becoming the new master for $secs seconds, or 60 seconds if undefined.

=cut

sub rs_freeze {
    my ($self, $secs) = @_;
    $secs = 60 unless(defined($secs));
    my $result = $self->{connection}->get_database('admin')->get_collection('$cmd')->find_one(Tie::IxHash->new('replSetFreeze' => $secs));
    if(exists($result->{'ok'}) && $result->{'ok'} == 1) {
        return $result;
    }
    warn $result->{'errmsg'};
    return undef;
}

=head2 rs_conf()

    my $result = $conn->rs_conf()

Return the replica set config

=cut

sub rs_conf {
    my ($self) = @_;
    my $result = $self->{connection}->get_database('local')->get_collection('system.replset')->find_one();
    return $result;
}

no Any::Moose;
__PACKAGE__->meta->make_immutable;

1;

=head1 AUTHOR

  David Burley <david@geek.net>

