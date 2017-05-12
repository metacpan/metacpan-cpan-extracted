package Net::Ifstat;

use warnings;
use strict;
our $VERSION = '0.01';

use base qw( Class::Accessor::Fast Class::ErrorHandler );
__PACKAGE__->mk_accessors(qw/
		ifstat
		options
		stdin
		stdout
		stderr
		command
		/);

use IPC::Run qw( run );
use Carp qw( carp );

our %options = (
		loopmon		=> '-l',
		allifs		=> '-a',
		hideidelifs	=> '-z',
		helpmsg		=> '-h',
		displayheader	=> '-n',
		ts		=> '-t',
		totalbw		=> '-T',
		ifaceidx	=> '-A',
		fixedcolwidth	=> '-w',
		wraplines	=> '-W',
		linestats	=> '-S',
		bitsstats	=> '-b',
		quietmode	=> '-q',
		verdrivers	=> '-v',

		iflist		=> '-i iflist separated by comma',
		delay		=> '-delay delaysecs',
		count		=> '-count pktcount'
		);

		sub new {
			my $class = shift;
			my $self            =  {
				ifstat          	=> shift || 'ifstat',
				options         => [],
				timeout		=> 0,
			};

			system("$self->{ifstat} -v > /dev/null 2>&1");
			my $ret = $? >> 8;
			if ( $ret != 0 and $ret != 1 ) {
				carp "Can't find ifstat command.";
				exit 0;
			}

			bless $self, $class;
		}

sub execute {
	my ($opts, %h, $delay, $count) = ();

	my $self = shift;
	$opts = $self->{options};

	%h = %{$opts};

	my @ifopts = ();
	for my $key (keys(%h)) {
		my $value = $h{$key};	
		if($key =~ /\-delay/) {
			$delay = $value;
			next;
		}
		if($key =~ /\-count/) {
			$count = $value;
			next;
		}
		if(int($value) != 1) {
			push @ifopts, $key . ' ' . $value;
		} else {
			push @ifopts, $key;
		}

	}
	my $cmd = $self->{ifstat};
	my $ifoptsline = join ' ', @ifopts;

	if(defined($delay) and defined($count)) {
		$ifoptsline = $ifoptsline . " " . join " ", $delay, $count;
	}
	
	my $fullcmd = $cmd . " " . $ifoptsline ;

	my @runcmd = split / /, $fullcmd;

	run \@runcmd;
	return 0;

}

*exec = \&execute;

__END__

=head1 NAME

Net::Ifstat - Report Interface Statistics

=head1 DESCRIPTION

Ifstat is a little tool to report interface activity, just like
       iostat/vmstat do for other system statistics.

Ifstat has two modes of operation. Batch mode and interactive
mode. In batch mode you have to give the delay and count and is suitable
for scripts. 

In the interactive mode this will keep printing stats on STDOUT
endlessly until you terminate with the keyboard interrupt.

=head1 SYNOPSIS

use Net::Ifstat;

my $ifstat = Net::Ifstat->new('/usr/local/bin/ifstat');

my $result = $ifstat->exec();
croak $ifstat->errstr unless $result;

$ifstat->exec();

$ifstat->options{
		'-b'       => 1,
		'-delay'   => 1,
		'-count'   => 5
	    };

$ifstat->exec()

	# All options in OpenBSD ifstt
		loopmon		=> '-l',
		allifs		=> '-a',
		hideidelifs	=> '-z',
		helpmsg		=> '-h',
		displayheader	=> '-n',
		ts		=> '-t',
		totalbw		=> '-T',
		ifaceidx	=> '-A',
		fixedcolwidth	=> '-w',
		wraplines	=> '-W',
		linestats	=> '-S',
		bitsstats	=> '-b',
		quietmode	=> '-q',
		verdrivers	=> '-v',

		iflist		=> '-i iflist separated by comma',
		delay		=> '-delay delaysecs',
		count		=> '-count pktcount'
		);

	$ifstat->{options} = {'-b' => 1,'-delay' => 0.2};
	$ifstat->exec();


=head1 METHODS

=head2 new('/usr/local/bin/ifstat')

	Contructs Net::Ifstat object.It takes a path of ifstat command.
	You can omit this argument and this module searches ifstat command within PATH environment variable.

	I tested and developed this on OpenBSD 5.2 ifstat. 

=head2 options( @options )

	Specify ifstat command options directly 

=head2 execute()

	Executes ifstat command with specified options.

=head2 exec()

An alias of execute()

=head2 stdout()

	Get ifstat command output to stdout.

=head2 stderr()

	Get ifstat command output to stderr.

	Specify output file name and output options.

	Avaiable options are:

=over

=item delay
	
The  delay between bandwidth updates.

=item count

The number of updates to show before exiting

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

	perldoc Net::Ifstat

	You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

	L<http://annocpan.org/dist/Net-Ifstat>

=item * CPAN Ratings

	L<http://cpanratings.perl.org/d/Net-Ifstat>

=item * RT: CPAN's request tracker

	L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Net-Ifstat>

=item * Search CPAN

	L<http://search.cpan.org/dist/Net-Ifstat>

=back

=head1 ACKNOWLEDGEMENTS

The author of Ifstat is Gael Roualland, <gael.roualland@dial.oleane.com>

=head1 COPYRIGHT & LICENSE

	Copyright 2012 Girish Venkatachalam, all rights reserved.

	This program is free software; you can redistribute it and/or modify it
	under the same terms as Perl itself.

=cut
