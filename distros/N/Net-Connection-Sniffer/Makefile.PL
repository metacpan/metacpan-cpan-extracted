use ExtUtils::MakeMaker;
use Config;
use lib qw(inc);

my $pkg = 'Net::Connection::Sniffer';
$pkg =~ /[^:]+$/;
my $module = $& .'.pm';

my $view = $then + 86400 < $now ? 5:0;

if ($Config{osname} =~ /win/i) {
  print q|Windows and Darwin not supported
Volunteers welcome
|;
  exit 1;
}
  

unless (eval {
        require Sys::LoadAvg &&
	$Sys::LoadAvg::VERSION >= 0.3
	}) {
  print q|
optional Sys::LoadAvg v0.3 or greater is required if 
you want to quench excess CPU usage during 'coalesc'
operation.

|;
  sleep $view if $view;
}

# extra libs we would like to have that perl does not,
# a SPACE separated list
#
# put a test for them in configure.ac and let the script
# below find and insert them. Make sure and add the necessary
# paths in %makeparms for INC and LIBS but not the library itself
#
my $wish_libs = '-lpcap';

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

my %makeparms = (
    NAME		=> $pkg,
    VERSION_FROM	=> $module, # finds $VERSION
    PREREQ_PM		=> {
				Net::DNS::Codes		=> 0.09,
				Net::DNS::ToolKit	=> 0.42,
				Net::Interface		=> 1.009,
				Net::NBsocket		=> 0.14,
				Sys::Hostname::FQDN	=> 0.10,
				Proc::PidUtil		=> 0.08,
				NetAddr::IP		=> 4.026,
				Sys::Sig		=> 0.04,
				Net::NBsocket		=> 0.16,
			},
# LIBS list should be a single string to be compatible with script below
    LIBS		=> '-L/usr/local/lib',
    INC			=> '-I/usr/local/include',
    clean		=> { FILES    => "*~ tmp* auto*"},
    realclean		=> { FILES    => "config.h config.log config.status"},
    dist		=> {COMPRESS=>'gzip', SUFFIX=>'gz'}
);

################################################
# fix up compile and link flags for "configure"
################################################
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

###################################

sub MY::top_targets {
  package MY;
  my $inherited = shift->SUPER::top_targets(@_);
  $inherited =~ s/(pure_all\s+::.+)/$1 README/;
  $inherited;
}

sub MY::post_constants {
  my $post_constants = $Config{scriptdirexp} .'/pod2text';
  if (-e $post_constants) {
    $post_constants = q|
MY_POD2TEXT = |. $post_constants .q|
|;
  } else {   
    $post_constants = q|
MY_POD2TEXT = echo "perl distro missing 'pod2text' to convert " |;
  }
}

sub MY::postamble {
  package MY;
  my $postamble = q|
README  : |. $module .q|
	@$(MY_POD2TEXT) |. $module .q| > README

|;
}

WriteMakefile(%makeparms);

unless (open(F,'./config.h')) {
  warn "can not find ./config.h\n";
  exit;
}

unless (scalar grep {/#define\s+HAVE_PCAP/} (<F>)) {
  close F;
  warn "prerequisite 'libpcap' (-lpcap) not found\n";
  exit 0;
}
close F;

