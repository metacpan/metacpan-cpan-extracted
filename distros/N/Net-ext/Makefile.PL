#!perl

# Copyright 1995,2002 Spider Boardman.
# All rights reserved.
#
# Automatic licensing for this software is available.  This software
# can be copied and used under the terms of the GNU Public License,
# version 1 or (at your option) any later version, or under the
# terms of the Artistic license.  Both of these can be found with
# the Perl distribution, which this software is intended to augment.
#
# THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR
# IMPLIED WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED
# WARRANTIES OF MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.
  
# rcsid: "@(#) $Id: Makefile.PL,v 1.23 2002/03/30 11:32:09 spider Exp $"

use 5.004_04;
use ExtUtils::MakeMaker qw(WriteMakefile $Verbose);
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

# some setup for building the associated .h file for Gen.c to include.
# Most of the setup is in routine MY::post_constants below.

my $tempfile	= "netgenh.new";
my $hfile	= "netgen.h";

END { unlink $tempfile }

# This is wrapped in a sub so that it's here where you expected it to be
# for easy customisation, but it won't take effect until the sub is called
# after other initialisation is done.
my @delfiles = ($tempfile, $hfile);
sub runMM {
WriteMakefile(
    'NAME'	=> 'Net::Gen',
    'DISTNAME'	=> 'Net-ext',
    'VERSION_FROM' => 'lib/Net/Gen.pm', # finds $VERSION
    "$]" ge "5.005" ?
		('ABSTRACT'	=>
			'Provide OO socket manipulations, including friendly [get/set]sockopt',
		 'AUTHOR'	=>
			'Spider Boardman <spidb@cpan.org>'
		)
		: ()
		,
    'LIBS'	=> [''],   # e.g., '-lm' 
    'DEFINE'	=> '',     # e.g., '-DHAVE_SOMETHING'
			   # DEFINE is modified by hint-files.
    'INC'	=> '',     # e.g., '-I/usr/include/other' 
    'dist'	=> {
		CI		=>	'ci -u -M',
		COMPRESS	=>	'gzip -9fNv',
		SUFFIX		=>	'.gz',
		TARFLAGS	=>	'cvof',
		},
    'clean'	=> {
		FILES	=>	qq[@delfiles],
		},
    'H'		=> [$hfile],
    'CONFIG'	=> [qw(usrinc locincpth)],
#    'MAN3PODS'	=> {},
);
}

# Fix up NOOP for my development environment.

sub MY::post_initialize
{
    my $self = shift;
    $self->{NOOP} = ':' if $^O eq 'dec_osf';
    $self->{FULLPERL} .= ' -Ixlib' if $] < 5.004_05;
    $self->MM::post_initialize(@_);
}

# Since the .h file is dependent upon this Makefile.PL file, an override
# is needed to generate the dependency rules properly.

sub MY::makefile
{
    my $self = shift;
    my $text = $self->MM::makefile(@_);
    $text =~ s/^($self->{MAKEFILE} : Makefile.PL\b)/$hfile $1/m;
    $text;
}

# I got tired of having my backup files 'installed' by the default
# Makefile....

# Also, we need a dummy version of attrs.pm for older perls.

my $have_attributes = eval 'sub dummy : locked { 1;} 1;';
my $have_attrs = $have_attributes || eval 'sub dummy { use attrs "locked"; 1} 1;';

sub MY::libscan
{
    my $self = shift;
    return ''
	if $_[0] =~ /\~$/ or
	    $_[0] =~ /\.ORIG$/i or
		$_[0] =~ /\.dat$/ or
		    $_[0] =~ m,(?:^|/)Net-ext-, or
			$_[0] =~ m,(?:^|/)(?:OLD|DL)$, or
			    $_[0] =~ m,(?:^|/)attrs\.pm$, and $have_attrs
				;
    $self->MM::libscan(@_);
}

# Here we create .pm files from the .dat files, based on whether we
# have C<sub : attrs> or are stuck with C<use attrs qw(attrs)>.

