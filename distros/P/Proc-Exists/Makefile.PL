#!perl -w
$|++;

use ExtUtils::MakeMaker;
use Config qw(%Config); #for $Config{cc} 
use Getopt::Long;
use Cwd;

use strict;

my ($force_cflags, $force_pp, $force_cc) = ('', undef, undef);
unless( GetOptions( 'cc=s'        => \$force_cc,
                    'cflags=s'    => \$force_cflags,
                    'xs'          => sub { $force_pp = 'n' },
                    'pp|pureperl' => sub { $force_pp = 'y' } ) ) {
	die "usage: $0 [ -pp | -xs [ -cc=/path/to/cc ] [ -cflags='-O -fPIC' ] ]\n".
	    "       -pp indicates pureperl, -xs indicates the xs implementation\n".
	    "       -cc is used to specify the path to the cc you would like to\n".
	    "       use if autodetection fails. similarly for -cflags, which is\n".
	    "       particularly useful when building with a different cc than\n".
	    "       the one which was used to build perl. -cflags also accepts\n".
	    "       the shortcut argument \"gcc\" which uses options for that\n".
	    "       compiler. -cc and -cflags have no effect when used with -pp\n";
}
#-cc or -cflags imply -xs
$force_pp = 'n' if($force_cflags or $force_cc);

#TODO: is this general enough?
if($force_cflags eq 'gcc') {
	$force_cflags = '-O -g -fPIC -D_LARGEFILE_SOURCE -D_FILE_OFFSET_BITS=64';
}

### non-compile-related platform specific hacks go here, for example,
### on windows NT pids are in multiples of 4
my $defines = '';
# win32 crud
if ($^O eq 'MSWin32') {
	if(defined($ENV{OS})) {
		if($ENV{OS} eq "Windows_NT") {
			# use multiples of 4 for pid
			$defines .= " -Dwin32_pids_mult4";
		} else {
			# win95/98/me, i presume...
			warn "wow, will i really run on $ENV{OS}?"; 
		}
	} else {
		warn "unsupported win32 OS - no \$ENV{OS} set...";
	}
}

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
my %Makefile = (
	NAME              => 'Proc::Exists',
	VERSION_FROM      => 'Exists.pm',
	PREREQ_PM         => {
	                       'Config'              => 0,
	                       'Exporter'            => 0,
	                       'ExtUtils::MakeMaker' => 0,
	                       'Getopt::Long'        => 0,
	                       'Test::More'          => 0, 
                        },
	($] >= 5.005 ?     ## Add these new keywords supported since 5.005
		(ABSTRACT_FROM => 'Exists.pm',
		 AUTHOR        => 'Brian Szymanski <ski-cpan@allafrica.com>') : ()),
	LIBS              => [''],
	DEFINE            => $defines, 
	INC               => '-I.',

	#MakeMaker LICENSE support: 6.30 - no, 6.30_0[1234] - yes, >=6.31 - yes
	#but some versions that identify as 6.30_01 are really rev 4535 which
	#does NOT understand the LICENSE key. and yes, this is quite a lot
	#of effort to avoid a single warning message on old systems :-)
	( ( (compare_version( $ExtUtils::MakeMaker::VERSION, '6.30') > 0 ) &&
	    ($ExtUtils::MakeMaker::Revision !~ /4535/) ) ?
         (LICENSE => 'perl') : () ),

	#MakeMaker NO_META support introduced in 6.10_03
	( compare_version($ExtUtils::MakeMaker::VERSION, '6.10.03') >= 0 ?
		(NO_META => 1) : () ),
	                           
	##Un-comment this if you add C files to link with later:
	# OBJECT          => '$(O_FILES)', # link all the C files too
	XS                => {},
	C                 => [],

	dist              => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
	clean             => { FILES => 'Proc-Exists-*' },
	realclean         => { FILES => '*~' },
);

# An existing makefile can confuse the CC test.
unlink('Makefile');

### ask if you want to use XS or pureperl (default=XS)
if(!defined($force_pp)) {
	print <<END;
It is recommended to use the XS code, which is faster, and compatible 
with non-cygwin win32. You should only use the pureperl option if you 
are on a POSIX system *without* a functional c compiler, or you have
trouble compiling the XS.

END
	$force_pp = prompt("Do you want to use the pureperl implementation (y/n)?", "no");
}

