package MemoryEater;

our $Onasui = "";

sub new {
    my $class = shift;
    my $self = bless {
    }, $class;
    return $self;
}

sub eat {
    my $self = shift;
    my $mb   = shift || 32;
    $Onasui .= 'X' x (1024*1024*$mb);
    return length $Onasui;
}

1;
