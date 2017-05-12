package RTMP::Client;
use Socket qw(:all);
use Fcntl;
use Time::HiRes qw(gettimeofday);

use 5.008008;
use warnings;

our $VERSION = '0.04';

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(rtmp_connect rtmp_play rtmp_call print_hex my_recv);
our $rtmp_packet_length = 12;
our $debug_flag = 0;

=head1 NAME

RTMP::Client - A Simple RTMP client

=head1 SYNOPSIS

 use RTMP::Client qw(rtmp_connect rtmp_play rtmp_call);

 print "connect success\n" if rtmp_connect('192.168.1.1', '1935', 'live/23');
 rtmp_play('MainB_1', '-1.0', '-1.0');
 rtmp_call('YourFunc', 'YourARGV');

=head1 DESCRIPTION

This is a simple RTMP client without video or audio decode.
It implemented in pure PERL including packing Adobe amf packages.

=head1 METHODS

=head2 rtmp_connect($rtmp_server_address, $server_port, $application_name)

Just like the 'NetConnection.connect()' function in ActionScript, with args are set in different way.

=cut

sub rtmp_connect
{
    my ($server_addr, $server_port, $app_name ) = @_;
    die 'app_name MUST NOT begin with \'/\' ' if substr($app_name, 0 , 1) eq '/';

    my $ipaddress;
    if ($server_addr =~ /^[\d\.]+$/ )
        { $ipaddress = inet_aton($server_addr); } # ip addr here 
    else 
        { $ipaddress = gethostbyname($server_addr); } # domain addr here
    my $address = sockaddr_in($server_port, $ipaddress);
    socket(SOCK, AF_INET, SOCK_STREAM, IPPROTO_TCP) || die $!;
    connect(SOCK, $address) || die $!;
    #my $fh_flag = fcntl(SOCK, F_GETFL,0);
    #$fh_flag |= O_NONBLOCK;
    #my $fh_flag = fcntl(SOCK, F_SETFL, $fh_flag);

    die 'handshake fail' unless rtmp_handshake();

    my $amf_body = pack_amf_string('connect');
    $amf_body.= pack_amf_number('1.0');
    $amf_body.= pack_amf_object_start();
    $amf_body.= pack_amf_attribute_name('app');
    $amf_body.= pack_amf_string($app_name);
    $amf_body.= pack_amf_attribute_name('flashVer');
    $amf_body.= pack_amf_string('LNX 10,0,32,18');
    $amf_body.= pack_amf_attribute_name('swfUrl');
    $amf_body.= pack_amf_string('http://sina/perl/rtmp/client-fate.swf');
    $amf_body.= pack_amf_attribute_name('tcUrl');
    $amf_body.= pack_amf_string("rtmp://$server_addr/$app_name");
    $amf_body.= pack_amf_attribute_name('fpad');
    $amf_body.= pack_amf_boolean('false');
    $amf_body.= pack_amf_attribute_name('capabilities');
    $amf_body.= pack_amf_number('15.0');
    $amf_body.= pack_amf_attribute_name('audioCodecs');
    $amf_body.= pack_amf_number('3191.0');
    $amf_body.= pack_amf_attribute_name('videoCodecs');
    $amf_body.= pack_amf_number('252.0');
    $amf_body.= pack_amf_attribute_name('videoFunction');
    $amf_body.= pack_amf_number('1.0');
    $amf_body.= pack_amf_attribute_name('pageUrl');
    $amf_body.= pack_amf_string('http://sina/perl/rtmp/client-fate.html');
    $amf_body.= pack_amf_attribute_name('objectEncoding');
    $amf_body.= pack_amf_number('0.0');
    $amf_body.= pack_amf_object_end();

    # set object id 3
    my $amf = pack_amf_body_to_chunks($amf_body, '00000011', '00000000', '14');
    my_send_bin($amf);
    for (1..5) 
    {
        my @rtmp_content = my_recv_a_msg();
        analysis_rtmp_msg(@rtmp_content);
    }

    $amf = pack('H*', '025154620000040500000000002625a0');
    my_send_bin($amf);

    # user control message -> set buffer length -> set stream 0 buffer to 1000
    $amf = pack('H*', '4200000000000a04000300000000000003e8');
    my_send_bin($amf);

    $amf_body = pack_amf_string('createStream');
    $amf_body.= pack_amf_number('2.0');
    $amf_body.= pack_amf_null();
    $amf = pack_amf_body_to_chunks($amf_body, '00000011', '00000000', '14');
    my_send_bin($amf);

    $amf = pack('H*', 'c2000300000001000003e8');
    my_send_bin($amf);
    for (1..1) 
    {
        my @rtmp_content = my_recv_a_msg();
        analysis_rtmp_msg(@rtmp_content);
    }

    return 1;
}

