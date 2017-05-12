package Net::Netcat;

use warnings;
use strict;
our $VERSION = '0.05';

use base qw( Class::Accessor::Fast Class::ErrorHandler );
__PACKAGE__->mk_accessors(qw/
		netcat
		options
		timeout
		stdin
		stdout
		stderr
		command
		/);

use IPC::Run qw( run );
use Carp qw( carp );

our %options = (
		ipv4only	=> '-4',
		ipv6only	=> '-6',
		staylistening	=> '-k',
		listenmode	=> '-l',
		nodns		=> '-n',
		randomports	=> '-r',
		md5sign		=> '-S',
		rfc854telnet	=> '-y',
		unixsocket	=> '-U',
		udpsocket	=> '-u',
		verbose		=> '-v',
		scanmode	=> '-z',

		tcprecvbuff	=> '-I length',
		tcpsendbuff	=> '-O length',
		delaypkt	=> '-i interval',
		sourceport	=> '-p source_port',
		sourceip	=> '-s source',
		toskeyword	=> '-T tos',
		timeout		=> '-w timeout',
		port		=> '-port port',
		dest		=> '-dest destination_to_connect_to'
		);

		sub new {
			my $class = shift;
			my $self            =  {
				nc          	=> shift || 'nc',
				options         => [],
				timeout		=> 0,
			};

			system("$self->{nc} > /dev/null 2>&1");
			my $ret = $? >> 8;
			if ( $ret != 0 and $ret != 1 ) {
				carp "Can't find nc command.";
				exit 0;
			}

			bless $self, $class;
		}

sub execute {
	my ($lflag, $printflg, $opts, %h, $ncdest, $ncport, $uflag) = ();

	my $self = shift;
	$opts = $self->{options};

	%h = %{$opts};

	my @ncopts = ();
	for my $key (keys(%h)) {
		my $value = $h{$key};	
		if($key =~ /\-port/) {
			$ncport = $value;
			next;
		}
		if($key =~ /\-dest/) {
			$ncdest = $value;
			next;
		}
		if(int($value) != 1) {
			push @ncopts, $key . ' ' . $value;
		} else {
			$printflg = 1 if ($key =~ /\-v/);
			$uflag = 1 if ($key =~ /\-U/);
			$lflag = 1 if ($key =~ /\-l/);
			push @ncopts, $key;
		}

	}
	my $cmd = $self->{nc};
	my $ncoptsline = join ' ', @ncopts;
	if(defined($ncdest) and $ncdest =~ /\S/ and defined($uflag) and $uflag == 1) {
		$ncoptsline = $ncoptsline . " " . $ncdest;
	} elsif(defined($ncport) and $ncport =~ /\d/ and defined($lflag) and $lflag == 1) {
		$ncoptsline = $ncoptsline . " " . $ncport;
	} elsif(defined($ncdest) and $ncdest =~ /\S/ and defined($ncport) and $ncport =~ /\d/) {
		$ncoptsline = $ncoptsline . " " . join " ", $ncdest, $ncport;
	}
	my $fullcmd = $cmd . " " . $ncoptsline ;
	print "Command line is: $fullcmd\n" if(defined($printflg) and $printflg == 1);
	my @runcmd = split / /, $fullcmd;

	run \@runcmd;
	return 0;

}

*exec = \&execute;

__END__

=head1 NAME

Net::Netcat - A wrapper class for nc Swiss army knife of networking

=head1 DESCRIPTION

A simple interface for using netcat command line utility. You can run
TCP, UDP or UNIX domain servers and clients.

=head1 SYNOPSIS

use Net::Netcat;

my $nc = Net::Netcat->new('/usr/bin/nc');

my $result = $nc->exec();
croak $nc->errstr unless $result;

$nc->exec();

$nc->options{
		'-s'       => 'source IP',
		'-p' 	   => 'source port',
	    };

$nc->exec()

	# All options in OpenBSD netcat
	ipv4only            => '-4',
	ipv6only            => '-6',
	staylistening       => '-k',
	listenmode          => '-l',
	nodns               => '-n',
	randomports         => '-r',
	md5sign             => '-S',
	rfc854telnet        => '-y',
	unixsocket          => '-U',
	udpsocket           => '-u',
	verbose             => '-v',
	scanmode            => '-z',
	tcprecvbuff         => '-I length',
	tcpsendbuff         => '-O length',
	delaypkt            => '-i interval',
	sourceport          => '-p source_port',
	sourceip            => '-s source',
	toskeyword          => '-T tos',
	timeout             => '-w timeout',
	port		    => '-port port',
	dest		    => '-dest destination_to_connect_to'

	$nc->options{'-v' => 1,'-4' => 1, '-l' => 1, 'port' => 2300};
	$nc->exec();


=head1 METHODS

=head2 new('/usr/bin/nc')

	Contructs Net::Netcat object.It takes a path of netcat command.
	You can omit this argument and this module searches netcat command within PATH environment variable.

	I tested and developed this on OpenBSD 5.2 netcat. This is
substantially different from Linux netcat. So kindly sene me bug
reports.

	There seems to be a bug in netcat with UNIX domain sockets and
the verbose flag. So don't use that combo. Usually you have to
terminate the command with the Ctrl-C keyboard interrupt signal. You
could also redirect the output to a file if desired.

=head2 options( @options )

	Specify netcat command options directly 

=head2 execute()

	Executes netcat command with specified options.

=head2 exec()

An alias of execute()

=head2 stdout()

	Get netcat command output to stdout.

=head2 stderr()

	Get netcat command output to stderr.

	Specify output file name and output options.

	Avaiable options are:

=over

=item destination

	The destination IP address to connect to or in case of UNIX
domain sockets the destination socket file to connect to

=item port

	The port to connect to

=item author

	Set the author.

=item comment

	Set the comment.

=back

=head1 AUTHOR

	Girish Venkatachalam, <girish at gayatri-hitech.com> 


=head1 BUGS

	Please report any bugs or feature requests to
	C<bug-text-cowsay at rt.cpan.org>, or through the web interface at
	L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=text-cowsay>.
	I will be notified, and then you'll automatically be notified of progress on
	your bug as I make changes.

=head1 SUPPORT

	You can find documentation for this module with the perldoc command.

	perldoc Net::Netcat

	You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

	L<http://annocpan.org/dist/Net-Netcat>

=item * CPAN Ratings

	L<http://cpanratings.perl.org/d/Net-Netcat>

=item * RT: CPAN's request tracker

	L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Net-Netcat>

=item * Search CPAN

	L<http://search.cpan.org/dist/Net-Netcat>

=back

=head1 ACKNOWLEDGEMENTS

The author of Netcat Hobbit who remains anonymous to this day.

=head1 COPYRIGHT & LICENSE

	Copyright 2012 Girish Venkatachalam, all rights reserved.

	This program is free software; you can redistribute it and/or modify it
	under the same terms as Perl itself.

=cut
