############################################################################
############################################################################
##                                                                        ##
##    Copyright 2004 Stephen Patterson (steve@patter.mine.nu)             ##
##                                                                        ##
##    A cross platform perl printer interface                             ##
##    This code is made available under the perl artistic licence         ##
##                                                                        ##
##    Documentation is at the end (search for __END__) or process with    ##
##    pod2man/pod2text/pod2html                                           ##
##                                                                        ##
##    Debugging and code contributions from:                              ##
##    David W Phillips (ss0300@dfa.state.ny.us)                           ##
##                                                                        ##
############################################################################
############################################################################

# routines specifically for unix like systems (linux/bsd etc)
# $self->{system} eq 'linux'

# load environment variables which contain the default printer name (Linux)
# (from the lprng lpr command manpage)
use Env qw(PRINTER LPDEST NPRINTER NGPRINTER PATH);

############################################################################
sub list_printers {
    # list available printers
    my $self = shift();
    my %printers;
    my @prs;
    if ( -f '/etc/printcap' ) {
	# DWP - linux, dec_osf
	open (PRINTCAP, '</etc/printcap') or 
	  Carp::croak "Can't read /etc/printcap: $!";
	while (<PRINTCAP>) {
	    if ($ARG =~ /^\w/) {
		chomp $ARG;
		$ARG =~ s!\\!!;
		$ARG =~ s!|.*!!;
		push @prs, $ARG;
	    }
	}
    } elsif ( -f '/etc/printers.conf' ) {
	# DWP - solaris
	open (PRINTCNF, '</etc/printers.conf') or
	  Carp::croak "Can't read /etc/printers.conf: $!";
	while (<PRINTCNF>) {
	    if ($ARG =~ /\|/ or $ARG =~ /^[^:]+:\\/) {
		chomp $ARG;
		$ARG =~ s/[\|:].*//;
		push @prs, $ARG unless $ARG =~ /^_(?:all|default)/i;
                }
	}
    } elsif ( -d '/etc/lp/member' ) {
	# DWP - hpux
	opendir (LPMEM, '/etc/lp/member') or
	  Carp::croak "Can't readdir /etc/lp/member: $!";
	@prs = grep { /^[^\.]/ && -f "/etc/lp/member/$_" } readdir(LPMEM);
    } elsif (-e '/etc/printcap.cups') {
	# cups spooler
	open (PRINTCAP, '/etc/printcap.cups') 
	  or Carp::croak "Can't read /etc/printcap.cups: $!";
	@prs = <PRINTCAP>;
    }

    # remove : at end of each name
    foreach my $pr (@prs) {$pr =~ s/:$//;}

    $printers{name} = [ @prs ];
    $printers{port} = [ @prs ];
    return %printers;
}
#############################################################################
sub use_default {
    # select the default printer
    my $self = shift;
    if ($Env{PRINTER}) {
	$self->{'printer'}{$OSNAME} = $Env{PRINTER};
    } elsif ($Env{LPDEST}) {
	$self->{'printer'}{$OSNAME} = $Env{LPDEST};
    } elsif ($Env{NPRINTER}) {
	$self->{'printer'}{$OSNAME} = $Env{NPRINTER};
    } elsif ($Env{NGPRINTER}) {
	$self->{'printer'}{$OSNAME} = $Env{NGPRINTER};
    } elsif ( open LPDEST, 'lpstat -d |' ) {
	# DWP - lpstat -d
	my @lpd = grep { /system default destination/i } <LPDEST>;
	if ( @lpd == 0 ) {
	    Carp::cluck 
		'I can\'t determine your default printer, setting it to lp';
	    $self->{'printer'}{$OSNAME} = "lp";
	} elsif ( $lpd[-1] =~ /no system default destination/i ) {
	    Carp::cluck 'No default printer specified, setting it to lp';
	    $self->{'printer'}{$OSNAME} = "lp";
	} elsif ( $lpd[-1] =~ /system default destination:\s*(\S+)/i ) {
	    $self->{'printer'}{$OSNAME} = $1;
	}
    } else {
	Carp::cluck 'I can\'t determine your default printer, setting it to lp'; 
	$self->{'printer'}{$OSNAME} = "lp";
    }
    print "Linuxish default = $self->{printer}{$OSNAME}\n\n";
    # DWP - test
}
############################################################################
sub print {
    # print
    # $prn->print($data, -orientation => 'landscape') etc
    my ($self) = shift;
    my $data = join("", @_);

    # use standard print command
    unless ($self->{print_command}) {
	my $pr_cmd = "| lpr -P $self->{'printer'}{$OSNAME}";
	if ($self->{orientation} eq 'landscape') {
	    $pr_cmd = '| a2ps -r' . $pr_cmd;
	}
	open PRINTER, $pr_cmd
	  or Carp::croak
	  "Can't open printer connection to $self->{'printer'}{$OSNAME}: $!";
	print PRINTER $data;
	close PRINTER;
    } else {
	# user has specified a custom print command
	if ($self->{print_command}->{linux}->{type} eq 'pipe') {
	    # command accepts piped data
	    open PRINTER, "| $self->{print_command}->{linux}->{command}"
	      or Carp::croak "Can't open printer connection to $self->{print_command}->{linux}->{command}";
	    print PRINTER $data;
	    close PRINTER;
	} else {
	    # command accepts file data, not piped
	    # write $data to a temp file
	    my $spoolfile = &get_unique_spool('linux');
	    open SPOOL, ">" . $spoolfile or Carp::croak "Can't write to required temproary file $spoolfile: $!";
	    print SPOOL $data;

	    # print this file
	    my $cmd = $self->{print_command}->{linux}->{command};
	    $cmd =~ s/FILE/$spoolfile/;
	    system($cmd); 
	    # or Carp::croak "Can't execute print command: $cmd, $!\n"; 
	    # this or is being executed when it shouldn't be.
	    unlink $spoolfile;
	}

    }
}
############################################################################
sub list_jobs {
    # list the current print queue
    my $self = shift;
    my @queue;
    # use available query program, lpq preferred
    my $lpcmd;
    if ( exists $self->{'program'}{'lpq'} ) {
	$lpcmd = $self->{'program'}{'lpq'}.' -P'
    } elsif ( exists $self->{'program'}{'lpstat'} ) {
	$lpcmd = $self->{'program'}{'lpstat'}.' -o'
    } else {
	Carp::croak "Can't find lpq or lpstat prog for jobs function";
    }
    my @lpq = `$lpcmd$self->{'printer'}{$OSNAME}`;
    chomp @_;
    # lprng returns
    # Printer: lp@localhost 'HP Laserjet 4L' (dest raw1@192.168.1.1)
    # Queue: 1 printable job
    # Server: pid 7145 active
    # Status: job 'cfA986localhost.localdomain' removed at 15:34:48.157
    # Rank   Owner/ID            Class Job Files           Size Time
    # 1      steve@localhost+144   A   144 (STDIN)          708 09:45:35
    my $pr = $self->{'printer'}{$OSNAME};

    if ($lpq[0] =~ /^Printer/) {
	# first line of lpq starts with Printer
	# lprng spooler, skip first 5 lines
	for (my $i = 5; $i < @lpq; ++$i) {
	    push @queue, join(' ',(split(/\s+/,$lpq[$i]))[0,1,3..5]);
	    # DWP - fix to exclude class
	}
    } elsif ($lpq[1] =~/^Rank/) {
	# DWP - said queue, should be lpq
	# second line of BSD & solaris lpq starts with Rank
	# DWP - compressed doc, inc solaris
	# Rank   Owner   Job  Files        Total Size
	# active mwf     31   thesis.txt   682048 bytes
	for (my $i = 2; $i < @lpq; ++$i) {
	    push @queue, $lpq[$i];
	}
    } elsif ($lpq[0] =~ /^$pr-\d+\s+/ and $lpq[1] =~ / bytes/) {
	# hpux lpstat -o has multi-line entries
	#NE1-9638            da0240         priority 0  Mar 14 14:53 on NE1
	#        (standard input)                          661 bytes
	#NE1-110             ss0300         priority 0  Oct 19 12:51
	#        mediafas             [ 3 copies ]       69 bytes
	#        rescan               [ 3 copies ]       62 bytes
	my @job;
	foreach my $line ( @lpq ) {
	    if ( $line =~ /^($pr-\d+)\s+(\S+)\s+priority/ ) {
		if ( @job ) {
		    push @queue, join(' ',@job);
		    @job<5 and Carp::cluck "Short job entry: $queue[-1] ";
		}
		@job = ( 'active', $2, $1 );              # rank,owner,job
	    } elsif ( $line =~ /^\s*(\S+|\(.+\))\s.*\s(\d+)\s+bytes/ ) {
		$job[3] = $job[3] ? $job[3].",$1" : $1;   # add file(s)
		my $sz = $2;
		$line =~ /\s(\d+)\s+copies/ and ( $sz *= $1 ); # copies?
		$job[4] = $job[4] ? $job[4].",$sz" : $sz; # add size(s)
		$job[3] =~ s/ /_/g;                       # elim spaces
	    }
	}
    } elsif ( ($lpq[1] !~ /\S/) and ($lpq[2] =~/^Rank/) ) {
	# third line of dec_osf lpq starts with Rank, second is blank
	#Rank   Owner      Job  Files                        Total Size
	#active ss0300     40   lpr.doc, Printer.pm          103014 bytes
	#active ss0300     42   (standard input)             54585 bytes
	for (my $i = 3; $i < @lpq; ++$i) {
	    $lpq[$i] =~ s/,\s/,/g;                        # multi-files
	    if ( $lpq[$i] =~ /(\(.*\))/ ) {               # spaces in file
		my ($ofil,$nfil) = ($1,$1);
		$nfil =~ s/ /_/g;
		($ofil,$nfil) = (quotemeta($ofil),quotemeta($nfil));
		$lpq[$i] = s/$ofil/$nfil/;
	    }
	    push @queue, $lpq[$i];
	}
    }

    # make the queue into an array of hashes
    for (my $i = 0; $i < @queue; ++$i) {
	$queue[$i] =~ s/\s+/ /g; # remove extraneous spaces
	my @job = split / /, $queue[$i];
	$queue[$i] = {Rank  => $job[0],
		      Owner => $job[1],
		      Job   => $job[2],
		      Files => $job[3],
		      Size  => $job[4]
		     };
    }

}
#############################################################################
1;