=head2 rtmp_play($stream_or_file_name, $play_type, $length, $interval_call_hook_function, $hook_function)

Just like the 'NetStream.play()' function in ActionScript, with args are set in different way.
You can use the last two args or not.

=cut

sub rtmp_play
{
    my ($stream_name, $play_type, $length, $recieve_loop_time, $hook_function) = @_;
    my $amf_body = pack_amf_string('play');
    $amf_body.= pack_amf_number('0.0');
    $amf_body.= pack_amf_null();
    $amf_body.= pack_amf_string($stream_name);
    $amf_body.= pack_amf_number($play_type);
    $amf_body.= pack_amf_number($length);
    #my $amf = pack_amf_body_to_chunks($amf_body, '00001000', '01000000', '14');
    my $amf = pack('H*','0800372400002e110100000000020004706c6179000000000000000000050200074d61696e425f3100c08f40000000000000c08f400000000000');
    my_send_bin($amf);

    my_recv_nostop($recieve_loop_time, $hook_function);
}

=head2 rtmp_call($stream_or_file_name, $play_type, $length, $file_path_to_store_the_data_received)

Just like the 'NetStream.call()' function in ActionScript, with args are set in different way.

=cut

sub rtmp_call
{
    my ($func_name,$select_option) = @_;
    #return unless $select_option =~ /^[A-Z]$/;
    my $amf_body = pack_amf_string($func_name);
    $amf_body.= pack_amf_number('1.0');
    $amf_body.= pack_amf_null();
    #$amf.= pack_amf_string($select_option);
    $amf_body.= pack_amf_string($select_option);
    #my $amf = pack_amf_body_to_chunks($amf_body, '01000011', '01000000', '11');
    #print_hex($amf);
    my $amf = pack('H*','43010d640000271100');
    $amf.= $amf_body;
    my_send_bin($amf);

    my @rtmp_content = my_recv_a_msg();
    my $string = do { use bytes;length $rtmp_content[1]; };
    return $string;

}


=head1 EXAMPLES

    use RTMP::Client qw(rtmp_connect rtmp_play rtmp_call);

Speed Detection

report download speed every 5 secs.

    print "connect success\n" if rtmp_connect('192.168.1.1', '1935', 'live/23');
    my $report_time = 5;
    rtmp_play('MainB_1', '-1.0', '-1.0', $report_time, \&speed_detector);
    sub speed_detector
    {
        my $rev_length = shift;
        my $speed = $rev_length / 1024 / $report_time;
        if ($speed > 3)
        {
            my $cur_time = strftime("%F_%T", localtime);
            print $cur_time, "\t", $speed, "\tKbytes/s\n";
        }
        else
        {
            print "too slow !\n";
        }
    }

    
Save to File

do things like "rtmpdump".L<http://rtmpdump.mplayerhq.hu/>

    print "connect success\n" if rtmp_connect('192.168.1.1', '1935', 'live/23');
    my $loop_time = 10;
    rtmp_play('MainB_1', '-1.0', '-1.0', $report_time, \&save_to_file);
    sub save_to_file
    {
        my $rev_length = shift;
        my $rev_binary = shift;
        open my $fh,">>","/root/rtmp_dump.bin";
        binmode $fh;
        print $fh $rev_binary;
        close $fh;
    }


=head1 SOME INTERNAL METHODS

=head2 rtmp_handshake()

No args need. Called in function rtmp_connect().

=cut

sub rtmp_handshake
{
    my @c0 = qw(03);
    my_send_hex(\@c0);

    my @c1 = qw(00 00 00 00); # time - 4 bytes
    push @c1, qw(00 00 00 00); # zero - 4 bytes (do not MUST!)
    for (1..1528) { push @c1, '99';}
    my_send_hex(\@c1);

    #print "start handshack...\n";
    my $s0 = my_recv(1);
    my $s1 = my_recv(1536);
    my $s2 = my_recv(1536);
    my $c2 = $s1;
    my_send_bin($c2);
    #print "handshack success.\n";

    return 1;
}

=head2 pack_amf_body_to_chunks($string, $object_id, $stream_id, $type)

Output a available binary amf packet.
Works on amf message body, just like add a right amf header before the message body.

=cut

