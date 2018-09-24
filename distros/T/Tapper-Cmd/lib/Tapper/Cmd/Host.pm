package Tapper::Cmd::Host;
our $AUTHORITY = 'cpan:TAPPER';
$Tapper::Cmd::Host::VERSION = '5.0.9';
use Moose;

use Tapper::Model 'model';
use YAML::Syck;
use 5.010;

use parent 'Tapper::Cmd';



sub add
{
        my ($self, $data) = @_;
        if (not ref($data) eq 'HASH') {
                die "Wrong data format, expected hash ref, got ",ref $data;
        }
        if ($data->{pool_count}) {
                die "pool_count can not go together with pool_free" if $data->{pool_free};
                $data->{pool_free} = $data->{pool_count};
        }
        my $host_r = Tapper::Model::model()->resultset('Host')->search({name => $data->{name}}, {rows => 1})->first;
        if ($host_r) {
                $host_r->is_deleted(0);
                $host_r->update;
        } else {
                $host_r = model('TestrunDB')->resultset('Host')->new($data)->insert;
        }
        return $host_r->id;

}



sub del
{
        my ($self, $id) = @_;
        my $host;
        if ($id =~ /^\d+$/) {
                $host = model('TestrunDB')->resultset('Host')->find($id);
        } else {
                $host = model('TestrunDB')->resultset('Host')->find({name => $id});
        }
        die qq(Host "$id" not found) if not $host;;
        $host->is_deleted(1);
        $host->active(0);
        $host->free(0);
        $host->update;
        return 0;
}


sub update
{
}


sub list
{
        my ($self, $filter, $order) = @_;
        my %options= (order_by => 'name');
        my %search;

        for my $key ('free', 'active') {
                $search{$key} = $filter->{$key} if defined $filter->{$key};
        }
        $search{is_deleted} = {-in => [ 0, undef ] } unless $filter->{deleted};
        $search{is_pool} = { not => undef } if $filter->{pool};

        # ignore all filterions if host is requested by name
        %search = (name   => $filter->{name}) if $filter->{name};

        if ($filter->{queue}) {
                my @queue_ids       = map {$_->id} model('TestrunDB')->resultset('Queue')->search({name => {-in => $filter->{queue}}});
                $search{queue_id}   = { -in => [ @queue_ids ]};
                $options{join}      = 'queuehosts';
                $options{'+select'} = 'queuehosts.queue_id';
                $options{'+as'}     = 'queue_id';
        }
        my $hosts = model('TestrunDB')->resultset('Host')->search(\%search, \%options);
        return $hosts;
}

1; # End of Tapper::Cmd::Testrun

__END__

=pod

=encoding UTF-8

=head1 NAME

Tapper::Cmd::Host

=head1 SYNOPSIS

This project offers backend functions for all projects that manipulate
hosts in the database.

    use Tapper::Cmd::Host;

    my $host = Tapper::Cmd::Host->new();
    my $details = { name  => 'einstein',
                    queue => ['queue-one', 'queue-two'],
                    active => 1,
              };
    my $id = $host->add($details);
    $details->{name} = "bohr";
    my $error = $host->update($id, $details);
    $error = $host->delete($id);

=head1 NAME

Tapper::Cmd::Host - Backend functions for manipluation of hosts in the database

=head1 FUNCTIONS

=head2 add

Add a new host. Expects all details as a hash reference.

@param hash ref  - host data
* name        - host name
* comment     - comment for host
* free        - is the host free to have tests running on it?
* active      - is host activated?
* is_deleted  - is host deleted?
* pool_free   - set number of pool elements, not allowed together with pool_count
* pool_count  - set number of pool elements, not allowed together with pool_free

@return success - host id
@return error   - undef

@throws die()

=head2 del

Delete a host with given id. Its named del instead of delete to prevent
confusion with the buildin delete function. The first parameter can be
either the host id or the host name.

@param int|string - host id|host name

@return success - 0

@throws die

=head2 update

Update a given host with new data.

=head2 list

Get a filtered list of hosts.

@param hash ref - filters
allowed keys:
* free    - bool            - filter for free/non-free hosts
* name    - list of strings - filter for host names
* active  - bool            - filter for active/non-active hosts
* queue   - list of strings - filter for hosts bound to this queue
* pool    - bool            - filter for pool hosts
* deleted - bool            - allowed deleted hosts too

@return success - Host resultset - DBIx::Class list of hosts

@throws die

=head1 AUTHORS

=over 4

=item *

AMD OSRC Tapper Team <tapper@amd64.org>

=item *

Tapper Team <tapper-ops@amazon.com>

=back

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Advanced Micro Devices, Inc..

This is free software, licensed under:

  The (two-clause) FreeBSD License

=cut
