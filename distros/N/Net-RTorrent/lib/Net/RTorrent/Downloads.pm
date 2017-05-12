#$Id: Downloads.pm 805 2010-07-05 13:20:49Z zag $

package Net::RTorrent::Downloads;

use strict;
use warnings;
use Carp;
use Data::Dumper;
use Collection;
use Net::RTorrent::DItem;
use constant {
    D_ATTRIBUTES => [
        'd.get_hash='               => 'hash',
        'd.get_base_filename='      => 'base_filename',
        'd.get_base_path='          => 'base_path',
        'd.get_bytes_done='         => 'bytes_done',
        'd.get_chunk_size='         => 'chunk_size',
        'd.get_chunks_hashed='      => 'chunks_hashed',
        'd.get_complete='           => 'complete',
        'd.get_completed_bytes='    => 'completed_bytes',
        'd.get_completed_chunks='   => 'completed_chunks',
        'd.get_connection_current=' => 'connection_current',
        'd.get_connection_leech='   => 'connection_leech',
        'd.get_connection_seed='    => 'connection_seed',
        'd.get_creation_date='      => 'creation_date',

        'd.get_directory='           => 'directory',
        'd.get_down_rate='           => 'down_rate',
        'd.get_down_total='          => 'down_total',
        'd.get_free_diskspace='      => 'free_diskspace',
        'd.get_hashing='             => 'hashing',
        'd.get_ignore_commands='     => 'ignore_commands',
        'd.get_left_bytes='          => 'left_bytes',
        'd.get_local_id='            => 'local_id',
        'd.get_local_id_html='       => 'local_id_html',
        'd.get_max_file_size='       => 'max_file_size',
#        'd.get_max_peers='           => 'max_peers', 
        'd.get_max_size_pex='        => 'max_size_pex',
#        'd.get_max_uploads='         => 'max_uploads',
        'd.get_message='             => 'message',
#        'd.get_min_peers='           => 'min_peers',
        'd.get_name='                => 'name',
        'd.get_peer_exchange='       => 'peer_exchange',
        'd.get_peers_accounted='     => 'peers_accounted',
        'd.get_peers_complete='      => 'peers_complete',
        'd.get_peers_connected='     => 'peers_connected',
        'd.get_peers_max='           => 'peers_max',
        'd.get_peers_min='           => 'peers_min',
        'd.get_peers_not_connected=' => 'peers_not_connected',
        'd.get_priority='            => 'priority',
        'd.get_priority_str='        => 'priority_str',
        'd.get_ratio='               => 'ratio',
        'd.get_size_bytes='          => 'size_bytes',
        'd.get_size_chunks='         => 'size_chunks',
        'd.get_size_files='          => 'size_files',
        'd.get_size_pex='            => 'size_pex',
        'd.get_skip_rate='           => 'skip_rate',
        'd.get_skip_total='          => 'skip_total',
        'd.get_state='               => 'state',
        'd.get_state_changed='       => 'state_changed',
        'd.get_tied_to_file='        => 'tied_to_file',
        'd.get_tracker_focus='       => 'tracker_focus',
        'd.get_tracker_numwant='     => 'tracker_numwant',
        'd.get_tracker_size='        => 'tracker_size',
        'd.get_up_rate='             => 'up_rate',
        'd.get_up_total='            => 'up_total',
        'd.get_uploads_max='         => 'uploads_max',
        'd.get_custom2='             => 'custom2',
        'd.is_active='               => 'is_active',
        'd.is_open='                 => 'is_open'
    ]
};

use 5.005;
our @ISA     = qw(Collection);
our $VERSION = '0.01';
my $attrs = { _cli => undef, _view => 'default' };
### install get/set accessors for this object.
for my $key ( keys %$attrs ) {
    no strict 'refs';
    *{ __PACKAGE__ . "::$key" } = sub {
        my $self = shift;
        $self->{$key} = $_[0] if @_;
        return $self->{$key};
      }
}

sub _init {
    my $self = shift;
    $self->_cli(shift);
    if ( my $view_name = shift ) {
        $self->_view($view_name);
    }
    return $self->SUPER::_init(@_);
}

