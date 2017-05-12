package Test::Net::Thumper;

use strict;
use warnings;

use Test::More;
use Test::MockObject;
use base 'Test::Class';

use FindBin;
use Net::AMQP;
use Data::Dumper;
use Try::Tiny;

sub startup : Tests(startup => 1) {
    my $self = shift;
    
    $self->{mock_socket} = Test::MockObject->new();
    $self->{mock_socket}->mock('sysread', sub {
        my $frame = shift @{ $self->{socket_read_data} };
        
        return unless $frame;
        
        my $raw_frame = $frame->to_raw_frame();
        $_[1] = $raw_frame;
        return $raw_frame;
    });    
    $self->{mock_socket}->mock('send', sub { 
        my $mock = shift;
        my $data = shift;
                
        if ($data ne Net::AMQP::Protocol->header) {
            my ($frame) = Net::AMQP->parse_raw_frames(\$data);
            push @{ $self->{frames_written} }, $frame;
        } 
        
        return 1;
    });
    $self->{mock_socket}->set_true('setsockopt');
    $self->{mock_socket}->set_true('close');
    
    $self->{mock_select} = Test::MockObject->new();
    $self->{mock_select}->fake_module(
        'IO::Select', 
        new => sub { $self->{mock_select} },
    );
    $self->{mock_select}->set_true('add');
    $self->{mock_select}->set_false('can_read');

    use_ok 'Net::Thumper';
    
    $self->{amqp} = Net::Thumper->new(
        amqp_definition => "$FindBin::Bin/amqp0-8.xml",
        server => 'rabbitmq_server',
        debug => 0,
    );
    $self->{amqp}->socket($self->{mock_socket});
   
}

sub setup : Tests(setup) {
    my $self = shift;
    
    undef $self->{socket_read_data};
    undef $self->{frames_written};    
}

sub test_dies_if_cant_connect : Tests() {
    my $self = shift;
    
    # GIVEN
    my $amqp = Net::Thumper->new(
        amqp_definition => "$FindBin::Bin/../../../lib/perl5/amqp0-8.xml",
        server => 'rabbitmq_server',
        debug => 0,
    );    
    
    # WHEN
    my $error;
    try {
        $amqp->connect();
    }
    catch {
        $error = $_;
    };
    
    # THEN
    like($error, qr/^Could not open socket:/, "Dies with correct error when connection failed");
}

sub test_connect : Tests(7) {
    my $self = shift;
    
    # GIVEN
    $self->{socket_read_data} = [
        $self->_create_method_frame('Connection::Start'),
        $self->_create_method_frame('Connection::Tune'),
        $self->_create_method_frame('Connection::OpenOk'),
    ];
    
    # WHEN
    $self->{amqp}->connect();
    
    # THEN
    is(@{ $self->{frames_written} }, 3, "3 frames written");
        
    isa_ok($self->{frames_written}[0], 'Net::AMQP::Frame::Method', 'First frame');
    isa_ok($self->{frames_written}[0]->method_frame, 'Net::AMQP::Protocol::Connection::StartOk', 'First method frame');
    
    isa_ok($self->{frames_written}[1], 'Net::AMQP::Frame::Method', 'Second frame');
    isa_ok($self->{frames_written}[1]->method_frame, 'Net::AMQP::Protocol::Connection::TuneOk', 'Second method frame');
    
    isa_ok($self->{frames_written}[2], 'Net::AMQP::Frame::Method', 'Third frame');
    isa_ok($self->{frames_written}[2]->method_frame, 'Net::AMQP::Protocol::Connection::Open', 'Third method frame');        
    
}

sub test_open_channel : Tests(4) {
    my $self = shift;
    
    # GIVEN
    $self->{socket_read_data} = [
        $self->_create_method_frame('Channel::OpenOk'),
    ];
    
    # WHEN
    $self->{amqp}->open_channel();  
    
    # THEN
    is(@{ $self->{frames_written} }, 1, "1 frame written");    
    
    isa_ok($self->{frames_written}[0], 'Net::AMQP::Frame::Method', 'Has outer method frame');
    isa_ok($self->{frames_written}[0]->method_frame, 'Net::AMQP::Protocol::Channel::Open', 'Sent a Channel::Open frame');
    
    is($self->{frames_written}[0]->channel, 1, "Channel id is hard-coded to 1");
}