### determine what C compiler to use, if any
my $CC; 
my $use_pp; 

if($force_pp =~ /^y/i) {
	$use_pp = "user requested pureperl";
} else {
	$use_pp = use_pure_perl();
	$Makefile{CC} = $CC; 
	
	if($CC && !$use_pp) {
		my $is_gcc = `$CC -v 2>&1`; $is_gcc = ($is_gcc =~ /^gcc\s+version/im);
		#my $is_sc = `$CC -V 2>&1`; $is_sc = ($is_sc =~ /^cc:\s+Sun\s+C/im);

		# if we have a perl built by something other than gcc, but a gcc
		# compiler is available, we'll need to munge CFLAGS and such later.
		if($is_gcc && !$Config::Config{gccversion}) {
			$force_cflags = '-O2 -g -fPIC';
			unless($^O =~ /^(?:solaris|hpux)/) {
				warn "gcc on $^O is uncharted territory, please report results!\n";
			}
		}

		# don't try to link via a non-existent cc (solaris 2006-06 w/ only gcc)
		if(($^O eq 'solaris') && ($CC ne $Config{cc}) && ($Config{ld} eq $Config{cc})) {
			$Makefile{LD} = $CC; 
		}
	}

	if($use_pp) {
		print "NO: $use_pp\n"; 
		print <<END;

I cannot detect a working C compiler. I will install the
perl-only implementation. Expect degraded performance.
Alternately, you can re-run Makefile.PL like so:
   perl Makefile.PL -cc=/path/to/your/c-compiler
note there is also a -cflags option.

END
	} else {
		print "YES\n";
	}
}

#tinker with %Makefile based om whether we are using pure perl or not
if($use_pp) {
	delete $Makefile{CC}; 
	delete $Makefile{LD}; 
} else {
	delete $Makefile{XS}; 
	delete $Makefile{C}; 
}

### change %Makefile as necessary to comply with the compiler we have
### if we have a force_cflags argument.
if( $force_cflags ) {
	#NOTE: must be a true value to override, so use a space instead
	#      of an empty string in to override the autodetected values
	$Makefile{OPTIMIZE} = ' ';
	$Makefile{CCFLAGS} = $force_cflags;
	$Makefile{CCCDLFLAGS} = ' '; #just on hpux?
} 
### (finished tinkering with cc related variables in Makefile)

### write out Configuration.pm and Makefile
write_config( defined $use_pp ? (want_pureperl => $use_pp ? 1 : 0) : () );
WriteMakefile(%Makefile); 

### return -1, 0, or 1 based on whether the first version string is 
### greater than the second. assume 1.2 < 1.2.0 when necessary
sub compare_version {
	my ($v1, $v2) = @_; 
	# 6.30_01 => ( 6, 30, 01 ), etc.
	my @v1 = split /[._]/, $v1; 
	my @v2 = split /[._]/, $v2; 
	#pad versions to the same length. 1.2 < 1.2.0 if they both exist
	push @v2, -1 while(@v2 < @v1); 
	push @v1, -1 while(@v1 < @v2); 
	for my $i (0..$#v1) {
		my $r = $v1[$i] <=> $v2[$i]; 
		return $r if $r; 
	}
	return 0;
}

### update the relevant entries in Configuration.pm
sub write_config {
	my %args = @_; 

	my $wd = getcwd();
	chdir('Exists') || die "can't change to Exists subdirectory: $!"; 
	open(CONF, '<Configuration.pm') || die "can't read Configuration.pm: $!"; 
	my @lines = map { chomp; $_ } <CONF>; 
	close(CONF);
	my $do_update = 0;
	my %old_config; 
	foreach my $key (keys %args) {
		my @t = grep {defined($_)} map { /^\s*\$Proc::Exists::Configuration::$key\s*=\s*(\d+)\s*;\s*$/; $1 } @lines; 
		die "Configuration.pm in a weird state, not the right number of ${key}'s\n... if you are confused, restore Exists/Configuration.pm from the distribution\n" if(@t != 1);
		$old_config{$key} = $t[0]; 
		$do_update = 1 unless $args{$key} eq $t[0]; 
	}
	if($do_update) {
		my $warn_str = 'updating Configuration.pm -- ';
		foreach my $k (sort keys %args) {
			unless($old_config{$k} eq $args{$k}) {
				$warn_str .= "$k: $old_config{$k} => $args{$k}, ";
			}
		}
		$warn_str =~ s/, $//; 
		warn "$warn_str on os: $^O\n"; 
		foreach my $ln (0..$#lines) {
			foreach my $key (keys %args) {
				$lines[$ln] =~ s/$key\s*=\s*\d+\s*;\s*$/$key = $args{$key};/; 
			}
		}
		open(CONF, '>Configuration.pm') || die "can't write Configuration.pm: $!"; 
		print CONF "$_\n" foreach @lines; 
		close(CONF);
	}
	chdir($wd) || die "can't restore pwd to '$wd': $!"; 
}

