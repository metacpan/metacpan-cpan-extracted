package Penguin::Frame::Data;

$VERSION = "3.0";

sub new {
    my ($class, %args) = @_;
    my $self = {};
    $self->{'Text'} = $args{'Text'};
    bless $self, $class;
}

sub assemble {
    my ($self, %args) = @_;
    $self->{'Text'} = 
    "%%%delimiter%%%\n" .
    pack("u", $args{'Text'}) . 
    "%%%delimiter%%%\n";
}

sub disassemble {
    my ($self, %args) = @_;
    my @splitframe = split(/^/, $self->{'Text'});
    my $topdelimiter = shift @splitframe;
    my $bottomdelimiter = pop @splitframe;
    my $wrappedtext = join('', @splitframe) ||
                              warn("useless frame: empty code.");
    if (! ($topdelimiter eq $bottomdelimiter)) {
        warn("corrupt frame; unbalanced delimiters.");
        return 0;
    }

    return unpack("u", $wrappedtext);
}

sub contents {
    my ($self, %args) = @_;
    $self->{'Text'} = $args{'Text'} || $self->{'Text'};
}

sub type {
    "Data";
}