sub test_declare_queue : Tests(5) {
    my $self = shift;
    
    # GIVEN
    $self->{socket_read_data} = [
        $self->_create_method_frame('Queue::DeclareOk'),
    ];
    
    # WHEN
    $self->{amqp}->declare_queue('queue_name', auto_delete => 1);  
    
    # THEN
    is(@{ $self->{frames_written} }, 1, "1 frame written");     
    
    isa_ok($self->{frames_written}[0], 'Net::AMQP::Frame::Method', 'Has outer method frame');
    isa_ok($self->{frames_written}[0]->method_frame, 'Net::AMQP::Protocol::Queue::Declare', 'Sent a Queue::Declare frame');
    
    is($self->{frames_written}[0]->method_frame->{queue}, 'queue_name', "Name of queue passed correctly");
    is($self->{frames_written}[0]->method_frame->{auto_delete}, '1', "auto_delete parameter passed correctly");    
}

sub test_publish : Tests(13) {
    my $self = shift;
    
    # GIVEN
    $self->{socket_read_data} = [];
    
    # WHEN
    $self->{amqp}->publish('exchange', 'routing key', 'body', {}, { correlation_id => 1, reply_to => 'me' });
    
    # THEN
    is(@{ $self->{frames_written} }, 3, "3 frames written");
    
    isa_ok($self->{frames_written}[0], 'Net::AMQP::Frame::Method', 'First frame has outer method frame');
    
    my $publish = $self->{frames_written}[0]->method_frame;
    isa_ok($publish, 'Net::AMQP::Protocol::Basic::Publish', 'Sent a Basic::Publish frame');
    is($publish->{routing_key}, 'routing key', "Routing key set correctly");
    is($publish->{exchange}, 'exchange', "Exchange set correctly");

    isa_ok($self->{frames_written}[1], 'Net::AMQP::Frame::Header', 'Second frame has outer header frame');
    
    my $header = $self->{frames_written}[1]->header_frame;
    isa_ok($header, 'Net::AMQP::Protocol::Basic::ContentHeader', 'Sent a Basic::ContentHeader frame');
    is($header->{reply_to}, 'me', "Reply to set correctly");
    is($header->{correlation_id}, '1', "Correlation id set correctly");
    is($header->{user_id}, undef, "User id has not been set");
    is($self->{frames_written}[1]->{body_size}, 4, "Body size is correct");
    
    isa_ok($self->{frames_written}[2], 'Net::AMQP::Frame::Body', 'Third frame is a body frame');

    my $body = $self->{frames_written}[2];    
    is($body->{payload}, "body", "Payload set correctly");            
}

sub test_publish_large : Tests(13) {
    my $self = shift;
    
    # GIVEN
    $self->{socket_read_data} = [];
    my $body = 'a' x 100000;
    
    # WHEN
    $self->{amqp}->publish('exchange', 'routing key', $body, {}, { correlation_id => 1, reply_to => 'me' });   
    
    # THEN
    is(@{ $self->{frames_written} }, 6, "6 frames written");
    
    isa_ok($self->{frames_written}[0], 'Net::AMQP::Frame::Method', 'First frame has outer method frame');
    
    my $publish = $self->{frames_written}[0]->method_frame;
    isa_ok($publish, 'Net::AMQP::Protocol::Basic::Publish', 'Sent a Basic::Publish frame');    
    
    isa_ok($self->{frames_written}[1], 'Net::AMQP::Frame::Header', 'Second frame has outer header frame');
    is($self->{frames_written}[1]->{body_size}, 100000, "Body size is correct");    
    
    isa_ok($self->{frames_written}[2], 'Net::AMQP::Frame::Body', 'Third frame is a body frame');
    is($self->{frames_written}[2]->{payload}, 'a' x 30000, "First body frame payload correct"); 
    
    isa_ok($self->{frames_written}[3], 'Net::AMQP::Frame::Body', 'Forth frame is a body frame');
    is($self->{frames_written}[3]->{payload}, 'a' x 30000, "Second body frame payload correct");
    
    isa_ok($self->{frames_written}[4], 'Net::AMQP::Frame::Body', 'Fifth frame is a body frame');
    is($self->{frames_written}[4]->{payload}, 'a' x 30000, "Third body frame payload correct");
    
    isa_ok($self->{frames_written}[5], 'Net::AMQP::Frame::Body', 'Sixth frame is a body frame');
    is($self->{frames_written}[5]->{payload}, 'a' x 10000, "Forth body frame payload correct");
}

sub test_get_no_message : Tests(5) {
    my $self = shift;
    
    # GIVEN
    $self->{socket_read_data} = [
        $self->_create_method_frame('Basic::GetEmpty'),
    ];
    
    # WHEN
    my $res = $self->{amqp}->get('foo');
    
    # THEN
    is($res, undef, "No message returned");
    
    is(@{ $self->{frames_written} }, 1, "1 frame written");
    
    isa_ok($self->{frames_written}[0], 'Net::AMQP::Frame::Method', 'Has outer method frame');
    isa_ok($self->{frames_written}[0]->method_frame, 'Net::AMQP::Protocol::Basic::Get', 'Sent a Basic::Get frame');
    
    is($self->{frames_written}[0]->method_frame->{queue}, 'foo', "Name of queue passed correctly");
}

