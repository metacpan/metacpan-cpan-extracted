#$Id: RTorrent.pm 938 2011-04-05 07:12:53Z zag $

package Net::RTorrent;

use strict;
use warnings;
use RPC::XML;
use RPC::XML::Client;
use Net::RTorrent::Downloads;
use Net::RTorrent::Socket;
use Collection;
our @ISA     = ();
use Carp;
use 5.005;

=head1 NAME

Net::RTorrent - Perl interface to rtorrent via XML-RPC.

=head1 SYNOPSIS

  #from http scgi gate
  my $obj =  new Net::RTorrent:: 'http://10.100.0.1:8080/scgitest';
  #from network address
  my $obj =  new Net::RTorrent:: '10.100.0.1:5000';
  #from UNIX socket
  my $obj =  new Net::RTorrent:: '/tmp/rtorrent.sock';
  
  #get completed torrents list
  my $dloads = $obj->get_downloads('complete');
  #get all torrents list
  my $dloads = $obj->get_downloads();
  #get stopped torrents list
  my $dloads = $obj->get_downloads('stopped');
  
  #fetch all items
  $dloads->fetch()
  #or by hash_info
  $dloads->fetch_one('02DE69B09364A355F71279FC8825ADB0AC8C3A29')
  #list oll hash_info
  my $keys = $dloads->list_ids;
  #upload remotely
  $obj->create( $torrent_raw );
  $obj->create( $data, 0 );

=head1 ABSTRACT
 
Perl interface to rtorrent via XML-RPC

=head1 DESCRIPTION

Net::RTorrent - short way to create tools for rtorrent.

=cut

use constant {
    #info atributes for system info
    S_ATTRIBUTES => [
        'get_download_rate'    => 'download_rate',    #in my version dosn't work
        'get_memory_usage'     => 'memory_usage',
        'get_max_memory_usage' => 'max_memory_usage',
        'get_name'             => 'name',
        'get_safe_free_diskspace' => 'safe_free_diskspace',
        'get_upload_rate'         => 'upload_rate',
        'system.client_version'   => 'client_version',
        'system.hostname'         => 'hostname',
        'system.library_version'  => 'library_version',
        'system.pid'              => 'pid',
    ],
};

our $VERSION = '0.11';
my $attrs = {
    _cli       => undef,
};
### install get/set accessors for this object.
for my $key ( keys %$attrs ) {
    no strict 'refs';
    *{ __PACKAGE__ . "::$key" } = sub {
        my $self = shift;
        $self->{$key} = $_[0] if @_;
        return $self->{$key};
      }
}

=head1 METHODS

=cut

=head2 new URL

Creates a new client object that will route its requests to the URL provided. 

=cut

sub new {
    my $class = shift;
    $class = ref $class if ref $class;
    my $self = bless( {}, $class );
    if (@_) {
        my $rpc_url = shift;
        my $cli_class  = $rpc_url =~m%\w+://% ? 'RPC::XML::Client': 'Net::RTorrent::Socket';
        $self->_cli( $cli_class->new($rpc_url) );

    }
    else {
        carp "need xmlrpc server URL";
        return;
    }
    return $self;
}

=head2 create \$raw_data || new IO::File , [ start_now=>1||0 ],[ tag=><string>]

Load torrent from file descriptor or scalar ref.

Params:

=over 2 

=item start_now  - start torent now

1 - start download now (default)

0 - not start download

=item tag - save <string> to rtorrent

For read tag value use:

    $ditem->tag

=back

=cut

sub create {
    my $self = shift;
    my $res = $self->load_raw(@_);
    return $res
}