sub pack_amf_body_to_chunks
{
    my ($body, $size_and_object_id, $stream_id, $type) = @_;
    my $body_length = do { use bytes;   length $body; };

    my $header = pack('B8', $size_and_object_id); # 2 = the size of the header{here: 12} 6 = object id{here: 3}
    $header.= pack('H6', '000000'); # timestamp (big-endian integer) [header size >= 4 bytes]
    $header.= substr( pack('N', $body_length), 1); # length of the object body (big-endian integer) [>= 8 bytes]
    $header.= pack('H2', $type); # content type [>= 8 bytes] {0x14: Function call, 0x09: Video data, 0x08: Audio data}
    $header.= pack('H8', $stream_id); # a stream id (32 bit integer that is little-endian encoded) [only = 12 bytes]

    my $need_chunk_num = ( $body_length - ( $body_length % 128 ) ) / 128;
    $need_chunk_num++;
    my $output = $header;
    for (1..$need_chunk_num)
    {
        my $seek_flag =  ($_ - 1) * 128 ;
        $output.= substr($body, $seek_flag, 128);
        $output.= pack('H2', 'c3');
    }
    $output = substr( $output, 0, -1);
    return $output;
}

=head2 pack_amf_object_start()

=cut

sub pack_amf_object_start
{
    my $output = pack('H2', '03');
    return $output;
}

=head2 pack_amf_object_end()

=cut

sub pack_amf_object_end
{
    my $output = pack('H6', '000009');
    return $output;
}

=head2 pack_amf_attribute_name($string)

It packs a attribute_name which less than 65536 bytes or return null.

=cut

sub pack_amf_attribute_name
{
    my ($string) = (@_);
    my $length = do { use bytes;   length $string; };
    return '' if $length > 65536;
    my $output = pack('n', $length);
    $output.= $string;
    return $output;
}

=head2 pack_amf_number($double)

Return 9 bytes binary data.

=cut

sub pack_amf_number
{
    my ($number) = (@_);
    my $output = pack('H2', '00');
    $output.= join "", reverse split//, pack('d', $number);
    return $output;
}

=head2 pack_amf_boolean($boolean)

Return 2 bytes binary data.

=cut

sub pack_amf_boolean
{
    my ($boolean) = (@_);
    my $output = pack('H2', '01');
    $output.= pack('H2', '00') if $boolean eq 'false';
    $output.= pack('H2', '01') if $boolean eq 'true';
    return $output;
}

=head2 pack_amf_string($string)

it can pack a string which less than 65536 bytes or it return null.
There will be a long string packer in future.

=cut

sub pack_amf_string
{
    my ($string) = (@_);
    my $length = do { use bytes;   length $string; };
    return '' if $length > 65536; #todo: alarm or switch into long_string function.
    my $output = pack('H2', '02');
    $output.= pack('n', $length);
    $output.= $string;
    return $output;
}

=head2 pack_amf_boolean($boolean)

Return 1 byte binary data.

=cut

sub pack_amf_null
{
    return pack('H2', '05');
}

=head2 my_recv_a_chunk()

Recieve a rtmp chunk.

=cut

