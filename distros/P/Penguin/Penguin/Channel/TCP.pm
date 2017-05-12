package Penguin::Channel::TCP;

# use Penguin::Frame::Code;
# use Penguin::Frame::Data;

sub close {
    my $self = shift;
    $self->{'Status'} = "not connected";
    $self->{'Socket'}->close();
}

sub putframe {
    my ($self, %args) = @_;

    if (! $self->{'Status'} eq 'connected') {
        die "can't put a frame on a closed channel";
    }

    $self->{'Socket'}->print("BEGIN " . $args{'Frame'}->type() . 
                             " $Penguin::Channel::TCP::VERSION\n");
    $self->{'Socket'}->print($args{'Frame'}->contents());
    $self->{'Socket'}->print("END " . $args{'Frame'}->type() . 
                             " $Penguin::Channel::TCP::VERSION\n");
    1;
}

sub getframe {
    my ($self, %args) = @_;
    my $frame = "";

    if (! $self->{'Status'} eq 'connected') {
        die "can't get a frame from a closed channel";
    }
 
    my $fh = $self->{'Socket'};

    chop($protocol_line = $fh->getline());
    ($begin, $type, $version) = split(/ /, $protocol_line);

    while($_ = $fh->getline()) {
        last if /^END $type $version/;
        $frame .= $_;
    }
    my $newframe;
    if ($type eq "Code") {
        $newframe = new Penguin::Frame::Code Text => $frame;
    } elsif ($type eq "Data") {
        $newframe = new Penguin::Frame::Data Text => $frame;
    } else {
        warn "unknown frame type: got \"$type\"";
        return undef;
    }
    $newframe;
}

sub getinfo {
    my ($self, %args) = @_;

    if ($self->{'Status'} eq "not connected") {
        warn "cannot getinfo on a closed channel";
        return undef;
    }

    return ($self->{'Socket'}->peerhost(),
            $self->{'Socket'}->peerport());
}
1;