sub load_raw {
    my $self = shift;
    my ( $raw, %flg ) = @_;
    $flg{start_now} = 1 unless defined $flg{start_now};
    my $command = $flg{start_now} ? 'load_raw_start' : 'load_raw';
    my @add =();
    push @add, "d.set_custom2=$flg{tag}" if exists $flg{tag};
    return $self->_cli->send_request( $command, RPC::XML::base64->new($raw), @add );
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



=head2 list_ids ( [ <name of view> ])

Return list of rtorrent I<info_hashes> for I<name of view>.
An empty string for I<name of view> equals "default".

To get list of views names :

    xmlrpc http://10.100.0.1:8080/scgitest view_list

  'main'
  'default'
  'name'
  'started'
  'stopped'
  'complete'
  'incomplete'
  'hashing'
  'seeding'
  'scheduler'

=cut

sub list_ids {
    my $self = shift;
    my $cli  = $self->_cli;
    my $resp = $cli->send_request('download_list',shift ||"default");
    return ref($resp) ? $resp->value : [];
}


=head2 get_downloads [ <view name > || 'default']

Return collection of downloads (L< Net::RTorrent::Downloads>).

To get list of view:

    xmlrpc http://10.100.0.1:8080/scgitest view_list

  'main'
  'default'
  'name'
  'started'
  'stopped'
  'complete'
  'incomplete'
  'hashing'
  'seeding'
  'scheduler'

=cut

sub get_downloads {
    my $self = shift;
    my $view = shift;
    return new Net::RTorrent::Downloads:: $self->_cli, $view;
}

=head2 system_stat 

Return system stat.

For example:

    print Dumper $obj->system_stat;

Return:

        {
           'library_version' => '0.11.9',
           'max_memory_usage' => '-858993460', #  at my amd64
           'upload_rate' => '0',
           'name' => 'gate.home.zg:1378',
           'memory_usage' => '115867648',
           'download_rate' => '0',
           'hostname' => 'gate.home.zg',
           'pid' => '1378',
           'client_version' => '0.7.9',
           'safe_free_diskspace' => '652738560'
         };

=cut

sub system_stat {
    my $self  = shift;
    my $comms = S_ATTRIBUTES;
    my @list  = @{$comms};
    my ( @res_pull, @cmd_pull ) = ();
    while ( my ( $mname, $aname ) = splice( @list, 0, 2 ) ) {
        push @res_pull, $aname;
        push @cmd_pull, $mname => [];
    }
    my $call_res = $self->do_sys_mutlicall(@cmd_pull);
    my %res      = ();
    while ( my $tmp_res = shift @$call_res ) {
        my $attr_name = shift @res_pull;
        $res{$attr_name} = defined $tmp_res->[1] ? $tmp_res : $tmp_res->[0];
    }
    return \%res

}

=head2 do_sys_mutlicall 'method1' =>[ <param1>, .. ], ...

Do XML::RPC I<system.multicall>. Return ref to ARRAY of results

For sample.

 print Dumper $obj->do_sys_mutlicall('system.pid'=>[], 'system.hostname'=>[]);

Will return:

    [
           [
             '1378'
           ],
           [
             'gate.home.zg'
          ]
    ];

=cut

sub do_sys_mutlicall {
    my $self    = shift;
    my $res     = [];
    my @methods = ();
    while ( my ( $method, $param ) = splice( @_, 0, 2 ) ) {
        push @methods, { methodName => $method, params => $param },;
    }
    if (@methods) {
        my $resp =
          $self->_cli->send_request(
            new RPC::XML::request::( 'system.multicall', \@methods ) );
        $res = $resp->value;
    }
    return $res;
}

1;
__END__

=head1 Setting up rtorrent

If you are compiling from rtorrent's source code, this is done during the configuration step by adding the flag --with-xmlrpc-c to the configure step. Example ./configure --with-xmlrpc-c. See L<http://libtorrent.rakshasa.no/wiki/RTorrentXMLRPCGuide>

Setup your rtorrent  and Web server. My tips:

=head3 .rtorrent

   scgi_port = 10.100.0.1:5000 
   #for complete erase
   on_erase = erase_complete,"execute=rm,-rf,$d.get_base_path="
   #or for save backup 
   on_erase = move_complete,"execute=mv,-n,$d.get_base_path=,~/erased/ ;d.set_directory=~/erased"

=head3 apache.conf

    LoadModule scgi_module        libexec/apache2/mod_scgi.so
    <IfModule  mod_scgi.c>
      SCGIMount /scgitest 10.100.0.1:5000
      <Location "/scgitest">
         SCGIHandler On
      </Location>
    </IfModule>

My url for XML::RPC is L<http://10.100.0.1:8080/scgitest>.

Use B<xmlrpc> ( L<http://xmlrpc-c.sourceforge.net/> ) for tests:

    xmlrpc http://10.100.0.1:8080/scgitest system.listMethods


=head1 SEE ALSO

Net::RTorrent::DItem, Net::RTorrent::Downloads, L<http://libtorrent.rakshasa.no/wiki/RTorrentXMLRPCGuide>

=head1 AUTHOR

Zahatski Aliaksandr, E<lt>zag@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2008-2009 by Zahatski Aliaksandr

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