sub my_recv_a_chunk
{
    # get the first byte include fmt and chunk stream id 
    my $fmt_and_chunk_id = my_recv(1);
    $fmt_and_chunk_id = unpack('B8', $fmt_and_chunk_id);
    dprint("Chunk fmt: $fmt_and_chunk_id\n");

    # get chunk_id
    my $chunk_id = substr( $fmt_and_chunk_id, 2, 6);
    if ($chunk_id eq '000000') 
    {
        # havn`t test
        my $buf = dec(my_recv(1));
        $chunk_id = $buf + 64;
    }
    elsif ($chunk_id eq '000001')
    {
        # havn`t test
        my $buf = dec(my_recv(1));
        $chunk_id = $buf + 64;
        $buf = dec(my_recv(1));
        $chunk_id += $buf * 256;
    }
    else
    {
        $chunk_id = oct('0b'.$chunk_id);
    }

    # get chunk_header_length
    my $fmt = substr( $fmt_and_chunk_id, 0, 2);
    if ($fmt eq '00') 
    {
        #Chunks of Type 0 are 11 bytes long. This type MUST be used at the
        #start of a chunk stream, and whenever the stream timestamp goes
        #backward (e.g., because of a backward seek).
        my $chunk_header = my_recv(11); 
        print('Chunk header: ') if $debug_flag;
        print_hex($chunk_header) if $debug_flag;

        #the absolute timestamp of the message is sent here.
        #If the timestamp is greater than or equal to 16777215
        #(hexadecimal 0x00ffffff), this value MUST be 16777215, and the
        #‘extended timestamp header’ MUST be present. Otherwise, this value
        #SHOULD be the entire timestamp.
        my $chunk_timestamp = dec(substr($chunk_header, 0, 3)); #todo: absolute timestamp for what?
        if ($chunk_timestamp >= 16777215)
        {
            $chunk_extended_timestamp = dec(my_recv(4));
            $chunk_timestamp = $chunk_extended_timestamp + 16777215;
        }
        reset_rtmp_timer($chunk_id); #todo: means reset chunk timestamp here?

        #Note that this is generally not the same as the length of the chunk
        #payload. The chunk payload length is the maximum chunk size for all
        #but the last chunk, and the remainder (which may be the entire
        #length, for small messages) for the last chunk.
        my $chunk_msg_length = dec(substr($chunk_header, 3, 3));
        set_rtmp_chunk_msg_length($chunk_id, $chunk_msg_length);
        my $chunk_msg_type_id = dec(substr($chunk_header, 6, 1));
        set_rtmp_chunk_msg_type_id($chunk_id, $chunk_msg_type_id);
        my $chunk_msg_stream_id = dec(substr($chunk_header, 7, 4));
        set_rtmp_chunk_msg_stream_id($chunk_id, $chunk_msg_stream_id);
    }
    elsif ($fmt eq '01') 
    {
        #Chunks of Type 1 are 7 bytes long. The message stream ID is not
        #included; this chunk takes the same stream ID as the preceding chunk.
        #Streams with variable-sized messages (for example, many video
        #formats) SHOULD use this format for the first chunk of each new
        #message after the first.
        my $chunk_header = my_recv(7); 

        my $chunk_timestamp_deta = dec(substr($chunk_header, 0, 3)); #for eval the bandwidth, i do not use it.
        if ($chunk_timestamp >= 16777215)
        {
            $chunk_extended_timestamp = dec(my_recv(4));
            $chunk_timestamp = $chunk_extended_timestamp + 16777215;
        }
        my $chunk_message_length = dec(substr($chunk_header, 3, 3));
        set_rtmp_chunk_msg_length($chunk_id, $chunk_message_length);
        my $chunk_message_type_id = dec(substr($chunk_header, 6, 1));
        set_rtmp_chunk_msg_type_id($chunk_id, $chunk_message_type_id);
    }
    elsif ($fmt eq '10') 
    {
        #Chunks of Type 2 are 3 bytes long. Neither the stream ID nor the
        #message length is included; this chunk has the same stream ID and
        #message length as the preceding chunk. Streams with constant-sized
        #messages (for example, some audio and data formats) SHOULD use this
        #format for the first chunk of each message after the first.
        my $chunk_header = my_recv(3); 

        my $chunk_timestamp_deta = dec(substr($chunk_header, 0, 3)); #for eval the bandwidth, i do not use it.
        if ($chunk_timestamp >= 16777215)
        {
            $chunk_extended_timestamp = dec(my_recv(4));
            $chunk_timestamp = $chunk_extended_timestamp + 16777215;
        }
    }
    elsif ($fmt eq '11') 
    { 
        #Chunks of Type 3 have no header. Stream ID, message length and
        #timestamp delta are not present; chunks of this type take values from
        #the preceding chunk. When a single message is split into chunks, all
        #chunks of a message except the first one, SHOULD use this type.
    }

    my $msg_length = get_rtmp_chunk_msg_length($chunk_id);
    my $msg_type_id = get_rtmp_chunk_msg_type_id($chunk_id);

    # if this is a Protocol Control Messages
    #Protocol control messages SHOULD have message stream ID 0(called as
    #control stream) and chunk stream ID 2
    if ($chunk_id == 2 and get_rtmp_chunk_msg_stream_id($chunk_id) == 0)
    {
        dprint('protocol_control_message', 3);
        #Set Chunk Size
        if ($msg_type_id == 1)
        {
            dprint('Set Chunk Size',6);
            my $new_chunk_size = dec(my_recv(4));
            set_rtmp_client_chunk_size($new_chunk_size);
            dprint("new chunk size is $new_chunk_size", 6);
            #    my $set_chunk_response = 
            #        pack('H2','02')
            #        . get_rtmp_timer($chunk_id, '3bytes')
            #        . pack('H6','000004')
            #        . pack('H2','01')
            #        . pack('H8','00000000')
            #        . pack('H8','00000080');
            #    my_send_bin($set_chunk_response);
        }
        #Abort Message
        elsif ($msg_type_id == 2)
        {
            dprint('Abort Message',6);
        }
        # Acknowledgement
        elsif ($msg_type_id == 3)
        {
            dprint('Acknowledgement',6);
        }
        # User Control Message
        elsif ($msg_type_id == 4)
        {
            dprint('User Control Message',6);
            my $event_type = dec(my_recv(2));
            if($event_type == 0)
            {
                dprint('Stream Begin', 9);
                my $begin_stream_id = dec(my_recv(4));
                dprint("Begin Stream ID is $begin_stream_id", 9);
            }
            elsif($event_type == 1)
            {
                dprint('Stream EOF', 9);
            }
            elsif($event_type == 2)
            {
                dprint('Stream Dry', 9);
            }
            elsif($event_type == 3)
            {
                dprint('Set Buffer Length', 9);
            }
            elsif($event_type == 4)
            {
                dprint('StreamIsRecorded', 9);
            }
            elsif($event_type == 5)
            {
                dprint('user contorl error recving', 9);
            }
            elsif($event_type == 6)
            {
                dprint('PingRequest', 9);
                my $ping_timestamp = my_recv(4);
                my $ping_response = 
                    pack('H2','02')
                    . get_rtmp_timer($chunk_id, '3bytes')
                    . pack('H6','000004')
                    . pack('H2','07')
                    . pack('H8','00000000')
                    . $ping_timestamp;
                my_send_bin($ping_response);
            }
            elsif($event_type == 7)
            {
                dprint('PingResponse', 9);
            }
            else
            {
                print "user contorl error recving!!!!\n";
            }
        }
        # Window Acknowledgement Size
        elsif ($msg_type_id == 5)
        {
            dprint('Window Acknowledgement Size',6);
            my $server_window_acknowledgement = dec(my_recv($msg_length));
            set_rtmp_peer_window($server_window_acknowledgement); # could not work on this
            dprint("peer Window Size is $server_window_acknowledgement now", 6);
        }
        # Set Peer Bandwidth
        elsif ($msg_type_id == 6)
        {
            dprint('Set Peer Bandwidth',6);
            my $buf = my_recv($msg_length);
            my $set_window_size = dec(substr($buf, 0, 4));
            my $limit_type = dec(substr($buf, 4, 1)); # 0-hard, 1-soft, 2-dunamic
            set_rtmp_window($set_window_size, $limit_type);
            dprint("peer set my Sindow Size to $set_window_size with limit type $limit_type", 6);
            my $rtmp_packet_window_acknowledgement_size = 
                pack('H2','02')
                . get_rtmp_timer($chunk_id, '3bytes')
                . pack('H6','000004')
                . pack('H2','05')
                . pack('H8','00000000')
                . substr($buf, 0, 4);
            my_send_bin($rtmp_packet_window_acknowledgement_size);
        }
        return 'rtmp_protocol_control_message';
    }

    if($msg_type_id == 20)
    {
        dprint('Command message in AMF0', 3);
    }
    my $chunk_size = get_rtmp_client_chunk_size(); # all rtmp chunk stream share one chunk_size here.

    if($msg_length <= $chunk_size)
    {
        #dprint("payload 1:$msg_length");
        my $rtmp_msg = my_recv($msg_length);
        put_rtmp_msg($chunk_id, $rtmp_msg);
        return $chunk_id;
    }
    else
    {
        our $msg_length_remain = get_rtmp_chunk_msg_length($chunk_id) unless defined $msg_length_remain;
        $msg_length_remain = get_rtmp_chunk_msg_length($chunk_id) if $msg_length_remain <= 0;
        if ($msg_length_remain <= $chunk_size)
        {
            #dprint("payload 2:$msg_length_remain");
            my $rtmp_msg = my_recv($msg_length_remain);
            put_rtmp_msg($chunk_id, $rtmp_msg);
            $msg_length_remain = 0;
            return $chunk_id;
        }
        else
        {
            #dprint("payload 3:$chunk_size");
            my $rtmp_msg = my_recv($chunk_size);
            put_rtmp_msg($chunk_id, $rtmp_msg);
            $msg_length_remain = $msg_length_remain - $chunk_size;
            return 'rtmp_msg_recv_piece';
        }
    }
}