### use_pure_perl determines if we should use the pure perl 
### implementation or the faster XS
# The perl/C checking voodoo is stolen from Olaf Kolkman's 
# Net-DNS via Graham Barr's Scalar-List-Utils distribution.
sub use_pure_perl {
	print "Testing if you have a working C compiler and the needed header files...\n";

	return "cannot write compile.c" unless open(FH, ">compile.c");

	print FH <<'EOF';
#include <sys/types.h>
#include <signal.h>
#include <errno.h>
int main() { return 0; }
EOF

	return "cannot close compile.c" unless close(FH); 

	#sometimes $Config{CC} is not the answer (e.g. solaris10 w/ gcc but
	#no sun c package installed)...
	my @cc_alternatives = ( $Config{cc}, qw( cc gcc clang egcs icc pcc lcc ));
	#if all fails but CC env var is set, try it, maybe it will link
	push @cc_alternatives, $ENV{CC} if($ENV{CC}); 
	if(!$force_cc && ($^O eq 'hpux')) {
		#- acc must come before cc for hp-ux, where we need C/ANSI C
		#compiler and not the default cc ( /usr/ccs/bin/cc )
		#TODO: instead of skippping default cc, try to massage its arguments
		if (grep /option\s+is\s+available\s+only\s+with\s+the\s+C\/ANSI\s+C\s+product/, `cc -Ae 2>&1` ) {
			warn "hpux: skipping built in cc, which can't support the same ".
			     "options that c/ansi c (which was used to compile perl) ".
			     "says we need\n";
			@cc_alternatives = grep !/^cc$/, @cc_alternatives; 
			#acc (HPUX C/ANSI C) will however work if it exists...
			unshift @cc_alternatives, 'acc';
		}
		unlink 'a.out'; #clean up after `cc -Ae` test
	}
	unshift @cc_alternatives, $force_cc if(defined($force_cc)); 
	my $ret; 
	print "trying compilers: "; 
	foreach my $cc ( @cc_alternatives )  {
		print "$cc... "; 
		my $cmd = "$cc -c compile.c -o compile$Config{obj_ext}"; 
		$ret = system($cmd); 
		#if on hpux (or others?) check the bitness of perl and cc's output
		#in general, check file's output on `which cc` and compile*
		if(($ret == 0) && ($^O eq 'hpux')) {
			my $out_type  = (split /:\s*/, `file compile$Config{obj_ext}`)[1]; 
			chomp $out_type; 
			my $perl_type = $Config::Config{archname}; 
			$out_type =~ /RISC\s*(1\.[01]|2\.0)/;
			my $out_risc_spec = ($out_type =~ /RISC\s*(1\.[01]|2\.0)/, $1); 
			my $perl_risc_spec = ($perl_type =~ /RISC\s*(1\.[01]|2\.0)/, $1); 
			#e.g. PA-RISC2.0-thread-multi-LP64 vs. PA-RISC1.1-thread-multi
			if($out_risc_spec ne $perl_risc_spec) {
				warn "compiler $cc seems to output the wrong type of files, ".
				     "skipping: '$out_type' vs. '$perl_type'\n";
				$ret = -1; #that's an error
				foreach my $file (glob('compile*')) {
					next if($file eq 'compile.c');
					unlink($file) || warn "Could not delete $file: $!\n"; 
				}
			}
		}
		if($ret==0) { $CC=$cc; last };
	}
   
	foreach my $file (glob('compile*')) {
		unlink($file) || warn "Could not delete $file: $!\n"; 
	}

	if ($ret == 0) {
		return 0;
	} else {
		return "failed";
	}
}

