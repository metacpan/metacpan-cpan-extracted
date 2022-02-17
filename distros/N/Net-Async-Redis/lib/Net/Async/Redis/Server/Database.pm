package Net::Async::Redis::Server::Database;

use strict;
use warnings;

our $VERSION = '3.020'; # VERSION

=head1 NAME

Net::Async::Redis::Server::Database - implementation for database-related Redis commands

=head1 DESCRIPTION

See L<Net::Async::Redis::Commands> for the full list of commands.

Most of them are not yet implemented.

=cut

use Math::Random::Secure ();

sub set : method {
    my ($self, $k, $v, @args) = @_;
    my %opt;
    while(@args) {
        my $cmd = shift @args;
        if($cmd eq 'EX') {
            $opt{ttl} = 1000 * shift @args;
        } elsif($cmd eq 'PX') {
            $opt{ttl} = shift @args;
        } elsif($cmd eq 'NX') {
            die 'Cannot set NX and XX' if exists $opt{xx};
            $opt{nx} = 1;
        } elsif($cmd eq 'XX') {
            die 'Cannot set NX and XX' if exists $opt{nx};
            $opt{xx} = 1;
        } else {
            die 'Invalid input: ' . $cmd
        }
    }
    return Future->done(undef) if not exists $self->{keys}{$k} and $opt{xx};
    return Future->done(undef) if exists $self->{keys}{$k} and $opt{nx};
    $self->{keys}{$k} = $v;
    if(exists $opt{ttl}) {
        $self->{expiry}{$k} = $opt{ttl} + $self->time;
    }
    return Future->done('OK');
}

sub get : method {
    my ($self, $k) = @_;
    return Future->done($self->{keys}{$k});
}

sub auth : method {
    my ($self, $auth) = @_;
    return Future->done('OK');
}

sub echo : method {
    my ($self, $string) = @_;
    return Future->done($string);
}

sub ping : method {
    my ($self, $string) = @_;
    return Future->done(PONG => $string);
}

sub quit : method {
    my ($self, $string) = @_;
    $self->connection->close;
    return Future->done('OK');
}

sub del : method {
    my ($self, @keys) = @_;
    return Future->done(delete @{$self->{keys}}{@keys});
}

sub exists : method {
    my ($self, @keys) = @_;
    return Future->done(map { exists $self->{keys}{$_} ? 1 : 0 } @keys);
}

sub expire : method {
    my ($self, $k, $ttl) = @_;
    return $self->pexpire($k => 1000 * $ttl);
}

sub expireat : method {
    my ($self, $k, $time) = @_;
    return $self->pexpireat($k => 1000 * $time);
}

sub pexpire : method {
    my ($self, $k, $ttl) = @_;
    $self->{expiry}{$k} = $ttl + $self->time if exists $self->{keys}{$k};
    return Future->done('OK');
}

sub pexpireat : method {
    my ($self, $k, $time) = @_;
    $self->{expiry}{$k} = $time if exists $self->{keys}{$k};
    return Future->done('OK');
}

sub keys : method {
    my ($self, $pattern) = @_;
    $pattern = '*' unless defined($pattern) and length($pattern);
    $pattern = qr/^\Q$pattern\E$/;
    $pattern =~ s{\\\*}{.*}g;
    return Future->done(grep { $_ =~ $pattern } sort keys %{$self->{keys}});
}

sub persist : method {
    my ($self, $k) = @_;
    delete $self->{expiry}{$k};
    return Future->done('OK');
}

sub randomkey : method {
    my ($self) = @_;
    return Future->done((keys %{$self->{keys}})[Math::Random::Secure::irand keys %{$self->{keys}}]);
}

sub lpush : method {
    my ($self, $k, @values) = @_;
    unshift @{$self->{keys}{$k}}, @values;
    return Future->done('OK');
}

sub rpush : method {
    my ($self, $k, @values) = @_;
    push @{$self->{keys}{$k}}, @values;
    return Future->done('OK');
}

sub brpoplpush : method {
    my ($self, $src, $dst, $timeout) = @_;
    my $v = pop @{$self->{keys}{$src}};
    unshift @{$self->{keys}{$dst}}, $v;
    return Future->done($v);
}

1;

=head1 AUTHOR

Tom Molesworth C<< <TEAM@cpan.org> >> plus contributors as mentioned in
L<Net::Async::Redis/CONTRIBUTORS>.

=head1 LICENSE

Copyright Tom Molesworth 2015-2022. Licensed under the same terms as Perl itself.

