package Net::YahooMessenger::Event;
use strict;

use constant YMSG_SIGNATURE => 'YMSG';
use constant YMSG_SEPARATOR => "\xC0\x80";
use constant YMSG_SALT      => '_2S43d5f';
use constant DEFAULT_OPTION => 1515563605;
use constant HIDE_LOGIN     => 12;

use constant YMSG_PROTOCOL_VERSION => '16';

use constant DATA_TYPE => {
    ID                  => 0,
    PROPOSERS_ID        => 3,
    FROM                => 1,
    RECV_FROM           => 4,
    TO                  => 5,
    CRYPTED_PASSWORD    => 6,
    BUDDY_ID            => 7,
    ONLINE_BUDDY_NUMBER => 8,
    STATUS_CODE         => 10,
    SESSION_ID          => 11,
    IS_ONLINE           => 13,
    MESSAGE             => 14,
    RECEIVING_TIME      => 15,
    ERROR_MESSAGE       => 16,
    STATUS_MESSAGE      => 19,
    BUSY_CODE           => 47,
    BUDDY_LIST          => 87,
    CHALLENGE_STRING    => 94,
};

sub new {
    my $class      = shift;
    my $connection = shift;
    bless {
        source     => '',
        code       => undef,
        option     => 0,
        connection => $connection,
    }, $class;
}

sub source {
    my $self = shift;
    $self->{source} = shift if @_;
    return $self->{source};
}

sub _get_by_name {
    my $self      = shift;
    my $name      = shift;
    my $raw_event = $self->source;
    return unless exists DATA_TYPE->{$name};
    my @param = split /\xC0\x80/, $raw_event;
    my @result;
    for ( my $i = 0 ; $i < scalar @param ; $i += 2 ) {
        my $value_type = $param[$i];
        next unless $value_type =~ /^\d+$/;
        next if DATA_TYPE->{$name} != $value_type;
        push @result, $param[ $i + 1 ];
    }
    return scalar @result <= 1 ? $result[0] : @result;
}

sub _set_by_name {
    my $self            = shift;
    my $name            = shift;
    my $value           = shift;
    my ($current_value) = $self->_get_by_name($name);
    if ( defined $current_value ) {
        my @raw_data = split /\xC0\x80/, $self->source;
        my $new_raw_data;
        for ( my $i = 0 ; $i < scalar @raw_data ; $i += 2 ) {
            next unless $raw_data[$i] =~ /^\d+$/;
            if ( DATA_TYPE->{$name} == $raw_data[$i] ) {
                $raw_data[ $i + 1 ] = $value;
            }
            $new_raw_data .=
                $raw_data[$i]
              . YMSG_SEPARATOR
              . $raw_data[ $i + 1 ]
              . YMSG_SEPARATOR;
        }
        $self->source($new_raw_data);
    }
    else {
        my $raw_event = $self->source;
        $raw_event .=
          DATA_TYPE->{$name} . YMSG_SEPARATOR . $value . YMSG_SEPARATOR;
        $self->source($raw_event);
    }
}

sub to_raw_string {
    my $self       = shift;
    my $identifier = eval { $self->get_connection->identifier; };
    my $body       = $self->source;
    $body = '' unless defined $body;

    my $header = pack 'a4xCx2nnNN',
      YMSG_SIGNATURE,
      YMSG_PROTOCOL_VERSION,
      length $body,
      $self->code,
      $self->option,
      $identifier || "\x00" x 4;
    return $header . $body;
}

sub get_connection {
    my $self = shift;
    $self->{connection} = shift if @_;
    $self->{connection};
}

sub connection {
    my $self = shift;
    $self->get_connection(@_);
}

sub from {
    my $self = shift;
    $self->_set_by_name( 'FROM', shift ) if @_;
    return $self->_get_by_name('FROM');
}

sub body {
    my $self = shift;
    $self->_set_by_name( 'MESSAGE', shift ) if @_;
    return $self->_get_by_name('MESSAGE');
}

sub to {
    my $self = shift;
    $self->_set_by_name( 'TO', shift ) if @_;
    return $self->_get_by_name('TO');
}

sub option {
    my $self = shift;
    $self->{option} = shift if @_;
    $self->{option};
}

sub code {
    my $self = shift;
    $self->{code} = shift if @_;
    return $self->{code};
}

sub is_enable { 1 }

sub to_string {
    my $self = shift;

    # event handler;
}

1;
__END__
