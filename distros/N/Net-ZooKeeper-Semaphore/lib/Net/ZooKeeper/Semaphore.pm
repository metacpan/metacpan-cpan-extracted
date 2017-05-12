package Net::ZooKeeper::Semaphore;

# ABSTRACT: Distributed semaphores via Apache ZooKeeper

=head1 NAME

Net::ZooKeeper::Semaphore

=head1 DESCRIPTION

Distributed semaphores via Apache ZooKeeper

=head1 SYNOPSIS

    my $fqdn = Sys::Hostname::FQDN::fqdn();
    my $zkh = Net::ZooKeeper->new(...);

    my $cpu_semaphore = Net::ZooKeeper::Semaphore->new(
        count => 1,
        path => "/semaphores/${fqdn}_cpu",
        total => Sys::CPU::cpu_count(),
        zkh => $zkh,
    );

    my %mem_info = Linux::MemInfo::get_mem_info();
    my $mem_semaphore = Net::ZooKeeper::Semaphore->new(
        count => 4E6, # 4GB
        data => $$,
        path => "/semaphores/${fqdn}_mem",
        total => $mem_info{MemTotal},
        zkh => $zkh,
    );

    undef $cpu_semaphore; # to delete lease

=cut

use strict;
use warnings;

our $VERSION = 0.02;

use Carp;
use Net::ZooKeeper qw/:acls :node_flags/;
use Net::ZooKeeper::Lock;
use Params::Validate qw/:all/;

=head1 METHODS

=head2 new(%options)

Object creation doesn't block.
Undef is returned if it isn't possible to acquire a lease.
An exception is raised on any ZooKeeper errors.
A lease is held as long as the object lives.

Parameters:

=item count

Resource amount to be leased.
Must be an integer (negative values are to be added to total).

=item data

Optional. Data for lease znode.
Must be a string, default is '0'.

=item path

Path in ZooKeeper that identifies the semaphore.
If it doesn't exist, it will be created.
Also path/lock and path/leases will be created.

=item total

Total amount of available resource.
If there are any active leases for the given path that were created with a
different total, an exception will be raised.

=item zkh

Net::ZooKeeper handle object

=cut

sub new {
    my $class = shift;
    my $self = validate(@_, {
        count => {type => SCALAR, regex => qr/^-?\d+$/o},
        data => {default => '0'},
        path => {type => SCALAR},
        total => {type => SCALAR, regex => qr/^\d+$/o},
        zkh => {isa => "Net::ZooKeeper"},
    });
    $self->{path} =~ s#/$##g;

    bless $self, $class;

    if ($self->_acquire) {
        return $self;
    } else {
        return undef;
    }
}


sub DESTROY {
    my $self = shift;

    if ($self->{lease_path}) {
        $self->{zkh}->delete($self->{lease_path});
    }
}


sub _acquire {
    my $self = shift;

    my $lock = Net::ZooKeeper::Lock->new(
        data => $self->{data},
        lock_name => "acquire",
        lock_prefix => "$self->{path}/lock",
        zkh => $self->{zkh},
    );
    if ($lock) {
        my $leases_path = "$self->{path}/leases";
        unless ($self->{zkh}->exists($leases_path)) {
            $self->_create_path($leases_path);
        }
        my @leases = $self->{zkh}->get_children($leases_path);
        my $sum = 0;
        for my $lease (@leases) {
            my ($count, $total, undef) = split /_/, $lease, 3; # count_total_seq
            if ($total != $self->{total}) {
                croak "Totals mismatch: $leases_path/$lease $self->{total}";
            }
            $sum += $count;
        }
        if ($sum + $self->{count} <= $self->{total}) {
            my $lease_tmpl = "$leases_path/$self->{count}_$self->{total}_";
            $self->{lease_path} = $self->{zkh}->create($lease_tmpl, $self->{data},
                acl   => ZOO_OPEN_ACL_UNSAFE,
                flags => (ZOO_EPHEMERAL | ZOO_SEQUENCE),
            ) or croak "unable to create sequence znode $lease_tmpl: ".$self->{zkh}->get_error;
            $lock->unlock;
            return 1;
        }
    }
    return 0;
}


sub _create_path {
    my ($self, $path) = @_;

    my $current_index = 1;
    while ($current_index > 0) {
        $current_index = index($path, "/", $current_index + 1);
        my $current_path;
        if ($current_index > 0) {
            $current_path = substr($path, 0, $current_index);
        } else {
            $current_path = $path;
        }

        if (!$self->{zkh}->exists($current_path)) {
            $self->{zkh}->create($current_path, '0',
                acl => ZOO_OPEN_ACL_UNSAFE,
            );
        }
    }
}

1;

__END__

=head1 AUTHOR

  Oleg Komarov <komarov@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Yandex LLC.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