sub test_get_with_message : Tests(6) {
    my $self = shift;
    
    # GIVEN
    my $msg_body = 'body';
    
    $self->{socket_read_data} = [
        $self->_create_method_frame('Basic::GetOk'),
        $self->_create_header_frame('Basic::ContentHeader', { body_size => length $msg_body }),
        Net::AMQP::Frame::Body->new(payload => $msg_body),
    ];
    
    # WHEN
    my $res = $self->{amqp}->get('foo');
    
    # THEN    
    is(@{ $self->{frames_written} }, 1, "1 frame written");
    
    isa_ok($self->{frames_written}[0], 'Net::AMQP::Frame::Method', 'Has outer method frame');
    isa_ok($self->{frames_written}[0]->method_frame, 'Net::AMQP::Protocol::Basic::Get', 'Sent a Basic::Get frame');    
    
    is($res->{body}, 'body', "Body returned correctly");
    is($res->{reply_to}, undef, "No reply_to in response");
    is($res->{correlation_id}, undef, "No correlation_id in response");
}

sub test_get_with_large_body : Tests(6) {
    my $self = shift;
    
    # GIVEN    
    $self->{socket_read_data} = [
        $self->_create_method_frame('Basic::GetOk'),
        $self->_create_header_frame('Basic::ContentHeader', { body_size => 200 }),
        Net::AMQP::Frame::Body->new(payload => 'a' x 100),
        Net::AMQP::Frame::Body->new(payload => 'a' x 100),
    ];
    
    # WHEN
    my $res = $self->{amqp}->get('foo');
    
    # THEN
    is(@{ $self->{frames_written} }, 1, "1 frame written");
    
    isa_ok($self->{frames_written}[0], 'Net::AMQP::Frame::Method', 'Has outer method frame');
    isa_ok($self->{frames_written}[0]->method_frame, 'Net::AMQP::Protocol::Basic::Get', 'Sent a Basic::Get frame');    
    
    is($res->{body}, 'a' x 200, "Body returned correctly");
    is($res->{reply_to}, undef, "No reply_to in response");
    is($res->{correlation_id}, undef, "No correlation_id in response");    
    
       
}

sub test_get_with_message_and_headers : Tests(6) {
    my $self = shift;
    
    # GIVEN
    my $msg_body = 'body';
    
    $self->{socket_read_data} = [
        $self->_create_method_frame('Basic::GetOk'),
        $self->_create_header_frame('Basic::ContentHeader', {body_size => length $msg_body, headers => { reply_to => 'me', correlation_id => 123}}),
        Net::AMQP::Frame::Body->new(payload => $msg_body),
    ];
    
    # WHEN
    my $res = $self->{amqp}->get('foo');
    
    # THEN
    is(@{ $self->{frames_written} }, 1, "1 frame written");
    
    isa_ok($self->{frames_written}[0], 'Net::AMQP::Frame::Method', 'Has outer method frame');
    isa_ok($self->{frames_written}[0]->method_frame, 'Net::AMQP::Protocol::Basic::Get', 'Sent a Basic::Get frame');    
    
    is($res->{body}, 'body', "Body returned correctly");
    is($res->{reply_to}, 'me', "reply_to in response");
    is($res->{correlation_id}, 123, "correlation_id in response");    
}

sub test_disconnect : Tests(3) {
    my $self = shift;
    
    # GIVEN
    $self->{socket_read_data} = [
        $self->_create_method_frame('Connection::CloseOk'),
    ];
    
    # WHEN
    $self->{amqp}->disconnect();
    
    # THEN
    is(@{ $self->{frames_written} }, 1, "1 frame written");
    isa_ok($self->{frames_written}[0], 'Net::AMQP::Frame::Method', 'Has outer method frame');
    isa_ok($self->{frames_written}[0]->method_frame, 'Net::AMQP::Protocol::Connection::Close', 'Sent a Connection::Close frame');    
    
       
}

sub _create_method_frame {
    my $self = shift;
    my $type = shift;
    my $params = shift;
    
    my $package = 'Net::AMQP::Protocol::'. $type; 
    
    my $frame = $package->new(
        %$params,
    );
  
    $frame = $frame->frame_wrap;
        
    return $frame;   
}

sub _create_header_frame {
    my $self = shift;
    my $type = shift;
    my $params = shift;
    
    my $body_size = delete $params->{body_size};
    
    my $frame = $self->_create_method_frame($type, $params);
    
    $frame->{body_size} = $body_size;
    
    return $frame;
}


1;