=head2 delete (<info_hash1>[, <info_hash2> ... ])

Call d.erase on I<info_hashes>.

return { <info_hashes> => <xml-rpc response value> }

=cut

sub _delete {
    my $self = shift;
    my (@ids) = map { ref($_) ? $_->{id} : $_ } @_;
    my %res = ();
    for (@ids) {
        my $resp = $self->_cli->send_request( 'd.erase', $_ );
        if ( ref $resp ) {
            $res{$_} = $resp->value;
        }
    }
    return \%res;
}

sub _fetch {
    my $self = shift;
    my @ids =  @_;
    my ( @methods, @attr_names ) = ();
    my $r         = D_ATTRIBUTES;
    my @meth2attr = @{$r};
    while ( my ( $method, $attr_name ) = splice @meth2attr, 0, 2 ) {
        push @methods,    $method;
        push @attr_names, $attr_name;
    }
    my $cli  = $self->_cli;
    my $resp =
      $cli->send_request( 'd.multicall', $self->_view || "default", @methods );
    if ( ref $resp ) {
        my $res    = $resp->value;
        my %result = ();
        foreach my $rec (@$res) {
            my %attr;
            @attr{@attr_names} = @$rec;
            my $id = $attr{hash};
            $result{$id} = \%attr;
        }
        return \%result;
    }
    return {};
}

=head2 fetch_one <info_hash>

Return L<Net::RTorrent::DItem> object for given I<info_hash>.

Or undef if I<info_hash> not exists.

=cut

sub fetch_one {
    my $self = shift;
    my ($obj) = values %{ $self->fetch(@_) };
    $obj;
}

=head2 fetch <info_hash1>[, <info_hash2> ... ]

Return info about torrents for given I<info_hashes>.

Result: ref to hash of L<Net::RTorrent::DItem> objects

=cut

sub fetch {
    my $self = shift;
    my @ids  = @_;
    unless ( scalar @_ ) {
       @ids = @{$self->list_ids}
    }
    my $res  = $self->SUPER::fetch(@ids);
    my %res  = ();
    foreach my $key (@ids) {
        $res{$key} = $res->{$key} if exists $res->{$key};
    }
    return \%res;
}


sub list_ids {
    my $self = shift;
    my $cli  = $self->_cli;
    my $resp = $cli->send_request('download_list',shift || $self->_view ||  "default");
    return ref($resp) ? $resp->value : [];
}

=head2 start <info_hash1>[, <info_hash2> ... ]

Start torrents

=cut

sub start {
    my $self = shift;
    my $cli  = $self->_cli;
    my %res = ();
    for (@_) {
        my $resp = $self->_cli->send_request( 'd.start', $_ );
        if ( ref $resp ) {
            $res{$_} = $resp->value;
        }
    }
    return \%res;
}

=head2 stop <info_hash1>[, <info_hash2> ... ]

Stop torrents

=cut

sub stop {
    my $self = shift;
    my $cli  = $self->_cli;
    my %res = ();
    for (@_) {
        my $resp = $self->_cli->send_request( 'd.stop', $_ );
        if ( ref $resp ) {
            $res{$_} = $resp->value;
        }
    }
    return \%res;
}

sub _prepare_record {
    my $self = shift;
    my ( $key, $ref ) = @_;
    return new Net::RTorrent::DItem:: $ref, $self->_cli;
}

1;
__END__

=head1 NAME

Net::RTorrent::Downloads - collection of downloads

=head1 SYNOPSIS

  my $obj =  new Net::RTorrent:: 'http://10.100.0.1:8080/scgitest';
  my $dloads = $obj->get_downloads('');

=head1 ABSTRACT
 
Net::RTorrent::Downloads - collection of downloads


=head1 DESCRIPTION

Net::RTorrent::Downloads - collection of downloads

=head1 SEE ALSO

Collections

=head1 AUTHOR

Zahatski Aliaksandr, E<lt>zag@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2008-2009 by Zahatski Aliaksandr

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
