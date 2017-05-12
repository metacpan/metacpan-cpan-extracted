# $Id: Channel.pm 37 2008-03-09 01:10:00Z maletin $
# $URL: http://svn.berlios.de/svnroot/repos/cpan-teamspeak/cpan/trunk/lib/Teamspeak/Telnet/Channel.pm $

package Teamspeak::Telnet::Channel;
my @ISA = qw( Teamspeak::Channel );

my @_parameters = (
    'id',    'name',     'topic',    'parent',
    'flags', 'maxusers', 'password', 'order'
);

sub parameter {
    return @_telnet_ch_parameters;
}

sub new {
    my ( $class, %arg ) = @_;
    bless {
        id       => $arg{id},
        parent   => $arg{parent},
        order    => $arg{order},
        maxusers => $arg{maxusers},
        name     => $arg{name},
        flags    => $arg{flags},
        password => $arg{password},
        topic    => $arg{topic},
        },
        ref($class) || $class;
}    # new

sub id {
    my $self = shift;
    return $self->{id};
}

sub codec {
    my $self = shift;
    return $self->{codec};
}

sub parent {
    my $self = shift;
    return $self->{parent};
}

sub order {
    my $self = shift;
    return $self->{order};
}

sub maxusers {
    my $self = shift;
    return $self->{maxusers};
}

sub name {
    my $self = shift;
    return $self->{name};
}

sub flags {
    my $self = shift;
    return $self->{flags};
}

sub password {
    my $self = shift;
    return $self->{password};
}

sub topic {
    my $self = shift;
    return $self->{topic};
}    # topic

1;

__END__

=head1 NAME

Teamspeak::Telnet::Channel - Datastructure for a Teamspeak-Channel.

=head2 parameter()

=head2 new()

=head2 id()

=head2 codec()

=head2 parent()

=head2 order()

=head2 maxusers()

=head2 name()

=head2 flags()

=head2 password()

=head2 topic()

=cut
