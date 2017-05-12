use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

if ($^O eq 'MSWin32') {
  print STDERR "Windows is not supported\n";
  exit 0
}

# extra libs we would like to have that perl does not,
# a SPACE separated list
#
# put a test for them in configure.ac and let the script
# below find and insert them. Make sure and add the necessary
# paths in %makeparms for INC and LIBS but not the library itself
#
my $wish_libs = '';

# 'C' files that are not objexts
#
my $include = ' ni_IFF_inc.c ni_XStabs_inc.c miniSocketXS.c ';

# objecct files
#
my $depend = 'defaults.h localconf.h config.h localperl.h netsymbolC.inc netsymbolXS.inc inst/netsymbols.pl '.
# ni_.h files '.
	'ni_funct.h ni_strlcpy.h ni_memcmp.h ni_fixups.h '.
# ni_.c files
	'ni_getifaddrs.c ni_ifreq.c  ni_in6_ifreq.c  ni_lifreq.c  ni_strlcpy.c  ni_util.c '.
	'ni_malloc.c ni_linuxproc.c  ni_af_inetcommon.c ni_memcmp.c ni_in6_classify.c '.
	'ni_fallbackhwaddr.c ni_get_set.c';
my $objects = 'Interface.o '. join(' ',grep {s/(ni_[^\.]+\.)c/${1}o/} split(/\ /,$depend));

$depend .= $include;

use Config;

my $pkg = 'Net::Interface';
$pkg =~ /[^:]+$/;
my $module = $& .'.pm';
my $cfile = $& .'.c';

my %makeparms = (
	NAME		=> $pkg,
	VERSION_FROM	=> $module, # finds $VERSION
	PREREQ_PM	=> {
	    Test::More	=> 0.62,
	    Socket	=> 0,
	},
# LIBS list should be a single string to be compatible with script below
	LIBS		=> '-L/usr/local/lib',
	INC		=> '-I/usr/local/include',
	OBJECT		=> $objects,
	dist		=> {'COMPRESS'	=> 'gzip', 
		    	    'SUFFIX'	=> 'gz'},
	clean		=> { FILES	=> q|*~ *.bs *.o tmp* localperl.h auto* *.inc |. 
				q|lib/Net/Interface/NetSymbols.pm ni_IFF_inc.c ni_XStabs_inc.c |},
	realclean	=> { FILES	=> "config.h config.log config.status"},
	depend		=> {$cfile	=> $depend,
	},
);

#################################
# fix up compile and link flags
#################################
my %addflags = (
	ldflags		=> $makeparms{LIBS},
	lddlflags	=> $makeparms{LIBS},
	ccflags		=> $makeparms{INC},
);

my $cfgstrg = '';
foreach (sort keys %addflags) {
  my $KEY = uc $_;
  my $oldstuff = $Config{$_} =~ /(\S.+)/ ? $1 : '';
  $oldstuff .= ' ' if $oldstuff && $oldstuff !~ / $/;
#print "$_, $KEY, $oldstuff, $addflags{$_}\n";
  unless ($oldstuff =~ m|$addflags{$_}|) {
    $oldstuff .= $addflags{$_};
  }
# fix up issue with memcpy, bug 57413
  if ($KEY eq 'CCFLAGS') {
    $oldstuff .= ' ' if $oldstuff && $oldstuff !~ / $/;
    $oldstuff .= '-D_FORTIFY_SOURCE=0';
  }
  $cfgstrg .= qq|$KEY="$oldstuff" |;
}

unless (-e './config.h') {
  my $command = qq|./configure $cfgstrg|;
  print $command,"\n";
  system($command);   
}

###################################
# fix up lib list
###################################

my %LIBS;
open(F,'config.h') or die "could not open config.h\n";
foreach(<F>) {
  if ($_ =~ /^#define LIBS([ a-zA-Z-]+)/) {
# make lib list unique
    map {$LIBS{$_} = 1} ($1 =~ /[a-zA-Z0-9-]+/g);
    last;
  }
}
close F;

my $liblist = $Config{libs} .' '. $wish_libs;

my $link = $makeparms{LIBS} =~ /(\S.+)/ ? $1 : '';
$link .= ' ' unless $link =~ / $/;
foreach(keys %LIBS) {
  if ($liblist =~ /$_\b/) {
    $link .= $_ .' ';   
  }
}
chop $link;
$makeparms{LIBS} = [$link];

#######################################
# find build symbols for OS and threads
#######################################

open(F,'>localperl.h') or die "could not open localperl.h for write\n";
print F q|
/*      Written by Makefile.PL
 *
 *      Do not modify this file, modify Makefile.PL instead
 *
 */ 
|;

my @osvers = split(/[._-]/,$Config{osvers});

foreach (0..$#osvers) {
  print F qq|#define NI_OSVER_$_ $osvers[$_]\n|;
}
print F qq|#define NI_OSVER_BASE $Config{osvers}
#define NI_OS_|, (uc $Config{osname}), q| 1
#define NI_OSARCH |, (uc $Config{myarchname}),q|
|;

  print F q|#define LOCAL_PERL_WANTS_PTHREAD_H 1
| if $Config{i_pthread} eq 'define';
  print F q|#define LOCAL_PERL_USE_THREADS 1
| if $Config{usethreads} eq 'define';
  print F q|#define LOCAL_PERL_USE_I_THREADS 1
| if $Config{useithreads} eq 'define';
  print F q|#define LOCAL_PERL_USE_5005THREADS 1
| if $Config{use5005threads} eq 'define';
close F;

################ build family definitions
do 'inst/netsymbols.pl';
## END ######### build family definitions

sub MY::top_targets {
   package MY;
   my $begin = q|

config :: config.h
	@$(NOOP)

config.h :
	$(SHELL) configure
|;
  my $inherited = shift->SUPER::top_targets(@_);
# whatever additional change, additions that may be needed
  $begin . $inherited;
}

unless (open(F,'./netsymbolC.inc')) {
  die "can not find ./netsymbolC.inc created by Makefile.PL\n";
  exit;
}

unless (scalar grep {/# define\s+_NI_AF_INET/} (<F>)) {
  close F;
  die "AF_INET not found in netsymbolsC.inc,\nprerequisite development library header files missing from /usr/include/sys\n";
  exit 0;
}
close F;

WriteMakefile(%makeparms);

