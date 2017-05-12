package Penguin::Rights;
$VERSION = 3.0;

sub new {
    my ($class, %args) = @_;
    
    $self = { };
    bless $self, $class;
    if ($args{'Filename'}) {
        get $self Filename => $args{'Filename'};
    }
    $self;
}

sub get {
    my ($self, %args) = @_;
    my $filename = $args{'Filename'} || $self->{'filename'}
                                    || "$ENV{'HOME'}/.rightsfile"; # last ditch
    my $user = "default";

    $self->{'filename'} = $filename;
    open(RIGHTSFILE, "<$filename") || die("can't open rightsfile $filename!");
    while(chomp($line = <RIGHTSFILE>)) {
        $line =~ s/#.*//g;  # get rid of comments
        if ($line =~ /^\[(.*)\]/) {
            $user = $1;
            next;
        }
        next unless $line;
        $self->{'Data'}->{$user} .= $line . " "; # delimit?
    }
    close(RIGHTSFILE);
    1;
}

sub save {
    my ($self, %args) = @_;
    my $filename = $args{'Filename'} || $self->{'filename'};

    if (! $filename) {
        die("Rights can't save: no filename provided or implicit");
    }
    open(RIGHTSFILE, ">$filename") || 
                                die "can't save: can't write to $filename!";
    print RIGHTSFILE "# automatically generated.\n";
    foreach $i (sort keys %{ $self->{'Data'} }) {
        print RIGHTSFILE "[$i]\n$self->{'Data'}->{$i}\n";
    }
    close(RIGHTSFILE);
    1;
}

sub set {
    my ($self, %args) = @_;
    my $user = $args{'User'};
    my $rights = $args{'Rights'};
    
    $self->{'Data'}->{$user} = $rights;
    1;
}

sub erase {
    my ($self, %args) = @_;
    my $user = $args{'User'};

    undef $self->{'Data'}->{$user};
    1;
}

sub getrights {
    my ($self, %args) = @_;
    my $user = $args{'User'};

    $self->{'Data'}->{$user} || $self->{'Data'}->{'default'};
}

1;