sub gen_pm_files ()
{
    open MANI, "<MANIFEST" or die "Cannot read MANIFEST file: $!";
    my @datfiles = grep { m/dat$/ } <MANI>;
    close MANI;
    chomp @datfiles;
    my $file;
    for $file (@datfiles) {
	my $outfile = $file;
	$outfile =~ s/dat$/pm/;
	unlink $outfile;
	next if $file eq 'lib/attrs.dat' and $have_attrs;
	open $file, "<$file" or die "Cannot read $file file: $!";
	open $outfile, ">$outfile" or die "Cannot write $outfile file: $!";
	#workaround for PAUSE indexer problem.
	#push @delfiles, $outfile;
	my $line;
	my $attrlist;
	while (defined($line = <$file>)) {
	    if ($attrlist) {
		if ($have_attributes) {
		    if ($line =~ m/^sub /) {
			$line =~ s/$/ : $attrlist/;
			undef $attrlist;
		    }
		}
		else {
		    if ($line =~ m/^[\{]/) { #'}' for vi's sake
			$line .= "    use attrs qw($attrlist);\n";
			undef $attrlist;
		    }
		}
	    }
	    unless ($line =~ m/^[\#][+]attrs (.*)$/) {
		print $outfile $line;
		next;
	    }
	    $attrlist = "$1"; # stringify to copy now, not later
	}
	close $outfile or die "Error writing $outfile file: $!";
	close $file or die "Error reading $file file: $!";
	print "Created $outfile from $file\n";
    }
}

# Here are some possible include files which we'll need if the system
# has them.  Add to this (and let me know!) if you find one that your
# system has to have to get some of the constants defined.
#
# Also, if you get other compilation problems besides undefined values,
# such as "incomplete type" problems, you may need to add additional system
# headers here.  For "incomplete type" in particular, you'll need to find
# which header file provides the missing information to complete a type
# (usually a union or a struct, possibly embedded inside another, and often
# also involving a typedef).  While this has been done for ULTRIX, old SunOS,
# some versions of Linux, and some versions of Solaris, I don't claim that
# the current list is complete.

my @hfiles = qw(
	netinet/in_systm.h
	netinet/in_system.h
	netinet/ip.h
	netinet/ip_icmp.h
        netinet/ip_tcp.h
	netinet/ip_var.h
	netinet/tcp.h
	inet/common.h
	netinet/tcpip.h
);

# Here are some symbols which should have system-independent values.
# If they're not found in your system header files, they'll be defined
# with the values here.

my %defdefines = (
	IPPROTO_IP		=>		'0',
	IPPROTO_ICMP		=>		'1',
	IPPROTO_IGMP		=>		'2',
	IPPROTO_GGP		=>		'3',
	IPPROTO_IPIP		=>		'4',
	IPPROTO_TCP		=>		'6',
	IPPROTO_EGP		=>		'8',
	IPPROTO_PUP		=>		'12',
	IPPROTO_UDP		=>		'17',
	IPPROTO_IDP		=>		'22',
	IPPROTO_TP		=>		'29',
	IPPROTO_RSVP		=>		'46',
	IPPROTO_HELLO		=>		'63',
	IPPROTO_EON		=>		'80',

	IPPROTO_RAW		=>		'255',
	IPPROTO_MAX		=>		'256',

	IPPORT_RESERVED		=>		'1024',
	IPPORT_USERRESERVED	=>		'5000',
	IPPORT_DYNAMIC		=>		'49152',

	IN_CLASSA_NET		=>		'((U32)0xff000000)',
	IN_CLASSA_NSHIFT	=>		'24',
	IN_CLASSA_HOST		=>		'((U32)0x00ffffff)',
	IN_CLASSA_MAX		=>		'128',

	IN_CLASSB_NET		=>		'((U32)0xffff0000)',
	IN_CLASSB_NSHIFT	=>		'16',
	IN_CLASSB_HOST		=>		'((U32)0x0000ffff)',
	IN_CLASSB_MAX		=>		'65536',

	IN_CLASSC_NET		=>		'((U32)0xffffff00)',
	IN_CLASSC_NSHIFT	=>		'8',
	IN_CLASSC_HOST		=>		'((U32)0x000000ff)',
	IN_CLASSC_MAX		=>		'(256*256*256)',

	IN_CLASSD_NET		=>		'((U32)0xf0000000)',
	IN_CLASSD_NSHIFT	=>		'28',
	IN_CLASSD_HOST		=>		'((U32)0x0fffffff)',

	INADDR_UNSPEC_GROUP	=>		'((U32)0xe0000000)',
	INADDR_ALLHOSTS_GROUP	=>		'((U32)0xe0000001)',
	INADDR_ALLRTRS_GROUP	=>		'((U32)0xe0000002)',
	INADDR_MAX_LOCAL_GROUP	=>		'((U32)0xe00000ff)',

	IN_LOOPBACKNET		=>		'127',

	IPVERSION		=>		'4',
	IP_DF			=>		'0x4000',
	IP_MF			=>		'0x2000',

	IP_MAXPACKET		=>		'65535',

	IPTOS_LOWDELAY		=>		'0x10',
	IPTOS_THROUGHPUT	=>		'0x08',
	IPTOS_RELIABILITY	=>		'0x04',

	IPTOS_PREC_NETCONTROL		=>	'0xe0',
	IPTOS_PREC_INTERNETCONTROL	=>	'0xc0',
	IPTOS_PREC_CRITIC_ECP		=>	'0xa0',
	IPTOS_PREC_FLASHOVERRIDE	=>	'0x80',
	IPTOS_PREC_FLASH		=>	'0x60',
	IPTOS_PREC_IMMEDIATE		=>	'0x40',
	IPTOS_PREC_PRIORITY		=>	'0x20',
	IPTOS_PREC_ROUTINE		=>	'0x10',

	IPOPT_CONTROL		=>		'0x00',
	IPOPT_RESERVED1		=>		'0x20',
	IPOPT_DEBMEAS		=>		'0x40',
	IPOPT_RESERVED2		=>		'0x60',

	IPOPT_EOL		=>		'0',
	IPOPT_NOP		=>		'1',

	IPOPT_RR		=>		'7',
	IPOPT_TS		=>		'68',
	IPOPT_SECURITY		=>		'130',
	IPOPT_LSRR		=>		'131',
	IPOPT_RIPSO_AUX         =>		'133',
	IPOPT_CIPSO             =>		'134',
	IPOPT_SATID		=>		'136',
	IPOPT_SSRR		=>		'137',

	IPOPT_OPTVAL            =>		'0',
	IPOPT_OLEN              =>		'1',
	IPOPT_OFFSET            =>		'2',
	IPOPT_MINOFF            =>		'4',
	MAX_IPOPTLEN            =>		'40',


	IPOPT_TS_TSONLY		=>		'0',
	IPOPT_TS_TSANDADDR	=>		'1',
	IPOPT_TS_PRESPEC	=>		'2',
	IPOPT_TS_PRESPEC	=>		'3',

	IPOPT_SECUR_UNCLASS	=>		'0x0000',
	IPOPT_SECUR_CONFID	=>		'0xf135',
	IPOPT_SECUR_EFTO	=>		'0x789a',
	IPOPT_SECUR_MMMM	=>		'0xbc4d',
	IPOPT_SECUR_RESTR	=>		'0xaf13',
	IPOPT_SECUR_SECRET	=>		'0xd788',
	IPOPT_SECUR_TOPSECRET	=>		'0x6bc5',

	MAXTTL			=>		'255',
	MINTTL          	=>		'1',
	DEFTTL          	=>		'64',
	IPTTLDEC		=>		'1',

	IP_MSS			=>		'576',

	ICMP_MINLEN		=>		'8',
	ICMP_TSLEN		=>		'(8 + 3 * 4)',
	ICMP_MASKLEN		=>		'12',
	ICMP_ADVLENMIN		=>		'(8 + 1+1+3*2+1+1+2+2*4 + 8)',

	ICMP_ECHOREPLY		=>		'0',
	ICMP_UNREACH		=>		'3',
		ICMP_UNREACH_NET	=>		'0',
		ICMP_UNREACH_HOST	=>		'1',
		ICMP_UNREACH_PROTOCOL	=>		'2',
		ICMP_UNREACH_PORT	=>		'3',
		ICMP_UNREACH_NEEDFRAG	=>		'4',
		ICMP_UNREACH_SRCFAIL	=>		'5',
	ICMP_SOURCEQUENCH	=>		'4',
	ICMP_REDIRECT		=>		'5',
		ICMP_REDIRECT_NET	=>		'0',
		ICMP_REDIRECT_HOST	=>		'1',
		ICMP_REDIRECT_TOSNET	=>		'2',
		ICMP_REDIRECT_TOSHOST	=>		'3',
	ICMP_ECHO		=>		'8',
	ICMP_TIMXCEED		=>		'11',
		ICMP_TIMXCEED_INTRANS	=>		'0',
		ICMP_TIMXCEED_REASS	=>		'1',
	ICMP_PARAMPROB		=>		'12',
	ICMP_TSTAMP		=>		'13',
	ICMP_TSTAMPREPLY	=>		'14',
	ICMP_IREQ		=>		'15',
	ICMP_IREQREPLY		=>		'16',
	ICMP_MASKREQ		=>		'17',
	ICMP_MASKREPLY		=>		'18',

	ICMP_MAXTYPE		=>		'18',

	TCPOPT_EOL		=>		'0',
	TCPOPT_NOP		=>		'1',
	TCPOPT_MAXSEG		=>		'2',
	TCPOPT_WINDOW   	=>		'3',

	TCP_MAXWIN		=>		'65535',
	TCP_MAX_WINSHIFT	=>		'14',

	TCP_MSS			=>		'536',
	TCP_MSS_IETF		=>		'536',

	TH_FIN			=>		'0x01',
	TH_SYN			=>		'0x02',
	TH_RST			=>		'0x04',
	TH_PUSH			=>		'0x08',
	TH_ACK			=>		'0x10',
	TH_URG			=>		'0x20',

# This one doesn't really belong here, except for its venerable status as
# the default in older BSD code.

	SOMAXCONN		=>		'5',

);

# Add some errno values (and related stuff), just to make life simpler by
# knowing that the symbols will be defined, even if they've been defaulted
# to 0.

my @errdefs = qw(EINPROGRESS EALREADY ENOTSOCK EDESTADDRREQ
		 EMSGSIZE EPROTOTYPE ENOPROTOOPT EPROTONOSUPPORT
		 ESOCKTNOSUPPORT EOPNOTSUPP EPFNOSUPPORT EAFNOSUPPORT
		 EADDRINUSE EADDRNOTAVAIL ENETDOWN ENETUNREACH ENETRESET
		 ECONNABORTED ECONNRESET ENOBUFS EISCONN ENOTCONN
		 ESHUTDOWN ETOOMANYREFS ETIMEDOUT
		 ECONNREFUSED EHOSTDOWN EHOSTUNREACH
		 ENOSR ETIME EBADMSG EPROTO ENODATA ENOSTR
		 MSG_OOB
		);

@defdefines{@errdefs} = ('0') x @errdefs;

# Here for macros with 1 argument, which will be _A here.

my %def1args = (
	IN_CLASSA	=>	'(((U32)(_A) & 0x80000000) == 0)',
	IN_CLASSB	=>	'(((U32)(_A) & 0xc0000000) == 0x80000000)',
	IN_CLASSC	=>	'(((U32)(_A) & 0xe0000000) == 0xc0000000)',
	IN_CLASSD	=>	'(((U32)(_A) & 0xf0000000) == 0xe0000000)',
	IN_MULTICAST	=>	'IN_CLASSD((_A))',
	IN_EXPERIMENTAL	=>	'IN_BADCLASS((_A))',
	IN_BADCLASS	=>	'(((U32)(_A) & 0xf0000000) == 0xf0000000)',

	IPOPT_COPIED	=>	'((_A)&0x80)',
	IPOPT_CLASS	=>	'((_A)&0x60)',
	IPOPT_NUMBER	=>	'((_A)&0x1f)',

	ICMP_INFOTYPE	=>	'(((UV)(_A)<19)&&((1L<<(_A)) & 0x7e101L))',

);

# Here is where the .h file gets written.  It's done this way so that
# a `perl Makefile.PL'-time override of INC will be noticed here in the
# search for system include files.
# However, for sanity while debugging, the hfile-writer is not in the
# pseudo-package which MM moves around.

sub write_hfile
{
    my ($self) = @_;
    local($_);		# protect outside users of $_;
    # collect include dirs from cc flags and Configure.
    # How do I fix this up for non-UNIX systems?
    my (@idirs) = grep(s/^-I// && $_, split(' ', $self->{INC}),
					split(' ', $self->{CCFLAGS}));
    my %idir;
    # Mark these as 'seen' by -I values.
    @idir{@idirs} = (1) x @idirs;
    push(@idirs, split(' ', $self->{LOCINCPTH}), split(' ', $self->{USRINC}));
    # usrinc is normally found implicitly as well.
    $idir{$self->{USRINC}} = 1
	unless " $self->{INC} $self->{CCFLAGS} " =~ / -I /;
    # stick to those which exist
    print STDERR "Searching for include directories\n"
	if $Verbose >= 2;
    @idirs = grep(($_ ne '') && (-d $_), @idirs);
    my ($hf, @found);
    my ($dir);
    # search for system-dependent include files
    print STDERR "Searching for system-dependent include files\n"
	if $Verbose >= 1;
    for $hf (@hfiles) {
	for $dir (@idirs) {
	    if (-f "$dir/$hf" && -r _) {
		if ($idir{$dir}) {
		    push(@found, $hf);
		}
		else {
		    push(@found, "$dir/$hf");
		}
		print STDERR " - found $found[-1]\n" if $Verbose >= 2;
		last;
	    }
	}
    }
    print STDERR "Producing $hfile\n" if $Verbose >= 1;
    local(*HF);
    open(HF,">$tempfile") or
	die "Failure opening temporary file `$tempfile' for `$hfile': $!\n";
    print HF <<EOH;
/*
 * This file was produced automatically by Makefile.PL.
 * Any edits made here will be lost!
 * File $hfile for $self->{DISTNAME}-$self->{VERSION} written ${\scalar(localtime)}.
 */

EOH
    for $hf (@found) {
	print HF "#include\t<$hf>\n";
    }
    print HF "\n";	# separate the sections
    my $macro;
    my $width = 0;
    # find longest name, just to keep output aligned
    while (($macro) = each %defdefines) {
	$width = length($macro) if length($macro) > $width;
    }
    # convert to a standard tab stop, ensuring a minimum of one tab.
    $width = int(($width+(7+1))/8);
    for $macro (sort keys %defdefines) {
	print HF "#ifndef\t$macro\n#define\t$macro";
	print HF +("\t" x ($width - int(length($macro)/8)));
	print HF $defdefines{$macro},"\n#endif\n";
    }
    print HF "\n";	# separate the sections
    # start over on max. name length for this section
    $width = 0;
    while (($macro) = each %def1args) {
	$width = length($macro) if length($macro) > $width;
    }
    # convert to a standard tab stop allowing for the "(_A)"
    $width = int(($width+(7+1+4))/8);
    for $macro (sort keys %def1args) {
	print HF "#ifndef\t$macro\n#define\t$macro(_A)";
	print HF +("\t" x ($width - int((length($macro)+4)/8)));
	print HF $def1args{$macro},"\n#endif\n";
    }
    # OK, write the trailer (finally checking error status, which should
    # be 'sticky') and rename the file if the last write and close are good.
    # [Note--the error check is after the text.]
    print HF <<EOT

/*
 * End of automatically generated $hfile for $self->{DISTNAME}-$self->{VERSION}.
 */
EOT
	or die "Error writing to `$tempfile' for `$hfile': $!\n";
    close(HF) or die "Error closing `$tempfile' for `$hfile': $!\n";
    # OK, move the bloody file.
    unless (rename($tempfile,$hfile)) {
	# A straight rename failed -- see whether we can force it.
	unless (unlink($hfile)) {
	    chmod 0777,$hfile;	# ignore error in case UNIX
	    unlink($hfile) or
		die "Error removing old ${hfile}: $!\n";
	}
	# OK, it's out of our way now--try again.
	rename($tempfile,$hfile) or
	    die "Error moving $hfile into place from ${tempfile}: $!\n";
    }
    print STDERR "Wrote $hfile\n" if $Verbose >= 0;
}

sub MY::post_constants
{
    my $self = shift;
    write_hfile($self);

    # Finally, make sure that MM gets its own chance.
    $self->MM::post_constants(@_);	# in case it's not empty now
}

# Override 'make ci' rule to account for the bogus .pm files.
sub MY::dist_ci
{
'ci :
	$(CI) `cat manifake`
	$(RCS_LABEL) `cat manifake`
'
}

# Generate the .pm files before we let MM scan the lib directory.
gen_pm_files;

# Now that we're sure we've initialised all our tables, let MM do its thing.
runMM;
