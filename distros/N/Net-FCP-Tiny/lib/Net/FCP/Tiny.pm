package Net::FCP::Tiny;
BEGIN {
  $Net::FCP::Tiny::AUTHORITY = 'cpan:AVAR';
}
BEGIN {
  $Net::FCP::Tiny::VERSION = '0.03';
}
use strict;
use warnings;
use IO::Socket::INET;
use Exporter 'import';

sub new {
    my ($pkg, %args) = @_;

    $args{name} ||= __PACKAGE__;
    $args{host} ||= 'localhost';
    $args{port} ||= 9481;

    $args{sock} ||= IO::Socket::INET->new(
        PeerAddr => $args{host},
        PeerPort => $args{port},
        Proto    => 'tcp',
        Blocking => 1,
    );

    # Couldn't connect
    return unless $args{sock};

    my $self = bless \%args => $pkg;

    my $helo = $self->send_msg(<<'END');
ClientHello
Name=$args{$name};
ExpectedVersion=2.0
EndMessage
END

    return $self;
}

sub send_msg {
    my ($self, $msg) = @_;
    my $sock = $self->{sock};
    my @line;

    print $sock $msg;

    while (my $line = <$sock>) {
        chomp $line;
        last if $line eq 'EndMessage';
        push @line => $line;
    }

    return \@line;
}

sub array2hash {
    my ($self, $lines) = @_;
    return +{
        map {
            my ($k, $v) = split(/=/, $_, 2);
            $k => $v;
        } @$lines
    };
}

1;

__END__

=head1 NAME

Net::FCP::Tiny - A Tiny and incomplete interface to the Freenet Client Protocol (FCPv2)

=head1 SYNOPSIS

    use Net::FPC::Tiny;

    my $fcp = Net::FCP::Tiny->new(
        name => 'Freenet Munin Plugin',
        host => $ENV{FREENET_HOST},
        port => $ENV{FREENET_PORT},
    );

    my $info = $fcp->array2hash($fcp->send_msg(<<'END'));
GetNode
WithPrivate=false
WithVolatile=true
EndMessage
END

    print "Java is using ", $info->{"volatile.usedJavaMemory"}, " bytes of memory";

=head1 DESCRIPTION

This is a tiny (~60 line) and stupid wrapper that talks the Freenet
Client Protocol. It sets up a communication channel for you, and you
can L<send messages|http://new-wiki.freenetproject.org/FCPv2> by
copy/pasting examples from the FCPv2 docs.

I wrote it for L<a munin
plugin|http://github.com/avar/munin-plugin-freenet> because
L<Net::FCP> was ancient, and L<AnyEvent::FCP> hurt my brain.

=head1 AUTHOR

E<AElig>var ArnfjE<ouml>rE<eth> Bjarmason <avar@cpan.org>

=head1 LICENSE AND COPYRIGHT

Copyright 2010 E<AElig>var ArnfjE<ouml>rE<eth> Bjarmason <avar@cpan.org>

This program is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