=head2 my_recv_a_msg()

Recieve a rtmp message.

=cut

sub my_recv_a_msg
{
    our $msg_counter unless defined $msg_counter;
    my $chunk_id = 0;
    my $chunk_count = 0;
    my $limit_chunk = 9; # this is a limit by me. not by the RTMP
    while(1)
    {
        $chunk_count++;
        #print "[", "-" x 5, " $chunk_count ", "-" x 5 ,"]\n";
        $chunk_id = my_recv_a_chunk();
        #die "limit chunk already recv.\n" if $chunk_count == $limit_chunk;
        if ($chunk_id =~ /[\d]+/)
        {
            my $rtmp_msg = get_rtmp_msg($chunk_id);
            my $rtmp_msg_type_id = get_rtmp_chunk_msg_type_id($chunk_id);

            my $rtmp_msg_type_name = '';
            if ($rtmp_msg_type_id == 8)
            {
                $rtmp_msg_type_name = 'Audio';
            }
            elsif ($rtmp_msg_type_id == 9)
            {
                $rtmp_msg_type_name = 'Video';
            }
            elsif ($rtmp_msg_type_id == 20 or $rtmp_msg_type_id == 17)
            {
                $rtmp_msg_type_name = 'Command';
            }
            elsif ($rtmp_msg_type_id == 18 or $rtmp_msg_type_id == 15)
            {
                $rtmp_msg_type_name = 'Data';
            }
            elsif ($rtmp_msg_type_id == 19 or $rtmp_msg_type_id == 16)
            {
                $rtmp_msg_type_name = 'SharedObject';
            }
            elsif ($rtmp_msg_type_id == 22)
            {
                $rtmp_msg_type_name = 'Aggregate';
            }
            else
            {
                $rtmp_msg_type_name = "SomethingElse[$rtmp_msg_type_id]";
            }

            $msg_counter++;
            print "=" x 50, " $msg_counter - $rtmp_msg_type_name ", "=" x 50 ,"\n" if $debug_flag;

            reset_rtmp_msg($chunk_id);
            return ($rtmp_msg_type_id, $rtmp_msg);
        }
        elsif($chunk_id eq 'rtmp_protocol_control_message')
        {
            return '';
        }
    }
}

