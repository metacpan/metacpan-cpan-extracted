package Tapper::TestSuite::Netperf::Server;
BEGIN {
  $Tapper::TestSuite::Netperf::Server::AUTHORITY = 'cpan:TAPPER';
}
{
  $Tapper::TestSuite::Netperf::Server::VERSION = '4.1.1';
}
# ABSTRACT: Tapper - Network performance measurements - Server

        use Moose;
        use IO::Handle;
        use IO::Socket::INET;

        sub run {
                my ($self) = @_;

                my $srv = IO::Socket::INET->new( LocalPort => 5000, Listen => 5);
                return "Can not open server socket:$!" if not $srv;
                my $msg_sock = $srv->accept();
                my $buf;
                while ($msg_sock->sysread($buf, 1024)) {
                        $msg_sock->syswrite($buf, length($buf));
                }
                return 0;
        }

1;



=pod

=encoding utf-8

=head1 NAME

Tapper::TestSuite::Netperf::Server - Tapper - Network performance measurements - Server

=head1 SYNOPSIS

You most likely want to run the frontend cmdline tool like this

  # host 1
  $ tapper-testsuite-netperf-server

  # host 2
  $ tapper-testsuite-netperf-client

=head1 METHODS

=head2 run

Main function of Netperf::Server.

@return success - 0
@return error   - error string

=head1 AUTHOR

AMD OSRC Tapper Team <tapper@amd64.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2012 by Advanced Micro Devices, Inc..

This is free software, licensed under:

  The (two-clause) FreeBSD License

=cut


__END__

