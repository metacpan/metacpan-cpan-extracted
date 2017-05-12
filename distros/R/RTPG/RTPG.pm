#!/usr/bin/perl

use utf8;
use strict;
use warnings;
package RTPG;
use Carp;
use POSIX qw(strftime);
use RTPG::Direct;
use RPC::XML::Client;
use RPC::XML;
use MIME::Types;

use Fcntl qw(:flock);

# international symbols in our commands
$RPC::XML::ENCODING = "UTF-8";

my $SIZE_BY_CHUNKS_LIMIT=1024**3;

=head1 NAME

RTPG - is a module for accessing to rtorrent's SCGI functions.

=head1 VERSION

0.92

=cut

our $VERSION=0.92;

=head1 SYNOPSIS

 use RTPG;

 # standard variant
 my $h = new RTPG(url=>'http://localhost/RPC2');

 # direct connection to rtorrent
 my $h = new RTPG(url=>'localhost:5000');
 my $h = new RTPG(url=>'/path/to/socket.rtorrent');

 # arrayref and error (standard version)
 my ($tlist, $error)=$h->torrents_list;

 # arrayref (died version)
 my $tlist=$h->torrents_list;

 for (@$tlist)
 {
     my $file_list=$h->file_list($_->{hash});
     ..
 }


 # direct commands by RPC
 my $list_methods=$h->rpc_command('system.listMethods');
 my ($list_methods, $error)=$h->rpc_command('system.listMethods');

 # system information (library versions, etc)
 my $hashref=$h->system_information;
 my ($hashref, $error)=$h->system_information;

=head1 METHODS


=head2 new

The constructor. It receives the next options:

=over

=item B<url>

is an address of rtorrent's SCGI (direct) or rtorrent's RPC (standard).

=item B<queue>

if TRUE, commands will process in queue mode (use flock).

=back

=cut

