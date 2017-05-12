package Net::Partty;

use strict;
use warnings;
use base 'Class::Accessor::Fast';
__PACKAGE__->mk_accessors(qw/ sock host port select /);
our $VERSION = '0.03';

use Carp;
use IO::Select;
use IO::Socket::Telnet;

my $DefaultOpts = {
    host => 'www.partty.org',
    port => 2750,
};

sub new {
    my($class, %opts) = @_;

    my $self = bless {}, $class;

    for my $opt (qw/ sock host port /) {
        $self->{$opt} = delete $opts{$opt} || $DefaultOpts->{$opt};
    }

    $self->{select} = IO::Select->new;
    $self->{sock} or $self->_sock_open;

    $self;
}

sub _sock_open {
    my $self = shift;
    $self->{sock} = IO::Socket::Telnet->new(
        PeerAddr => $self->host,
        PeerPort => $self->port,
        Proto    => 'tcp',
    ) or croak $!;
    $self->select->add($self->{sock});
    $self->{sock};
}

sub _sock_close {
    my $self = shift;
    return unless $self->{sock};
    close $self->{sock};
    $self->select->remove($self->{sock});
    delete $self->{sock};
}

sub _send_uint8 {
    my($self, $int) = @_;
    my $data = pack 'C', $int;
    $self->sock->send($data);
}
sub _send_uint16 {
    my($self, $int) = @_;
    my $data = pack 'n', $int;
    $self->sock->send($data);
}

sub connect {
    my($self, %opts) = @_;

    my @params = qw( message session_name writable_password readonly_password );
    my @error;
    for my $param (@params) {
        push @error, $param unless exists $opts{$param};
    }
    croak join(', ', @error) . ' parameters is required.' if @error;

    croak 'session time out' unless $self->can_write(10);
    $self->sock->send('Partty!');
    $self->_send_uint8(2);
    for my $param (@params) {
        $self->_send_uint16(length $opts{$param});
    }
    for my $param (@params) {
        $self->sock->send($opts{$param});
    }


    croak 'session time out' unless $self->can_read(10);
    my $sock = $self->sock;
    my $buf;
    $self->sock->read($buf, 2);
    my $retcode = unpack 'n', $buf;
    $self->sock->read($buf, 2);
    my $retmessage_len = unpack 'n', $buf;
    $self->sock->read(my $retmessage, $retmessage_len);
    croak $retmessage if $retcode;
}

sub can_read {
    my($self, $time) = @_;
    $self->select->can_read($time);
}

sub can_write {
    my($self, $time) = @_;
    $self->select->can_write($time);
}

{
    package #
	IO::Socket::Telnet;
    sub sb {
        my($self, $cmd, $opt) = @_;
        $self->send(chr(255) . chr(250) . $cmd . $opt . chr(255) . chr(240));
    }
}

1;
__END__

=encoding utf8

=head1 NAME

Net::Partty - Partty.org! interface

=head1 SYNOPSIS

  use Net::Partty;
  my $partty = Net::Partty->new;
  $partty->connect(
      session_name      => 'session',
      message           => 'message',
      writable_password => 'password',
  };

=head1 DESCRIPTION

Net::Partty is Partty.org! login interface for perl.

=head1 AUTHOR

Kazuhiro Osawa E<lt>ko@yappo.ne.jpE<gt>

=head1 SEE ALSO

C<example/pertty.pl>
L<http://www.partty.org/>

=head1 REPOSITORY

  svn co http://svn.coderepos.org/share/lang/perl/Net-Partty/trunk Net-Partty

Net::Partty is Subversion repository is hosted at L<http://coderepos.org/share/>.
patches and collaborators are welcome.

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
