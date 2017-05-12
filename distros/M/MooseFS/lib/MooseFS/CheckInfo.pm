package MooseFS::CheckInfo;
use strict;
use warnings;
use IO::Socket::INET;
use Moo;

extends 'MooseFS';

sub BUILD {
    my $self = shift;
    my $s = $self->sock;
    print $s pack('(LL)>', 512, 0);
    my $header = $self->myrecv($s, 8);
    my ($cmd, $length) = unpack('(LL)>', $header);
    if ( $cmd == 513 and $length >= 36 ) {
        my $data = $self->myrecv($s, $length);
        my $d = substr($data, 0, 36);
        my ($loopstart, $loopend, $files, $ugfiles, $mfiles, $chunks, $ugchunks, $mchunks, $msgbuffleng) = unpack('(LLLLLLLLL)>', $d);
        my ($messages, $truncated);
        if ($loopstart > 0) {
            if ($msgbuffleng > 0 ) {
                if ($msgbuffleng == 100000) {
                    $truncated = 'first 100k';
                } else {
                    $truncated = 'no';
                };
                $messages = substr($data, 36);
            };
        } else {
            $messages = 'no data';
        };
        $self->info({
            check_loop_start_time => $loopstart,
            check_loop_end_time => $loopend,
            files => $files,
            under_goal_files => $ugfiles,
            missing_files => $mfiles,
            chunks => $chunks,
            under_goal_chunks => $ugchunks,
            missing_chunks => $mchunks,
            msgbuffleng => $msgbuffleng,
            important_messages => $messages,
            truncated => $truncated,
        });
    }
    for my $key ( keys %{ $self->info } ) {
        has $key => (is => 'ro', lazy => 1, default => sub {$self->info->{$key}} );
    };
}

1;
