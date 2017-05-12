#   Hej, Emacs, don't you see this is -*- perl -*- mode? :-)
#
#   Copyright (c) 1997,1998  Andreas König, Jochen Wiedmann
#
#  You may distribute this under the terms of either the GNU General Public
#  License or the Artistic License, as specified in the Perl README file.
#
#  $Id: Makefile.PL,v 1.10 1999/10/21 20:05:41 joe Exp $
#
BEGIN {require 5.004;}
use strict;
use Config ();
use Getopt::Long ();
use ExtUtils::MakeMaker qw(prompt WriteMakefile);
use File::Path ();
use Cwd ();
use lib "lib";
use ExtUtils::PerlPP ();

use vars qw($VERSION $DBD_VERSION $options);

$VERSION = "1.2219";
$DBD_VERSION = "2.0419";

$options = { 'prompt' => 1 };


############################################################################
#
#   General hints:
#
#   This Makefile.PL can install several modules: DBD::mysql, DBD::mSQL
#   and/or DBD::mSQL1.
#
#   This is done by creating a hash ref $config with keys 'mysql', 'mSQL'
#   and 'mSQL1'. Each key has another hash ref as value with keys like
#
#       install (0 or 1)
#       install_nodbd (0 or 1)
#       files   (hash ref ready for using as MakeMakers PL_FILES)
#       dbd_driver  (drivers name, same as the top level key)
#       nodbd_driver (Mysql, Msql or Msql1)
#       lc_dbd_driver (lowercased driver name)
#       dbd_version
#       nodbd_version
#       test_dsn (DSN for running tests)
#       test_user (User for running tests)
#       test_pass (Password for running tests)
#       test_db (Database for running tests; DSN is derived from this and
#                test_host)
#       test_host (Host for running tests)
#
############################################################################


############################################################################
#
#   Name:    QueryDb
#
#   Purpose: Query settings for running the test suite
#
#   Inputs:  $cfg - Config hash ref
#
#   Returns: Nothing; creates
#            $cfg->{$driver}->{test_(db|host|dsn|user|pass)}
#
############################################################################

sub QueryDb ($) {
    my($cfg) = @_;
    my $db = $cfg->{'description'};
    my $driver = $cfg->{'dbd_driver'};

    my $d = lc $driver;
    my $prompt = $options->{'prompt'};

    my $test_db =  exists($options->{"$d-test-db"}) ?
	$options->{"$d-test-db"} : ($cfg->{'test_db'} || 'test');
    $test_db = prompt
	("Which database should I use for testing the $db drivers?",
	 $test_db) if $prompt;

    my $test_host = exists($options->{"$d-test-host"}) ?
	$options->{"$d-test-host"} : ($cfg->{'test_host'} || 'localhost');
    $test_host = prompt
	("On which host is database $test_db running (hostname, ip address\n" .
	 "or host:port)", $test_host) if $prompt;

    my($test_user, $test_pass);
    if ($driver eq 'mysql') {
	$test_user = exists($options->{"$d-test-user"}) ?
	    $options->{"$d-test-user"} : ($cfg->{'test_user'} || "undef");
	$test_user = prompt
	    ("User name for connecting to database $test_db?", $test_user)
		if $prompt;
	$test_user = undef if $test_user eq 'undef';

	$test_pass = exists($options->{"$d-test-pass"}) ?
	    $options->{"$d-test-pass"} : ($cfg->{'test_pass'} || "undef");
	$test_pass = prompt
	    ("Password for connecting to database $test_db?", $test_pass)
		if $prompt;
	$test_pass = undef if $test_pass eq 'undef';
    }

    $cfg->{$driver}->{'test_db'} = $test_db;
    $cfg->{$driver}->{'test_host'} = $test_host;
    if ($test_host eq 'undef'  ||  $test_host eq 'localhost') {
	$test_host = '';
    }
    my $test_dsn = "DBI:$driver:database=$test_db";
    if ($test_host) {
	$cfg->{$driver}->{'test_dsn'} .= ";host=$test_host";
    }

    $cfg->{'test_dsn'} = $test_dsn;
    $cfg->{'test_db'} = $test_db;
    $cfg->{'test_host'} = $test_host;
    $cfg->{'test_user'} = $test_user;
    $cfg->{'test_pass'} = $test_pass;

    if ($options->{'verbose'}) {
	print("Driver $driver is using the following settings for tests:\n",
	      "    Database $test_db\n",
	      "    Host     $test_host\n",
	      "    DSN      $test_dsn\n",
	      "    User     $test_user\n",
	      "    Password $test_pass\n");
    }
}