sub new
{
    my ($class, %opts)=@_;
    croak 'XMLRPC url must be defined' unless exists $opts{url};

    # XML::RPC::Client (standard variant)
    if ($opts{url} =~ m{^\w+://})
    {
        my $connect=RPC::XML::Client->new($opts{url});
        unless (ref $connect)
        {
            $!="Error connect to XMLRPC-server: $connect\n";
            return undef;
        }

        return bless {
            standard            =>  1,
            rtorrent_ctl_url    =>  $opts{url},
            connection          =>  $connect,
            queue_mode          =>  $opts{queue} || 0,
        }, $class;
    }

    my $connect=RTPG::Direct->new(url => $opts{url});
    return bless {
        standard            => 0,
        rtorrent_ctl_url    => $opts{url},
        connection          => $connect,
        queue_mode          => $opts{queue} || 0,
    };
}

=head2 rpc_command(CMD[,ARGS])

You can use this method for send commands to rtorrent.

=head3 EXAMPLE

 # standard version
 my ($result, $error)=$h->rpc_command('system.listMethods');

 # died version
 my $result=$h->rpc_command('system.listMethods');

=cut

sub rpc_command
{
    my $self=shift;
    my ($cmd, @args)=@_;
    my $resp;

    flock DATA, LOCK_EX if $self->{queue_mode};
    $resp=$self->{connection}->send_request($cmd, @args);
    flock DATA, LOCK_UN if $self->{queue_mode};

    if (ref $resp)
    {
        if ('RPC::XML::fault' eq ref $resp)
        {
            my $err_str=sprintf
                "Fault when execute command: %s\n" .
                "Fault code: %s\n" .
                "Fault text: %s\n",
                join(' ', $cmd, @args),
                $resp->value->{faultString},
                $resp->value->{faultCode};
            die $err_str unless wantarray;
            return (undef, $err_str);
        }
        return $resp->value unless wantarray;
        return $resp->value, '';
    }
    my $err_str=sprintf
        "Fault when execute command: %s\n" .
        "Fault text: %s\n",
        join(' ', $cmd, @args),
        $resp||'';
    die $err_str unless wantarray;
    return undef, $err_str;
}

=head2 torrents_list([VIEW])

This method returns list of torrents. It is a link to array of hashes.

=head3 EXAMPLE

 # standard version
 my ($tlist, $err)=$h->torrents_list;
 my ($tlist, $err)=$h->torrents_list('started');

 # died version
 my $tlist=$h->torrents_list;
 my $tlist=$h->torrents_list('started');

=head3 views variants

=over

=item default

=item name

=item stopped

=item started

=item complete

=item incomplete

=back

=cut

our $exclude_d_mask = qr{^d\.(get_mode|get_custom.*|get_bitfield)$};

sub torrents_list
{
    my ($self, $view)=@_;
    $view||='default';


    my @iary=eval {
        grep !/$exclude_d_mask/,
        grep /^d\.(get_|is_|views\.has$)/, $self->_get_list_methods;
    };

    if ($@)
    {
        return undef, "$@" if wantarray;
        die $@;
    }
    my ($list, $error) =
        $self->rpc_command('d.multicall', $view, map { "$_=" } @iary);

    unless (defined $list)
    {
        die $error unless wantarray;
        return undef, $error;
    }

    for (@$list)
    {
        my %info;
        for my $i (0 .. $#iary)
        {
            my $name=$iary[$i];
            $name =~ s/^..(?:get_)?//;
            $info{$name}=$_->[$i];
        }

        # Set download status
        if( $info{hashing} )
        {
            $info{status} = 'hashing';
        }
        elsif( $info{complete} )
        {
            if($info{is_active})
            {
                $info{status} = 'seeding';
            }
            else
            {
                $info{status} = 'finished';
            }
        }
        else
        {
            if($info{is_active})
            {
                $info{status} = 'downloading';
            }
            else
            {
                $info{status} = 'paused';
            }
        }

        $_ = _normalize_one_torrent_info(\%info);
    }
    return $list unless wantarray;
    return $list, '';
}

=head2 torrent_info(tid)

The method returns the link to hash which contains the information about
the torrent (tid);

=head3 EXAMPLE

 my $tlist = $h->torrents_list;
 my $tinfo_first = $tlist->[0];
 my $tinfo_first_second_time
    = $h->torrent_info($tlist->[0]{hash});

=head4 NOTE

Hashes B<$tinfo_first> and B<$tinfo_first_second_time> are equal.
This method can use if You know torrent-id and do not know
an other information about the torrent.

 # standard version
 my ($tinfo, $error)=$h->torrent_info($tid);

 # died version
 my $tinfo=$h->torrent_info($tid);

=cut

sub torrent_info
{
    my ($self, $id)=@_;
    my @iary=eval {
        grep !/$exclude_d_mask/,
        grep /^d\.(get_|is_)/, $self->_get_list_methods;
    };
    if ($@)
    {
        return undef, "$@" if wantarray;
        die $@;
    }

    my $info={};

    eval
    {
        for my $cmd (@iary)
        {
            my $name=$cmd;
            $name=~s/^..(?:get_)?//;
            $info->{$name}=$self->rpc_command($cmd, $id);
        }
    };
    if ($@)
    {
        return undef, "$@" if wantarray;
        die $@;
    }
    return _normalize_one_torrent_info($info), '' if wantarray;
    return _normalize_one_torrent_info($info);

}

=head2 file_list(tid)

The method returns the link to array which contains information
about each file that belong to the torrent (tid).

=head3 EXAMPLE

 # standard version
 my ($files, $error)=$h->file_list($tid);

 # died version
 my $files=$h->file_list($tid);

=cut

sub file_list
{
    my ($self, $id)=@_;
    croak "TorrentID must be defined!\n" unless $id;
    my @iary=eval {
        grep /^f\.(get|is)/, $self->_get_list_methods;
    };

    if ($@)
    {
        return undef, "$@" if wantarray;
        die $@;
    }

    my ($chunk_size, $error)=$self->rpc_command('d.get_chunk_size', $id);
    unless (defined $chunk_size)
    {
        die $error unless wantarray;
        return undef, $error;
    }

    my $list;

    ($list, $error) =
        $self->rpc_command('f.multicall', $id, '', map { "$_=" } @iary);
    unless (defined $list)
    {
        die $error unless wantarray;
        return undef, $error;
    }

    my $mimetypes = MIME::Types->new;
    my $unknown   = MIME::Type->new(
        encoding    => 'base64',
        simplified  => 'unknown/unknown',
        type        => 'x-unknown/x-unknown');

    for (@$list)
    {
        my %info;
        for my $i (0 .. $#iary)
        {
            my $name=$iary[$i];
            $name =~ s/^..(?:get_)?//;
            $info{$name}=$_->[$i];
        }
        $_ =  \%info;
        my $size_bytes=1.0*$chunk_size*$_->{size_chunks};
        $_->{size_bytes}=$size_bytes if $size_bytes > $SIZE_BY_CHUNKS_LIMIT;
        $_->{priority_str} =
            ($_->{priority} == 0) ?'off'    :
            ($_->{priority} == 1) ?'normal' :
            ($_->{priority} == 2) ?'high'   :'unknown';
        $_->{percent}=_get_percent_string(
            $_->{completed_chunks},
            $_->{size_chunks}
        );
        $_->{mime} = $mimetypes->mimeTypeOf( $_->{path} ) || $unknown;
    }
    return $list, '' if wantarray;
    return $list;
}

=head2 tracker_list

The method returns information about trackers.

=cut

sub tracker_list
{
    my ($self, $tid) = @_;
    my @cmd = eval {
        grep /^t\.(?:get_|is_)/,
            $self->_get_list_methods
    };

    if ($@) {
        return undef, $@ if wantarray;
        die;
    }

    my ($r, $e) =
        $self->rpc_command('t.multicall', $tid, undef, map { "$_="  } @cmd);

    if ($e) {
        return undef, $e if wantarray;
        die $e;
    }

    @cmd = map { s/^t\.(?:get_)?//; $_ } @cmd;

    for my $t (@$r) {
        $t = { map { ($cmd[$_] => $t->[$_]) } 0 .. $#cmd };
    }

    return ($r, $e) if wantarray;
    return $r;
}

=head2 peer_list(tid)

The method returns information about peers we are connected (by torrent id).

=cut

sub peer_list
{
    my ($self, $tid) = @_;
    my @cmd = eval { grep /^p\.(?:get_|is_)/, $self->_get_list_methods };
    if ($@) {
        return undef, $@ if wantarray;
        die;
    }

    my ($list, $error) = eval {
        $self->rpc_command('p.multicall', $tid, undef, map { "$_=" } @cmd)
    };


    if ($@) {
        return undef, $@ if wantarray;
        die;
    }

    unless($error) {
        for my $item (0 .. $#{$list}) {
            my %h;
            for (0 .. $#cmd) {
                (my $name = $cmd[$_]) =~ s/^p\.(?:get_)?//;
                $h{$name} = $list->[$item][$_];
            }
            $list->[$item] = { %h };
        }
    }

    return ($list, $error) if wantarray;
    return $list unless $error;
    die $error;
}

=head2 set_files_priorities(tid, pri)

This method updates priorities of all files in one torrent

=head3 EXAMPLE

 # standard version
 my $error=$h->set_files_priorities($tid, $pri);
 my ($error)=$h->set_files_priorities($tid, $pri);

 # died version
 $h->set_files_priorities($tid, $pri);

=cut

sub set_files_priorities
{
    my ($self, $id, $pri)=@_;
    my ($list, $error) =
        $self->rpc_command('f.multicall', $id, '', "f.set_priority=$pri");
    return $error if defined wantarray;
    die $error if $error;
    return undef;
}

=head2 set_file_priority

Set file priority

=cut

sub set_file_priority
{
    my ($self, $id, $file_index, $priority) = @_;

    my ($res, $error)=
        $self->rpc_command('f.set_priority', $id, $file_index, $priority);
    unless (defined $res)
    {
        return undef, "$error" if wantarray;
        die $error;
    }

    return $res;

}

=head2 system_information

The method returns the link to hash about system information. The hash
has the fields:

=over

=item B<client_version>

the version of rtorrent.

=item B<library_version>

the version of librtorrent.

=back

=cut

sub system_information
{
    my $self = shift;

    my @info_params = qw(client_version library_version);

    my ($res, $err) = $self->rpc_command(
        'system.multicall', [
            map { { methodName => "system.$_", params => [] } } @info_params
        ]
    );

    if ($err) {
        die $err unless wantarray;
        return (undef, $err);
    }


    my %res;

    for (0 .. $#info_params) {
        $res{ $info_params[$_] } = $res->[$_][0];
    }

    return \%res, '' if wantarray;
    return \%res;
}

=head2 view_list([ARGS])

The method returns information about views in rtorrent.
There are a few additional named arguments:

=over

=item full

if TRUE, method will return additional information about view.

=back

=cut

sub view_list
{
    my ($self, %opts) = @_;

    my $info;

    eval
    {
        $info = $self->rpc_command('view_list');
    };
    if ($@)
    {
        return undef, "$@" if wantarray;
        die $@;
    }


    if ($opts{full}) {
        for (@$info) {
            my ($tl, $err) = $self->rpc_command(
                'd.multicall', $_, 'd.get_state='
            );

            if ($err) {
                return undef, $err if wantarray;
                die $err;
            }

            $_ = {
                name    => $_,
                count   => scalar(@$tl)
            }
        }
    }

    return $info;
}

=head2 start

Start torrent (tid) download

=cut

sub start
{
    my ($self, $id) = @_;

    my $res;

    eval
    {
        $res = $self->rpc_command('d.start', $id);
    };
    if ($@)
    {
        return undef, "$@" if wantarray;
        die $@;
    }

    return $res;
}

=head2 stop

Stop torrent (tid) download

=cut

sub stop
{
    my ($self, $id) = @_;

    my $res;

    eval
    {
        $res = $self->rpc_command('d.stop', $id);
    };
    if ($@)
    {
        return undef, "$@" if wantarray;
        die $@;
    }

    return $res;
}

=head2 delete

Delete torrent (tid)

=cut

sub delete
{
    my ($self, $id) = @_;

    my $res;

    eval
    {
        $res = $self->rpc_command('d.erase', $id);
    };
    if ($@)
    {
        return undef, "$@" if wantarray;
        die $@;
    }

    return $res;
}

=head2 pause

Pause torrent (tid)

=cut

sub pause
{
    my ($self, $id) = @_;

    my $res;

    eval
    {
        $res = $self->rpc_command('d.pause', $id);
    };
    if ($@)
    {
        return undef, "$@" if wantarray;
        die $@;
    }

    return $res;
}

=head2 check

Check torrent hash (tid)

=cut

sub check
{
    my ($self, $id) = @_;

    my $res;

    eval
    {
        $res = $self->rpc_command('d.check_hash', $id);
    };
    if ($@)
    {
        return undef, "$@" if wantarray;
        die $@;
    }

    return $res;
}

=head2 priority

Set torrent priority (tid, priority)

=cut

sub priority
{
    my ($self, $id, $priority) = @_;

    my $res;

    eval
    {
        $res = $self->rpc_command('d.set_priority', $id, $priority);
    };
    if ($@)
    {
        return undef, "$@" if wantarray;
        die $@;
    }

    return $res;
}

=head2 set_download_rate

Set maximum download rate for all torrents

=cut

sub set_download_rate
{
    my ($self, $rate) = @_;

    my ($res, $error)=$self->rpc_command('set_download_rate', $rate);
    unless (defined $res)
    {
        return undef, $error if wantarray;
        die $error;
    }

    return $res;
}

=head2 set_upload_rate

Set maximum upload rate for all torrents

=cut

sub set_upload_rate
{
    my ($self, $rate) = @_;

    my ($res, $error)=$self->rpc_command('set_upload_rate', $rate);
    unless (defined $res)
    {
        return undef, $error if wantarray;
        die $error;
    }

    return $res;
}

=head2 rates

Return varios current speed rates and etc.

=cut
sub rates
{
    my ($self, $param)=@_;

    my (%info, $error);

    ($info{download_rate}, $error) = $self->rpc_command('get_download_rate')
        unless $error;
    ($info{upload_rate},   $error) = $self->rpc_command('get_upload_rate')
        unless $error;

    if ($error)
    {
        return undef, $error if wantarray;
        die $error;
    }
    return \%info;
}

=head2 add

Add new torrent for download from url list or filehandle

=cut

sub add
{
    my ($self, $param) = @_;

    $param = [ $param ] unless 'ARRAY' eq ref $param;

    my ($res, $error);

    for (@$param)
    {
        if(ref $_)
        {
            local $/;
            binmode $_;
            my $torrent = RPC::XML::base64->new(<$_>);
            ($res, $error) = $self->rpc_command(load_raw => $torrent);
        }
        else
        {
            my $url = RPC::XML::base64->new($_);
            ($res, $error) = $self->rpc_command(load_verbose => $url);
        }
    }

    if ($error)
    {
        return undef, $error if wantarray;
        die $error;
    }

    return $res;
}

=head1 PRIVATE METHODS

=head2 _get_list_methods

returns list of rtorrent commands

=cut

sub _get_list_methods
{
    my $self=shift;
    return @{ $self->{listMethods} } if $self->{listMethods};
    my $list = $self->rpc_command('system.listMethods');
    return @$list;
}

=head2 _get_percent_string(PART_OF_VALUE,VALUE)

counts percent by pair values

=cut

sub _get_percent_string($$)
{
    my ($part, $full)=@_;
    return undef unless $full;
    return undef unless defined $part;
    return undef if $part<0;
    return undef if $full<0;
    return undef if $part>$full;
    my $percent=$part*100/$full;
    if ($percent<10)
    {
        $percent=sprintf '%1.2f', $percent;
    }
    else
    {
        $percent=sprintf '%1.1f', $percent;
    }
    s/(?<=\.\d)0$//, s/\.00?$// for $percent;
    return "$percent%";
}

=head2 _normalize_one_torrent_info(HASHREF)

=over

=item calculates:

percents, ratio, human_size, human_done,
human_up_total, human_up_rate, human_down_rate

=item fixes:

32bit overflow in libxmlrpc-c3 version < 1.07

=back

=cut

sub _normalize_one_torrent_info($)
{
    my ($info)=@_;

    for ($info)
    {
        $_->{percent} = _get_percent_string(
            $_->{completed_chunks},
            $_->{size_chunks}
        );

        my ($bytes_done, $size_bytes)=
        (
            1.0*$_->{completed_chunks}*$_->{chunk_size},
            1.0*$_->{size_chunks}*$_->{chunk_size}
        );
        $_->{size_bytes}=$size_bytes if $size_bytes>$SIZE_BY_CHUNKS_LIMIT;
        $_->{bytes_done}=$bytes_done if $bytes_done>$SIZE_BY_CHUNKS_LIMIT;
        $_->{up_total}=1.0*$_->{bytes_done}*($_->{ratio}/1000);


        $_->{ratio}=sprintf '%1.2f', $_->{ratio}/1000;
        $_->{ratio}=~s/((\.00)|0)$//;

#        $_->{human_size}        = as_human_size(  $_->{size_bytes} );
#        $_->{human_done}        = as_human_size(  $_->{bytes_done} );
#        $_->{human_up_total}    = as_human_size(  $_->{up_total}   );
#        $_->{human_up_rate}     = as_human_speed( $_->{up_rate}    );
#        $_->{human_down_rate}   = as_human_speed( $_->{down_rate}  );
    }
    return $info;
}

=head2 as_human_size(NUM)

converts big numbers to small 1024 = 1K, 1024**2 == 1M, etc

=cut

sub as_human_size($)
{
    my ($size, $sign) = (shift, 1);

    my %result = (
        original    => $size,
        digit       => 0,
        letter      => '',
        human       => 'N/A',
        byte        => '',
    );

    {{
        last unless $size;
        last unless $size >= 0;

        my @suffixes = ('', 'K', 'M', 'G', 'T', 'P', 'E');
        my ($limit, $div) = (1024, 1);
        for (@suffixes)
        {
            if ($size < $limit || $_ eq $suffixes[-1])
            {
                $size = $sign * $size / $div;
                if ($size < 10)
                {
                    $size = sprintf "%1.2f", $size;
                }
                elsif ($size < 50)
                {
                    $size = sprintf "%1.1f", $size;
                }
                else
                {
                    $size = int($size);
                }
                s/(?<=\.\d)0$//, s/\.00?$// for $size;
                $result{digit}  = $size;
                $result{letter} = $_;
                $result{byte}   = 'B';
                last;
            }
            $div = $limit;
            $limit *= 1024;
        }
    }}

    $result{human} = $result{digit} . $result{letter} . $result{byte};

    return ($result{digit}, $result{letter}, $result{byte}, $result{human})
        if wantarray;
    return $result{human};
}

=head2 as_human_speed

As as_human_size, but convert into speed

=cut
sub as_human_speed
{
    my @result = as_human_size(shift);
    my $human = pop @result;
    my $byte = pop @result;
    push @result, 'b',  '/', 's';
    $human = join '', @result;
    push @result, $human;
    return @result if wantarray;
    return $human;
}

=head2 as_human_datetime

Return datetime string from timestemp

=cut

sub as_human_datetime
{
#    return decode utf8 => strftime '%c', localtime shift;
    return strftime '%F %R', localtime shift;
}

=head2 torrent_priority_num

Convert torrent priority name to int

=cut
sub torrent_priority_num
{
    my ($name) = @_;

    # Default normal
    my $num =   ($name eq 'off')    ?0    :
                ($name eq 'low')    ?1    :
                ($name eq 'normal') ?2    :
                ($name eq 'high')   ?3    :2;

    return $num;
}

=head2 file_priority_num

Convert file priority name to int

=cut
sub file_priority_num
{
    my ($name) = @_;

    # Default normal
    my $num =   ($name eq 'off')    ?0    :
                ($name eq 'normal') ?1    :
                ($name eq 'high')   ?2    :1;

    return $num;
}

1;

=head1 AUTHORS

Copyright (C) 2008 Dmitry E. Oboukhov <unera@debian.org>,

Copyright (C) 2008 Roman V. Nikolaev <rshadow@rambler.ru>

=head1 LICENSE

This program is free software: you can redistribute  it  and/or  modify  it
under the terms of the GNU General Public License as published by the  Free
Software Foundation, either version 3 of the License, or (at  your  option)
any later version.

This program is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even  the  implied  warranty  of  MERCHANTABILITY  or
FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public  License  for
more details.

You should have received a copy of the GNU  General  Public  License  along
with this program.  If not, see <http://www.gnu.org/licenses/>.

=cut

__DATA__
this is lock for this module
