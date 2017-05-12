# -*- perl -*-
#
#
#   DBD::mSQL::Install - Determine settings of installing DBD::mSQL
#

use strict;

require Config;
require File::Basename;
require ExtUtils::MakeMaker;


package DBD::mSQL::Install;

@DBD::mSQL::Install::ISA = qw(DBD::mysql::Install);


sub new {
    my($class, $dbd_version, $nodbd_version) = @_;
    my($old, $self);

    if (@_ != 3) {
	die 'Usage: new($dbd_version, $nodbd_version)';
    }
    if (ref($class)) {
	$old = $class;
	$class = ref($class);
    } else {
	$old = {};
    }

    my $self = {
	'install'       => exists($old->{'install'}) ? $old->{'install'} : 1,
	'install_nodbd' => exists($old->{'install_nodbd'}) ?
	    $old->{'install_nodbd'} : 1,
	'dbd_driver'    => $old->{'dbd_driver'}   ||  'mSQL',
	'nodbd_driver'  => $old->{'nodbd_driver'} ||  'Msql',
	'description'   => $old->{'description'}  ||  'mSQL',
	'dbd_version'   => $dbd_version,
	'nodbd_version' => $nodbd_version,
	'test_db'       => $old->{'test_db'}      ||  'test',
	'test_host'     => $old->{'test_host'}    ||  'localhost',
	'test_user'     => $old->{'test_user'}    ||  undef,
	'test_pass'     => $old->{'test_pass'}    ||  undef,
	'files'         => {
	    'dbd/bundle.pm.in'      => 'mSQL/lib/Bundle/DBD/mSQL.pm',
	    'dbd/dbdimp.c'          => 'mSQL/dbdimp.c',
	    'dbd/dbd.xs.in'         => 'mSQL/mSQL.xs',
	    'dbd/dbd.pm.in'         => 'mSQL/lib/DBD/mSQL.pm',
	    'tests/00base.t'        => 'mSQL/t/00base.t',
	    'tests/10dsnlist.t'     => 'mSQL/t/10dsnlist.t',
	    'tests/20createdrop.t'  => 'mSQL/t/20createdrop.t',
	    'tests/30insertfetch.t' => 'mSQL/t/30insertfetch.t',
	    'tests/40bindparam.t'   => 'mSQL/t/40bindparam.t',
	    'tests/40listfields.t'  => 'mSQL/t/40listfields.t',
	    'tests/40blobs.t'       => 'mSQL/t/40blobs.t',
	    'tests/40nulls.t'       => 'mSQL/t/40nulls.t',
	    'tests/40numrows.t'     => 'mSQL/t/40numrows.t',
	    'tests/50chopblanks.t'  => 'mSQL/t/50chopblanks.t',
	    'tests/50commit.t'      => 'mSQL/t/50commit.t',
	    'tests/60leaks.t'       => 'mSQL/t/60leaks.t',
	    'tests/ak-dbd.t'        => 'mSQL/t/ak-dbd.t',
	    'tests/dbdadmin.t'      => 'mSQL/t/dbdadmin.t',
#	    'tests/dbisuite.t'      => 'mSQL/t/dbisuite.t',
	    'tests/lib.pl'          => 'mSQL/t/lib.pl'
	    },
	'files_nodbd' => {
	    'tests/akmisc.t'        => 'mSQL/t/akmisc.t',
	    'tests/msql1.t'         => 'mSQL/t/msql1.t',
	    'tests/msql2.t'         => 'mSQL/t/msql2.t',
	    'nodbd/nodbd.pm.in'     => 'mSQL/lib/Msql.pm',
	    'nodbd/statement.pm.in' => 'mSQL/lib/Msql/Statement.pm',
	    'nodbd/pmsql.in'        => 'mSQL/pmsql'
	    }
    };

    $self->{'lc_dbd_driver'} = lc $self->{'dbd_driver'};
    $self->{'uc_dbd_driver'} = uc $self->{'dbd_driver'};
    $self->{'lc_nodbd_driver'} = lc $self->{'nodbd_driver'};
    $self->{'uc_nodbd_driver'} = uc $self->{'nodbd_driver'};
    $self->{'test_dsn'} = sprintf("DBI:%s:database=%s%s",
				  $self->{'dbd_driver'},
				  $self->{'test_db'},
				  $self->{'test_host'} ?
				      (';host=' . $self->{'test_host'}) : '');

    bless($self, $class);
    $self;
}