############################################################################
#
#   This is main()
#
############################################################################

sub SelectDrivers ($$) {
    my($config, $old) = @_;
    my $prompt = $options->{'prompt'};

    # Set defaults
    $config->{'mysql'}->{'install'} =
	exists($options->{'mysql-install'}) ?
	    $options->{'mysql-install'} :
	    (!$old->{'mysql'}  ||
	     ($old->{'mysql'} && $old->{'mysql'}->{'install'}));
    eval "use Mysql";
    $config->{'mysql'}->{'install_nodbd'} =
	exists($options->{'mysql-install-nodbd'}) ?
	    $options->{'mysql-install-nodbd'} :
	    ($old->{'mysql'} ? $old->{'mysql'}->{'install_nodbd'} :
	     (defined($Mysql::VERSION) and $Mysql::VERSION > 1.19));
    $config->{'mSQL'}->{'install'} =
	exists($options->{'msql-install'}) ?
	    $options->{'msql-install'} :
	    (!$old->{'mSQL'}  ||
	     ($old->{'mSQL'} && $old->{'mSQL'}->{'install'}));
    eval "use Msql";
    $config->{'mSQL'}->{'install_nodbd'} =
	exists($options->{'msql-install-nodbd'}) ?
	    $options->{'msql-install-nodbd'} :
	    (($old->{'mSQL'} ? $old->{'mSQL'}->{'install_nodbd'} :
	      (defined($Msql::VERSION) and $Msql::VERSION > 1.19)));
    $config->{'mSQL1'}->{'install'} =
	exists($options->{'msql1-install'}) ?
	    $options->{'msql1-install'} :
	    ($old->{'mSQL1'}  &&  $old->{'mSQL1'}->{'install'});
    eval "use Msql";
    $config->{'mSQL1'}->{'install_nodbd'} =
	exists($options->{'msql1-install-nodbd'}) ?
	    $options->{'msql1-install'} :
	    (defined($Msql1::VERSION) and $Msql::VERSION > 1.19);

    if ($prompt) {
	my $choice;
	if ($config->{'mysql'}->{'install'}) {
	    if ($config->{'mSQL'}->{'install'}) {
		$choice = $config->{'mSQL1'}->{'install'} ? 5 : 3;
	    } else {
		$choice = 1;
	    }
	} else {
	    $choice = $config->{'mSQL1'}->{'install'} ? 4 : 2;	
	}

	$choice = prompt
	    ("Which drivers do you want to install?\n\n"
	     . "    1)	MySQL only\n"
	     . "    2)	mSQL only (either of mSQL 1 or mSQL 2)\n"
	     . "    3)  MySQL and mSQL (either of mSQL 1 or mSQL 2)\n\n"
	     . "    4)  mSQL 1 and mSQL 2\n"
	     . "    5)  MySQL, mSQL 1 and mSQL 2\n\n"
	     . "Enter the appropriate number: ", $choice);

	my $reply;
	if ($config->{'mysql'}->{'install'} =
	    ($choice == 1  ||  $choice == 3  ||  $choice == 5)) {
	    my $reply =
		prompt(qq{

Do you want to install the MysqlPerl emulation? You might keep your old
Mysql module (to be distinguished from DBD::mysql!) if you are concerned
about compatibility to existing applications!},
		       $config->{'mysql'}->{'install_nodbd'} ? "y" : "n");
	    $config->{'mysql'}->{'install_nodbd'} = ($reply =~ /y/i) ? 1 : 0;
	}
	if ($config->{'mSQL'}->{'install'} = ($choice > 1)) {
	    my $reply =
		prompt(qq{

Do you want to install the MsqlPerl emulation? You might keep your old
Mysql module (to be distinguished from DBD::mysql!) if you are concerned
about compatibility to existing applications!},
		       $config->{'mSQL'}->{'install_nodbd'} ? "y" : "n");
	    $config->{'mSQL'}->{'install_nodbd'} = ($reply =~ /y/i) ? 1 : 0;
	}
	if ($config->{'mSQL1'}->{'install'} = ($choice > 4)) {
	    $reply = prompt
		(qq{

Do you want to install the Msql1Perl emulation? You might keep your old
Mysql module (to be distinguished from DBD::mysql!) if you are concerned
about compatibility to existing applications!},
		 $config->{'mSQL1'}->{'install_nodbd'} ? "y" : "n");
	    $config->{'mSQL1'}->{'install_nodbd'} = ($reply =~ /y/i) ? 1 : 0;
	}
    }

    $config->{'mSQL'}->{'description'} = 'mSQL 2'
	if $config->{'mSQL'}->{'install'} and $config->{'mSQL1'}->{'install'};
    $config->{'mysql'}->{'install_nodbd'} = 0
	unless $config->{'mysql'}->{'install'};
    $config->{'mSQL'}->{'install_nodbd'} = 0
	unless $config->{'mSQL'}->{'install'};
    $config->{'mSQL1'}->{'install_nodbd'} = 0
	unless $config->{'mSQL1'}->{'install'};
}


