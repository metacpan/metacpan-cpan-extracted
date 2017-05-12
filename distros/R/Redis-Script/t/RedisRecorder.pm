package t::RedisRecorder;

sub new {
    my ($class, $redis) = @_;
    return bless {
        redis  => $redis,
        record => [],
    }, $class;
}

sub AUTOLOAD {
    my $self = shift;
    my $sub = $AUTOLOAD;
    $sub =~ s/.*://;
    push @{$self->{record}}, [$sub, @_];
    return $self->{redis}->$sub(@_);
}

sub DESTROY {}

sub record {
    my $self = shift;
    return $self->{record};
}

sub reset_record {
    my $self = shift;
    $self->{record} = [];
}

1;