############################################################################
#
#   Name:    Initialize
#
#   Purpose: Determine compiler settings
#
#   Inputs:  $self - Instance
#
#   Returns: Hash ref of MakeMaker variables
#
############################################################################

sub Initialize {
    my($self, $options) = @_;

    my @msqldirs = qw{/usr/local/Hughes /usr/local/Minerva /usr/local
		      /usr/mSQL /opt/mSQL /usr};
    my(@gooddirs, $gooddir, $var);
    $var = (ref($self) =~ /msql1/i) ? 'MSQL1_HOME' : 'MSQL_HOME';
    if (exists($ENV{$var})) {
	unshift @gooddirs, $ENV{$var};
    }

    my $headerdir;
    if (exists($options->{'msql-incdir'})) {
	if (-d $options->{'msql-incdir'}) {
	    $headerdir = $options->{'msql-incdir'};
	} else {
	    die "No such directory: $options->{'msql-incdir'}";
	}
    } else {
	($headerdir, $gooddir) = $self->SearchHeaders
	    ($options, \@gooddirs, \@msqldirs, ["include/msql.h"]);
    }
    my $libdir;
    if (exists($options->{'msql-libdir'})) {
	if (-d $options->{'msql-libdir'}) {
	    $libdir = $options->{'msql-libdir'};
	} else {
	    die "No such directory: $options->{'msql-libdir'}";
	}
    } else {
	($libdir) = $self->SearchLibs
	    ($options, \@gooddirs, \@msqldirs, ["lib/libmsql.a"]);
    }

    my $extralibs = "";
    my $linkwith = "";
    if ($Config::Config{osname} eq 'sco_sv') {
	# Some extra libraries need added for SCO
	$extralibs = "-lc";
    } elsif ($Config::Config{osname} eq 'solaris') {
	# We need to link with -R if we're on Solaris.......Brain-damaged....
	$linkwith = "-L$libdir -R$libdir";
    } elsif ($Config::Config{osname} eq 'hpux') {
	# We need to add +z to the list of CFLAGS if we're on HP-SUX, or -fPIC 
	# if we're on HP-SUX and using 'gcc'
	if ($Config::Config{cccdlflags} eq '+z') {
	    print q{You\'re building on HP-UX with the HP compiler.
You might get a warning at the link stage of:

    ld: DP-Relative Code in file .../libmsql.a(libmsql.o)
    >  - Shared Library must be Position-Independent

You\'ll have to recompile libmsql.a from the mSQL distribution with the
    '+z' flag of your C compiler.
};
	  } elsif($Config::Config{cccdlflags} eq '-fPIC') {
	    print q{You\'re building on HP-UX with the GNU C Compiler.
You might get a warning at the link stage like:

    ld: DP-Relative Code in file .../libmsql.a(libmsql.o)
    >  - Shared Library must be Position-Independent

You\'ll have to recompile libmsql.a from the mSQL distribution specifying
the '-fPIC' flag to produce Position-Independent code.
};
	}
    }

    my $sysliblist = "-L$libdir -lmsql -lm $extralibs";
    my(@headerfiles) = ("$headerdir/msql.h");

    my $defs = "-DDBD_MSQL";
    if ($ENV{'HOSTNAME'} eq 'laptop.ispsoft.de' && $ENV{'LOGNAME'} eq 'joe') {
	$defs .= ' -Wall -Wstrict-prototypes';
    }
    my $inc = "-I../dbd -I$headerdir  -I\$(INSTALLSITEARCH)/auto/DBI"
	. " -I\$(INSTALLARCHLIB)";
    my $dir;
    foreach $dir (@INC) {
	if (-f "$dir/auto/DBI/DBIXS.h") {
	    $inc = "-I$dir/auto/DBI " . $inc;
	    last;
	}
    }

    $self->{'makemaker'} = {
	'dynamic_lib' => { OTHERLDFLAGS => "-L$libdir $linkwith" },
	'DEFINE'      => $defs,
	'LIBS'        => $sysliblist,
	'H'           => \@headerfiles,
	'INC'         => $inc,
    };
}


1;