use vars qw($README_created);

{
    Getopt::Long::GetOptions($options, "verbose", "debug", "static", "config",
			     'mysql-install!', 'msql-install!',
			     'msql1-install!',
			     'mysql-install-nodbd', 'msql-install-nodbd',
			     'msql1-install-nodbd',
			     'mysql-test-db=s', 'msql-test-db=s',
			     'msql1-test-db=s',
			     'mysql-test-host:s', 'msql-test-host:s',
			     'msql1-test-host:s',
			     'mysql-test-user:s', 'mysql-test-pass:s',
			     'mysql-libdir=s', 'mysql-incdir=s',
			     'mysql-use-client-found-rows',
			     'msql-libdir=s', 'msql-incdir=s',
			     'msql1-libdir=s', 'msql1-incdir=s',
			     'help', 'prompt!');
    if ($options->{'help'}) {
	print <<"EOF";
Usage: perl Makefile.PL <options>

Possible Options are:

  --config	Recreate files
  --debug	Enable debugging mode
  --static	Link against static version of libmysqlclient.
  --verbose	Enable verbose mode
  --noprompt	Disable interactive dialog

  --[no]mysql-install	[Do not] Install DBD::mysql and related files
  --[no]msql-install	[Do not] Install DBD::mSQL and related files
  --[no]msql1-install	[Do not] Install DBD::mSQL1 and related files

  --mysql-install-nodbd	Install Mysql and related files
  --msql-install-nodbd  Install Msql and related files
  --msql1-install-nodbd Install Msql1 and related files

  --mysql-test-db=db		Sets database and user name, password and
  --mysql-test-user=user	host name to be used for running the
  --mysql-test-pass=password	DBD::mysql tests. Defaults to "test",
  --mysql-test-host=host	"", "" and "" (aka "localhost").
  --mysql-use-client-found-rows By default enable
                                \$dbh->{mysql_client_found_rows}

  --msql-test-db=db		Sets database and host name for running
  --msql-test-host=host		the DBD::mSQL tests. Defaults to "test"
				and "" (aka "localhost").

  --msql1-test-db=db		Sets database and host name for running
  --msql1-test-host=host	the DBD::mSQL1 tests. Defaults to "test"
				and "" (aka "localhost").

  --mysql-incdir=dir		Sets directories with MySQL's header and
  --mysql-libdir=dir		library files.

  --msql-incdir=dir		Sets directories with mSQL's header and
  --msql-libdir=dir		library files.

  --msql1-incdir=dir		Sets directories with mSQL1's header and
  --msql1-libdir=dir		library files.
EOF
	exit 1;
    }
    $options->{'verbose'} = 1 if $options->{'debug'};

    # Checking for existing installations
    my $old = {};
    my $config = {};
    foreach my $package ('mysql', 'mSQL', 'mSQL1') {
	my $class = "DBD::$package\::Install";
	eval "use $class()";
	die $@ if $@;
	# Try to find an existing configuration
	my $cfg = eval qq{require $class\::Config};
	if ($cfg) {
	    $old->{$package} = $config->{$package} =
		bless($cfg, $class);
	} else {
	    $config->{$package} = eval "$class->new(\$DBD_VERSION, \$VERSION)";
	}
	$config->{$package}->{'nodbd_version'} = $VERSION;
	$config->{$package}->{'dbd_version'} = $DBD_VERSION;
	if ($config->{$package}->{'install'}  &&  !$README_created) {
	    my $driver = $config->{$package}->{'dbd_driver'};

	    # Try to find pod2text
	    my $pod2text;
	    foreach my $p ($Config::Config{'installscript'},
			   split(/:/, $ENV{'PATH'}) ) {
		if (-f "$p/pod2text") {
		    $pod2text = "$p/pod2text";
		    last;
		}
	    }
	    if (!$pod2text) {
		foreach my $p ($Config::Config{'installscript'},
			       split(/:/, $ENV{'PATH'}) ) {
		    if (-f "$p/perldoc") {
			$pod2text = "PAGER=cat $p/perldoc";
			last;
		    }
		}
	    }
	    if ($pod2text) {
		$README_created = "\npm_to_blib: README\n\n"
		    . "README: $driver/lib/DBD/$driver.pm\n"
			. "\t$pod2text $driver/lib/DBD/$driver.pm >README\n\n";
	    } else {
		$README_created = "\n";
	    }
	}
    }

    eval "use Data::Dumper";
    if ($@) {
	print q{
You don't have installed the Data::Dumper module, which is
required for building this package. Missing modules are available
from any CPAN mirror, for example

   ftp://ftp.funet.fi/pub/languages/perl/CPAN/modules/by-module

};
	exit 1;
    }


    if ($options->{'config'}  ||
	!$old->{'mysql'}  ||  !$old->{'mSQL'}  ||  !$old->{'mSQL1'}) {
	SelectDrivers($config, $old);
    }

    my(@installdirs, @pl_files, @delete_files, $dbimon_done);
    $| = 1;
    foreach my $package ('mysql', 'mSQL', 'mSQL1') {
	my $cfg = $config->{$package};
	# Create the config file
	my $dir = $cfg->{'dbd_driver'};

	if ($cfg->{'install'}) {
	    my $description = $cfg->{'description'};
	    push(@installdirs, $dir);
	    push(@pl_files, 'dbd/Makefile.PL.in', "$dir/Makefile.PL",
		 "lib/DBD/$dir/Install/Config.pm");
	    if (!$dbimon_done) {
		$dbimon_done = 1;
		push(@pl_files, 'dbd/dbimon.in', 'dbimon',
		     "lib/DBD/$dir/Install/Config.pm");
	    }
	    if (!$old->{$package} or $options->{'config'}) {
		$cfg->Initialize($options);
		QueryDb($cfg);
		# Create the Makefile.PL
		print "Creating files for $description ";
	        ExtUtils::PerlPP::ppp('dbd/Makefile.PL.in',
				      "$dir/Makefile.PL",
				      $cfg);
		print ".";
		# Create other files.
		my($var, $val);
		while (($var, $val) = each %{$cfg->{'files'}}) {
		    ExtUtils::PerlPP::ppp($var, $val, $cfg);
		      print ".";
		}
		if ($cfg->{'install_nodbd'}) {
		    while (($var, $val) = each %{$cfg->{'files_nodbd'}}) {
		        ExtUtils::PerlPP::ppp($var, $val, $cfg);
			print ".";
		    }
		} else {
		    push(@delete_files, values %{$cfg->{'files_nodbd'}});
		}
		print "\n";
	    }

	    $Data::Dumper::Indent = 1;
	    my $cf = Data::Dumper->Dump
		([$cfg], ["\$DBD::${dir}::Install::Config::configuration"]);
	    my $time = localtime();
	    my $cfg_file = <<"CFG_FILE";
# -*- perl -*-
#
#    This file was automatically generated at $time
#    by Makefile.PL. Do not edit, instead do a "make realclean" in
#    the toplevel directory and rerun "perl makefile.PL".
#
package DBD::${dir}::Install::Config;

$cf
CFG_FILE
            my $d = "lib/DBD/$dir/Install";
	    if (! -d $d  &&  !mkdir $d, 0755) {
		die "Error while creating $d: $!";
	    }
	    if (!open(CFG, ">$d/Config.pm")
		|| !(printf CFG $cfg_file)  || !close(CFG)) {
		die "Cannot create config file $d/Config.pm: $!";
	    }
        } else {
	    push(@delete_files, "$dir/Makefile.PL",
		 values %{$cfg->{'files'}},
		 values %{$cfg->{'files_nodbd'}});
	}
    }

    my $f;
    foreach $f (@delete_files) {
 	if ($f !~ /\.pm$/  and  -f $f) {
 	    if ($options->{'verbose'}) {
 		print "Removing file: $f\n";
 	    }
 	    if (!unlink $f) {
 		die "Error while removing $f: $!";
 	    }
 	}
    }

    my %opts = (
	 'NAME'         => 'Msql-Mysql-modules',
         'DIR'          => \@installdirs,
         'EXE_FILES'    => [ 'dbimon' ],
         'dist'         => { 'SUFFIX'       => ".gz",
			     'DIST_DEFAULT' => 'all tardist',
			     'COMPRESS'     => "gzip -9f" },
         'VERSION'      => $VERSION,
         'realclean'    => {
	     FILES => 'Mysql/Makefile.PL Msql/Makefile.PL Msql1/Makefile.PL'
		 . ' lib/DBD/mysql/Install/Config.pm'
		 . ' lib/DBD/mSQL/Install/Config.pm'
		 . ' lib/DBD/mSQL1/Install/Config.pm'
	     },
         'PL_FILES'     => \@pl_files
    );
    if ($ExtUtils::MakeMaker::VERSION >= 5.43) {
        $opts{'CAPI'} = 'TRUE';
	$opts{'AUTHOR'} = 'Jochen Wiedmann (joe@ispsoft.de)';
	$opts{'ABSTRACT'} =
	    'mSQL and MySQL drivers for the Perl5 Database Interface (DBI)';
	$opts{'PREREQ_PM'} = { 'DBI' => 1.08,
			       'Data::Dumper' => 0,
			       'Data::ShowTable' => 0 };
    }
    ExtUtils::MakeMaker::WriteMakefile(%opts);
}




package MY;

sub libscan {
    my($self, $path) = @_;
    if ($path =~ /(PerlPP\.pm|Config\.pm|Install\.pm|,v|~)$/) { return undef; }
    $path;
}

sub processPL {
    my($self) = shift;
    my @output;
    my @files = @{$self->{'PL_FILES'}};
    while (@files) {
	my $from = shift @files;
	my $to = shift @files;
	my $cfg = shift @files;
	push(@output, <<"PART");
pm_to_blib: $to

$to :: $from
	\$(PERL) -I\$(INST_ARCHLIB) -I\$(INST_LIB) -I\$(PERL_ARCHLIB) \\
		-I\$(PERL_LIB) -Ilib -MExtUtils::PerlPP \\
		-e ppp "$from" "$to" "$cfg"

PART
    }
    join "", @output;
}

sub postamble {
    $::README_created || '';
}
