package Progress::PV;

use warnings;
use strict;
our $VERSION = '0.02';

use base qw( Class::Accessor::Fast Class::ErrorHandler );
__PACKAGE__->mk_accessors(qw/
		pv
		options
		stdin
		stdout
		stderr
		/);

use IPC::Run qw( run );
use Carp qw( carp );

our %options = (
		progress	=> '-p',
		timeron		=> '-t',
		etatimer	=> '-e',
		ratecnter	=> '-r',
		avgrate		=> '-a',
		bytecnter	=> '-b',
		timeron		=> '-t',
		numericop	=> '-n',
		quietmode	=> '-q',
		waitmode	=> '-W',
		forceop		=> '-f',
		cursorpos	=> '-c',
		linemode	=> '-l',
		help		=> '-h',
		version		=> '-V',

		assumesize	=> '-s SIZE',
		termwidth	=> '-w WIDTH',
		termheight	=> '-h HEIGHT',
		nameprefix	=> '-N NAME',
		ratelimit	=> '-L RATE',
		bufsize		=> '-B BYTES',
		inputfiles 	=> '-file files... (shell globbed)',
		cmd 	=> '-cmd command to run in pipe'
	);

sub new {
	my $class = shift;
	my $self            =  {
		pv          	=> shift || 'pv',
		options         => []
	};

	system("$self->{pv} -V > /dev/null 2>&1");
	my $ret = $? >> 8;
	if ( $ret != 0 and $ret != 1 ) {
		carp "Can't find pv command.";
		exit 0;
	}

	bless $self, $class;
}

sub showprogress {
	my ($opts, %h, $files, $cmd, $shcmd, @shcmd) = ();

	my $self = shift;
	$opts = $self->{options};

	%h = %{$opts};

	my @pvopts = ();
	for my $key (keys(%h)) {
		my $value = $h{$key};	
		
		if($key =~ /\-file/) {
			$files = $value;
			next;
		}
		if($key =~ /\-cmd/) {
			$shcmd = $value;
			next;
		}
		if(int($value) != 1) {
			push @pvopts, $key . ' ' . $value;
		} else {
			push @pvopts, $key;
		}

	}
	$cmd = $self->{pv};
	my $pvoptsline = join ' ', @pvopts;
	if(defined($files)) {
		$pvoptsline = $pvoptsline . " " . join " ", $files;
	} 
	
	my $fullcmd = $cmd . " " . $pvoptsline;
	$fullcmd =~ s/\s+/ /g;
	my @runcmd = split / /, $fullcmd;
	if(defined($shcmd)) {
		@shcmd = ($shcmd);
		run \@runcmd, '|', \@shcmd;
	} else {
		run \@runcmd;
	}
	return 0;

}

*pr = \&showprogress;

__END__

=head1 NAME

Progress::PV	Use the pipe viewer command from inside perl to add
progress bar to tar extraction, decompression,checksumming and so on

=head1 DESCRIPTION

pv gives you the ability to see the progress of operations that take
time. But this will not always work. Only when a single file is
processed you can view the progress. pv works as a pass through copying
STDIN to STDOUT thereby adding progress bar based on the rate of
processing STDOUT.

If no display switches are specified, pv behaves as if -p, -t, -e,
-r,
       and -b had been given (i.e. everything except average rate is
switched
       on).  Otherwise, only those display types that are explicitly
switched
       on will be shown.

 From the pv man page:

	pv allows a user to see the progress of data through a pipeline, by
       giving information such as time elapsed, percentage completed
	(with progress bar), current throughput rate, total data transferred,
	and ETA.

       To use it, insert it in a pipeline between two processes, with the
       appropriate options.  Its standard input will be passed through to its
       standard output and progress will be shown on standard error.

       pv will copy each supplied FILE in turn to standard output 
       (- means standard input), or if no FILEs are specified just standard
       input is copied. This is the same behaviour as cat(1).

       A simple example to watch how quickly a file is transferred using
       pv(1):

              pv file | pv -w 1 somewhere.com 3000


=head1 SYNOPSIS

use Progress::PV;

my $pv = Progress::PV->new('/usr/local/bin/pv');

$pv->{options} = ...

$pv->showprogress();

croak $pv->errstr unless $result;

	All options in pv

	$pv->options{
		progress	=> '-p',
		etatimer	=> '-e',
		ratecnter	=> '-r',
		avgrate		=> '-a',
		bytecnter	=> '-b',
		timeron		=> '-t',
		numericop	=> '-n',
		quietmode	=> '-q',
		waitmode	=> '-W',
		forceop		=> '-f',
		cursorpos	=> '-c',
		linemode	=> '-l',
		help		=> '-h',
		version		=> '-V',

		assumesize	=> '-s SIZE',
		termwidth	=> '-w WIDTH',
		termheight	=> '-h HEIGHT',
		nameprefix	=> '-N NAME',
		ratelimit	=> '-L RATE',
		bufsize		=> '-B BYTES',
		inputfiles 	=> '-file files... (shell globbed)',
		cmd 	=> '-cmd command to run in pipe'

	    };

	$pv->showprogress();

	For instance,

	use PV;
	
	$pv = Progress::PV->new();
	
	$pv->{options} = {'-file' => '/home/foo/chatserver.img', '-cmd' => 'sha1'};
	
	$pv->pr();


=head1 METHODS

=head2 new('/usr/local/bin/pv')

	Contructs Progress::PV object.It takes a path of pv command.
	You can omit this argument and this module searches pv command within PATH environment variable.

=head2 options{ @options }

	Specify pv command options directly 

=head2 showprogress()

	Executes pv command with specified options.

=head2 pr()

An alias of showprogress()

=head2 stdout()

	Get pv command output to stdout.

=head2 stderr()

	Get pv command output to stderr.

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

	perldoc Progress::PV

	You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

	L<http://annocpan.org/dist/Progress-PV>

=item * CPAN Ratings

	L<http://cpanratings.perl.org/d/Progress-PV>

=item * RT: CPAN's request tracker

	L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Progress-PV>

=item * Search CPAN

	L<http://search.cpan.org/dist/Progress-PV>

=back

=head1 ACKNOWLEDGEMENTS

Andrew Wood<andrew.wood@ivarch.com> is the author of pv.

=head1 COPYRIGHT & LICENSE

	Copyright 2012 Girish Venkatachalam, all rights reserved.

	This program is free software; you can redistribute it and/or modify it
	under the same terms as Perl itself.

=cut