=head2 my_recv_nostop(\&sub)

Wait until recieved bytes, then return it.

=cut

sub my_recv_nostop
{
    my ($report_loop_time, $function) = @_;
    return unless ref $function eq 'CODE';

    my $how_many_btyes_recieved_total = 0;
    my $how_many_btyes_recieved_noack = 0;
    my $how_many_btyes_recieved_noreport = 0;
    my $time_flag = time;
    my $report_time_count = 0;
    
    my $recieved_binary;
    while(1)
    {
        my @rtmp_content = my_recv_a_msg();
        analysis_rtmp_msg(@rtmp_content);

        #my $how_many_btyes_recieved = sysread(SOCK, $buf, 4096); #or die "sysread: $!";
        #$bytes .= $buf;
        $recieved_binary = $rtmp_content[1];
        my $how_many_btyes_recieved = do {use bytes; length($rtmp_content[1]);};
        $how_many_btyes_recieved_total += $how_many_btyes_recieved;
        $how_many_btyes_recieved_noack += $how_many_btyes_recieved;
        $how_many_btyes_recieved_noreport += $how_many_btyes_recieved;
        if ( $how_many_btyes_recieved_noack >= get_rtmp_window() )
        {
            dprint("send acknowlege to server.");
            $how_many_btyes_recieved_noack = 0;
            my $send_bin_tmp = join "", reverse split//, pack('I', $how_many_btyes_recieved_total);
            #my $send_bin = pack('H*','4200000000000403') . $send_bin_tmp;
            my $send_bin = 
                pack('H2','02')
                . get_rtmp_timer(2, '3bytes')
                . pack('H6','000004')
                . pack('H2','03')
                . pack('H8','00000000')
                . $send_bin_tmp;
            my_send_bin($send_bin);
        }

        if (time - $time_flag >= $report_loop_time)
        {
            $time_flag = time;
            $report_time_count++;
            &$function($how_many_btyes_recieved_noreport, $recieved_binary);
            $how_many_btyes_recieved_noreport = 0;
        }
    }
    return 0;
}

=head2 my_recv($int_wanted_length, $int_time_out)

Wait $int_time_out Seconds, or Recieve $int_wanted_length bytes, then return it.

=cut

sub my_recv
{
    my ($wanted_length, $time_out) = @_;
    return unless $wanted_length =~ /^[1-9][\d]*$/;
    $time_out = 3 unless $time_out;

    my $start_time = time;
    my $bytes = '';
    while(1)
    {
        if (time - $start_time >= $time_out)
        {
            print "func: my_recv(), timeout for $time_out Seconds\n";
            return '';
        }
        my $buf = '';
        my $success_length = sysread(SOCK, $buf, $wanted_length);
        next unless $success_length; # for no-block IO
        $bytes .= $buf;
        $wanted_length = $wanted_length - $success_length;
        last if $wanted_length <= 0;
    }
    return $bytes;
}

=head2 my_send_bin($binary_data)

Send binary data to server.

=cut

sub my_send_bin
{
    my ($bin_string) = @_;
    my $sent = syswrite(SOCK, $bin_string);
    return $sent;
}

=head2 my_send_hex(@array_with_hex)

Convert hex array to binary ,then send them to server.

=cut

