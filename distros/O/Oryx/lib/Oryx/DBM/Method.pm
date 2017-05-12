package Oryx::DBM::Method;

use base qw(Oryx::MetaClass);

sub new {
    my ($class, $meta, $owner) = @_;
    my $self = bless {
	owner => $owner,
	meta  => $meta,
    }, $class;
    return $self;
}

sub name { $_[0]->{meta}->{name} }

sub construct {

}

sub create {

}

sub retrieve {

}

sub search {

}

sub update {

}

1;
