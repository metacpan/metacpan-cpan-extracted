package Penguin::Frame::Code;

$VERSION = "3.0";

sub new {
    my ($class, %args) = @_;
    my $self = {};
    $self->{'Text'} = $args{'Text'};
    $self->{'Wrapper'} = $args{'Wrapper'} || "Penguin::Wrapper::Transparent";
    bless $self, $class;
}

sub assemble {
    my ($self, %args) = @_;
    my $wrapobject = $self->{'Wrapper'}->new;
    my $signedtext = wrap $wrapobject Password => $args{'Password'},
                                      Text     => $args{'Text'};
    $self->{'Text'} = 
    "Penguin ${Penguin::VERSION} P${Penguin::Frame::Code::VERSION}\n" .
    "checksum\n" .
    "$args{'Title'}\n" .
    "$args{'Name'}\n" .
    "$wrapobject->{'Wrapmethod'}\n" .
    "%%%delimiter%%%\n" .
    "$signedtext" .
    "%%%delimiter%%%\n";
}

sub disassemble {
    my ($self, %args) = @_;
    my @splitframe = split(/^/, $self->{'Text'});
    chop(my $versions = shift @splitframe);
    chop(my $md5sum = shift @splitframe);
    chop(my $title = shift @splitframe);
    chop(my $signing_authority = shift @splitframe);
    chop(my $wrapmethod = shift @splitframe);
    my $topdelimiter = shift @splitframe;
    my $bottomdelimiter = pop @splitframe;
    my $wrappedtext = join('', @splitframe);
    if (! ($topdelimiter eq $bottomdelimiter)) {
        warn("unbalanced delimiters");
        return 0;
    }

    $self->{'Wrapper'} = "Penguin::Wrapper::$wrapmethod";
    my $wrapobject = new $self->{'Wrapper'};
    my ($signer, $unwrappedtext) = unwrap $wrapobject
                                        Password => $args{'Password'},
                                        Text     => $wrappedtext;
    return ($title, $signer, $wrapmethod, $unwrappedtext);
}

sub contents {
    my ($self, %args) = @_;
    $self->{'Text'} = $args{'Text'} || $self->{'Text'};
}

sub type {
    "Code";
}