sub my_send_hex
{
    my ($ref_hex_array) = @_;
    my $send_str = '';
    foreach (@$ref_hex_array)
    {
        my $one_byte = '0x'.$_;
        $send_str.= pack('C', oct($one_byte));
    }
    my $sent = syswrite(SOCK, $send_str);
    return $sent;
}

=head2 print_hex($binary_data)

Print binary data in a readable format.

=cut

sub print_hex
{
    my ($bytes) = @_;
    my $col_counter = 0;
    my @bytes = split //, $bytes;
    foreach (@bytes)
    {
        $col_counter++;
        printf "%02x ", ord($_);
        if($col_counter == 16)
        {
            $col_counter = 0;
            print "\n";
        }
    }
    print "\n";
}

=head2 rtmp_timer($int_chunk_id)

Return rtmp timestamp of the chunk stream id in string format.
From Adobe RTMP Spec:
1.Timestamps in RTMP Chunk Stream are given as an integer number of milliseconds.
2.each Chunk Stream will start with a timestamp of 0, but this is not required.
3.Timestamps MUST be monotonically increasing, and SHOULD be linear in time.

=cut

sub get_rtmp_timer
{
    my ($chunk_id, $format) = @_;
    return unless $chunk_id =~ /^[1-9][\d]*$/;

    my $output;
    my ($sec, $microsec) = gettimeofday;
    my $now_time = $sec . substr($microsec, 0, 3);
    our @rtmp_timer_start unless defined @rtmp_timer_start;
    if (defined $rtmp_timer_start[$chunk_id])
    {
        my $rtmp_timestamp = $now_time - $rtmp_timer_start[$chunk_id];
        $rtmp_timestamp = 0 if $rtmp_timestamp < 0; # keep it. sometimes happen.
        $output = $rtmp_timestamp;
    }
    else
    {
        $rtmp_timer_start[$chunk_id] = $now_time;
        $output = 0;
    }

    if($format eq '3bytes')
    {
        $output = join "", reverse split//, pack('I',$output);
        $output = substr($output, 1, 3);
    }

    return $output;
}

=head2 reset_rtmp_timer($chunk_id)

=cut

sub reset_rtmp_timer
{
    my $chunk_id = shift;
    return unless $chunk_id =~ /^[1-9][\d]*$/;

    my ($sec, $microsec) = gettimeofday;
    my $now_time = $sec . substr($microsec, 0, 3);
    our @rtmp_timer_start unless defined @rtmp_timer_start;
    $rtmp_timer_start[$chunk_id] = $now_time;
    return 1;
}

=head2 reset_rtmp_timer($chunk_id, $chunk_message_length)

=cut

sub set_rtmp_chunk_msg_length
{
    my ($chunk_id, $chunk_message_length) = @_;
    return unless $chunk_id =~ /^[1-9][\d]*$/;

    our @rtmp_msg_length unless defined @rtmp_msg_length;
    $rtmp_msg_length[$chunk_id] = $chunk_message_length;
    return 1;
}

=head2 get_rtmp_chunk_msg_length($chunk_id)

=cut

sub get_rtmp_chunk_msg_length
{
    my ($chunk_id) = @_;
    return unless $chunk_id =~ /^[1-9][\d]*$/;
    print 'get msg length before set.' unless defined @rtmp_msg_length;
    return $rtmp_msg_length[$chunk_id];
}

=head2 set_rtmp_chunk_msg_type_id($chunk_id, $chunk_message_type_id)

=cut

sub set_rtmp_chunk_msg_type_id
{
    my ($chunk_id, $chunk_message_type_id) = @_;
    return unless $chunk_id =~ /^[1-9][\d]*$/;

    our @rtmp_msg_type_id unless defined @rtmp_msg_type_id;
    $rtmp_msg_type_id[$chunk_id] = $chunk_message_type_id;
    return 1;
}

=head2 get_rtmp_chunk_msg_type_id($chunk_id)

=cut

sub get_rtmp_chunk_msg_type_id
{
    my ($chunk_id) = @_;
    return unless $chunk_id =~ /^[1-9][\d]*$/;
    print 'get msg type id before set.' unless defined @rtmp_msg_type_id;
    return $rtmp_msg_type_id[$chunk_id];
}

=head2 set_rtmp_chunk_msg_stream_id($chunk_id, $chunk_message_stream_id)

=cut

sub set_rtmp_chunk_msg_stream_id
{
    my ($chunk_id, $chunk_message_stream_id) = @_;
    return unless $chunk_id =~ /^[1-9][\d]*$/;

    our @rtmp_msg_stream_id unless defined @rtmp_msg_stream_id;
    $rtmp_msg_stream_id[$chunk_id] = $chunk_message_stream_id;
    return 1;
}

