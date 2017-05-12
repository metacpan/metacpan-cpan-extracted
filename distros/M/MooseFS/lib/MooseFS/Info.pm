package MooseFS::Info;
use strict;
use warnings;
use IO::Socket::INET;
use Moo;

extends 'MooseFS';

sub BUILD {
    my $self = shift;
    my $s = $self->sock;
    print $s pack('(LL)>', 510, 0); 
    my $header = $self->myrecv($s, 8); 
    my ($cmd, $length) = unpack('(LL)>', $header);
    if ($cmd == 511 and $length == 52) {
        my $data = $self->myrecv($s, $length);
        my ($total, $avail, $trspace, $trfiles, $respace, $refiles, $nodes, $chunks, $tdcopies) = unpack("(QQQLQLLLL)>", $data);
        $self->info({
            total_space => $total,
            avail_space => $avail,
            trash_space => $trspace,
            trash_files => $trfiles,
            reserved_space => $respace,
            reserved_files => $refiles,
            all_fs_objects => $nodes,
            chunks => $chunks,
            regular_chunk_copies => $tdcopies,
        });
    } elsif ($cmd == 511 and $length == 60) {
        my $data = $self->myrecv($s, $length);
        my ($total, $avail, $trspace, $trfiles, $respace, $refiles, $nodes, $dirs, $files, $chunks, $tdcopies) = unpack("(QQQLQLLLLLL)>", $data);
        $self->info({
            total_space => $total,
            avail_space => $avail,
            trash_space => $trspace,
            trash_files => $trfiles,
            reserved_space => $respace,
            reserved_files => $refiles,
            all_fs_objects => $nodes,
            directories => $dirs,
            files => $files,
            chunks => $chunks,
            regular_chunk_copies => $tdcopies,
        });
    } elsif ($cmd == 511 and $length == 68) {
        my $data = $self->myrecv($s, $length);
        my ($v1, $v2, $v3, $total, $avail, $trspace, $trfiles, $respace, $refiles, $nodes, $dirs, $files, $chunks, $allcopies, $tdcopies) = unpack("(SCCQQQLQLLLLLLL)>", $data);
        $self->info({
            version => "$v1.$v2.$v3",
            total_space => $total,
            avail_space => $avail,
            trash_space => $trspace,
            trash_files => $trfiles,
            reserved_space => $respace,
            reserved_files => $refiles,
            all_fs_objects => $nodes,
            directories => $dirs,
            files => $files,
            chunks => $chunks,
            all_chunk_copies => $allcopies,
            regular_chunk_copies => $tdcopies,
        });
    } elsif ($cmd == 511 and $length == 76) {
        my $data = $self->myrecv($s, $length);
        my ($v1, $v2, $v3, $memusage, $total, $avail, $trspace, $trfiles, $respace, $refiles, $nodes, $dirs, $files, $chunks, $allcopies, $tdcopies) = unpack('(SCCQQQQLQLLLLLLL)>', $data); 
        $self->info({
            version => "$v1.$v2.$v3",
            total_space => $total,
            avail_space => $avail,
            trash_space => $trspace,
            trash_files => $trfiles,
            reserved_space => $respace,
            reserved_files => $refiles,
            all_fs_objects => $nodes,
            directories => $dirs,
            files => $files,
            chunks => $chunks,
            all_chunk_copies => $allcopies,
            regular_chunk_copies => $tdcopies,
            memusage => $memusage,
        });
    };
    for my $key ( keys %{ $self->info } ) {
        has $key => (is => 'ro', lazy => 1, default => sub {$self->info->{$key}} );
    };
};

1;