=head2 get_rtmp_chunk_msg_stream_id($chunk_id)

=cut

sub get_rtmp_chunk_msg_stream_id
{
    my ($chunk_id) = @_;
    return unless $chunk_id =~ /^[1-9][\d]*$/;
    print 'get msg stream id before set.' unless defined @rtmp_msg_stream_id;
    return $rtmp_msg_stream_id[$chunk_id];
}

=head2 set_rtmp_client_chunk_size($new_chunk_size)

=cut

sub set_rtmp_client_chunk_size
{
    my ($new_chunk_size) = @_;

    #The maximum chunk size can be 65536 bytes. The
    #maintained independently for each direction.
    return unless $new_chunk_size =~ /^[\d]{1,5}$/;
    return if $new_chunk_size > 65536;
    our $rtmp_client_chunk_size = $new_chunk_size;
}

=head2 get_rtmp_client_chunk_size

=cut

sub get_rtmp_client_chunk_size
{
    if (defined $rtmp_client_chunk_size)
    {
        return $rtmp_client_chunk_size;
    }
    else
    {
        our $rtmp_client_chunk_size = 128;
        return $rtmp_client_chunk_size;
    }
}

=head2 reset_rtmp_msg($chunk_id)

=cut

sub reset_rtmp_msg
{
    print "reset rtmp msg before set it.\n" unless defined @rtmp_msg;
    my ($chunk_id) = @_;
    $rtmp_msg[$chunk_id] = '';
}

=head2 put_rtmp_msg($chunk_id, $string)

=cut

sub put_rtmp_msg
{
    my ($chunk_id, $string) = @_;
    our @rtmp_msg unless defined @rtmp_msg;
    $rtmp_msg[$chunk_id] .= $string;
}

=head2 get_rtmp_msg

=cut

sub get_rtmp_msg
{
    print "get rtmp msg before set it.\n" unless defined @rtmp_msg;
    my ($chunk_id) = @_;
    return $rtmp_msg[$chunk_id];
}

=head2 set_rtmp_window($window_size, $limit_type)

=cut

sub set_rtmp_window
{
    my ($window_size, $limit_type) = @_;
    our $rtmp_my_window_size = $window_size;
}

=head2 get_rtmp_window()

=cut

sub get_rtmp_window
{
    print "get rtmp window before set it.\n" unless defined $rtmp_my_window_size;
    return $rtmp_my_window_size;
}

=head2 set_rtmp_peer_window($window_size)

=cut

sub set_rtmp_peer_window
{
    my ($window_size) = @_;
    our $rtmp_peer_window_size = $window_size;
}

=head2 get_rtmp_peer_window()

=cut 

sub get_rtmp_peer_window
{
    print "get rtmp window before set it.\n" unless defined $rtmp_peer_window_size;
    return $rtmp_peer_window_size;
}

=head2 dec($binary_data)

Dump the data to dec

=cut

sub dec
{
    return oct('0x'.unpack('H*', shift));
}

=head2 dec($string, $indent, $front_color, $back_color)

print colorful strings

=cut

sub dprint
{
    my ($string, $indent, $front_color, $back_color) = @_;
    #$front_color = 39 unless $front_color; # accept: 30-39
    #$back_color = 40 unless $back_color; # accept: 40-49
    #$color="\\033[$front_color;$back_color"."m";
    #$endstyle="\\033[0m";
    #$content = "\"".$color.$string.$endstyle."\"";
    print '-' x $indent, "> " if $debug_flag;
	print $string,"\n";
    #my $cmd = "echo $content\n";
    #system $cmd if $debug_flag;
}

=head2 analysis_rtmp_msg($msg_type, $msg)

output the rtmp stream information to STDOUT

=cut

sub analysis_rtmp_msg
{
    my ($msg_type, $msg) = @_;
    if ($msg)
    {
        #print '-' x 22, " msg content ", '-' x 22, "\n";
        #print "msg type: $msg_type\n";
        if ($msg_type == 20)
        {
            my $command_name_length = dec(substr($msg, 1, 2));
            my $command_name = substr($msg, 3, $command_name_length);
            dprint("command name: $command_name", 9);
            #print_hex($msg);
        }
        elsif ($msg_type == 22)
        {
            local $| = 1;
            #print_hex($msg);
        }
    }
}


=head1 AUTHOR

Written by ChenGang, yikuyiku.com@gmail.com
L<http://blog.yikuyiku.com/>


=head1 COPYRIGHT

Copyright (c) 2011 ChenGang.

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.


=head1 SEE ALSO

L<Kamaitachi>

=cut

1;
