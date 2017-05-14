
# $Id: Makefile.PL,v 1.23 2006/03/31 15:19:39 sommerb Exp $

use lib '.';

use inc::Module::Install;

# some wide-scoped variables
my $run_tests;
my $yes_tests = 't/test_unit_testcase.t';
my $no_tests = 't/no_tests.t';
my @scripts_to_install;

#
# Helpful Subroutines
#

sub module_prereqs {
  # adapted from modules.pl from Bricolage
  # using this code, we record module dependencies
  # in one place - Myco::Admin

  my %prereqs;
  my @mod;
  open(ADM, "lib/Myco/Admin.pod")
    or die "Unable to open lib/Myco/Admin.pod : $!";
  # seek to start of modules
  while (<ADM>) {
    last if /START MODULE LIST/;
  }
  # read in modules
  while (<ADM>) {
    if (/^=item\s+(\S+)(?:\s+([\d\.]+))?(?:\s+(\(optional\)))?/) {
      $prereqs{$1} = $2 || 0;
    } elsif (/END MODULE LIST/) {
      last;
    }
  }
  close ADM;

  return %prereqs;
}

# figure out where this platform's /etc and userland /bin are located
sub get_etc_or_bin {
  my $etc_or_bin = shift;
  return '/usr/local/bin' if $etc_or_bin eq 'bin';
  my $etc = '';
  my $os = $^O;
  if ($os =~ /\w+bsd$/) {
    $etc = '/usr/local/etc';
  } elsif ($os eq 'linux' || $os =~ m/cygwin|darwin|panther|tiger/g) {
    $etc = '/etc';
  }
  return $etc;
}

# this enables the ugly hacks below
sub remove_file_from_manifest {
  my $test_to_remove = shift;
  open M, 'MANIFEST';
  my $f = '';
  for (<M>) {
    $f .= $_ unless $_ =~ /$test_to_remove/;
  }
  close M;
  open M, ">MANIFEST";
  print M $f;
  close M;
}

sub yes {
  print ' (Y/n) ';
  return <STDIN> =~ /^(Y(e(s)?)?|A(YE|II+!*))?\n?$/i;
}

# copy myco.conf-dist and my_myco_app.conf-example over to this platform's /etc
# on install, and optionally the bin scripts
sub MY::postamble {
  my $etc = get_etc_or_bin('etc');
  my $copy_scripts = '';
  my $bin = get_etc_or_bin('bin');
  for my $script (@scripts_to_install) {
    $copy_scripts .= "\n\tcp bin/$script $bin/$script";
  }

  my $move_etc;
  if (-f "$etc/myco.conf" && ($run_tests && -f 'conf/myco.conf') ) {
    $move_etc = "mv $etc/myco.conf $etc/myco.conf.old && cp conf/myco.conf $etc && ";
  }

  return inc::Module::AutoInstall::postamble . "
install ::
\t" . $move_etc . "cp conf/myco.conf-dist $etc\n
\t" . "cp conf/my_myco_app.conf-example $etc" . $copy_scripts;

}


#
# HERE WE GO!
#

print '
Do you plan to run the test suite? You will need all modules installed before
typing \'make test\', as well as a database server installed and configured
(Myco only provides explicit support for PostreSQL)';

if (yes()) {
  $run_tests = 1;
  # HACK!!
  rename $no_tests,  "$no_tests.skip";
  remove_file_from_manifest($no_tests);
} else {
  print "TEST SUITE IS DISABLED\n";
  # another HACK!!
  rename $yes_tests, "$yes_tests.skip";
  remove_file_from_manifest($yes_tests);
}

print "
Do you want to install the following scripts on your system?\n";

print "\n ./bin/myco-deploy?";
push @scripts_to_install, 'myco-deploy' if yes();
print "\n ./bin/myco-recycle?";
push @scripts_to_install, 'myco-recycle' if yes();
print "\n ./bin/myco-testrun?";
push @scripts_to_install, 'myco-testrun' if yes();
print "\n ./bin/myco-mkentity?";
push @scripts_to_install, 'myco-mkentity' if yes();
print "\n ./bin/myco-probe (a script to probe Entity class metadata)?";
push @scripts_to_install, 'myco-probe' if yes();

name('Myco');
requires( module_prereqs() );
include_deps('Test::More');
include('ExtUtils::AutoInstall');
version_from('lib/Myco.pm'); # finds $VERSION
license('perl');
abstract('The myco object framework ');
auto_install_now();

#
# a BIG if-then
#
if ($run_tests) {
  my ($cs, $user, $passwd);

  print "\nPlease give me the credentials for a user with priveledges to create a
new test database, as well as a database name to use, though please embed it in
the form of a DBI-friendly connect string.\n";

  print "\n1) Connect string (DSN): ";
  $cs = <STDIN>;
  chop $cs;

  unless ($cs =~ m/:pg:/i) {
    print "Please note: only the PostreSQL is support\n";
  }

  print "2) Login: ";
  $user = <STDIN>;
  chop $user;

  print "3) Password: ";
  $passwd = <STDIN>;
  chop $passwd;

  print <<'MSG';

Thank you. I am going to use this information to generate 'conf/myco.conf' 
from conf/myco.conf-dist. If you have given me sensitive information, 
make sure to empty out _just_ this sensitive data only when the tests have 
been completed.
MSG

  sleep 1;

  my %config_replacements = ( DB_DSN => $cs,
			      DB_USER => $user,
			      DB_PASSWORD => $passwd, );

  my $dbname = $cs;
  $dbname =~ s/^.[^=]*=(.*)/$1/;

  if ($cs =~ m/:pg:/i) {

    $config_replacements{DB_DROP_CMD} =
      'dropdb -U ' . $user . ' ' . $dbname;
    $config_replacements{DB_CREATE_CMD} =
      'createdb -U ' . $user . ' ' . $dbname;

  }

  open CONF_DIST, 'conf/myco.conf-dist';
  my $conf_dist;
  $conf_dist .= $_ for <CONF_DIST>;
  close CONF_DIST;

  while (my ($label, $value) = each(%config_replacements) ) {
    if ($label =~ /db_create_cmd|db_drop_cmd/i) {
      # inserting an un-stringified perl data structure here
      $conf_dist =~ s/
		      (.*$label)
		      \s*
		      (\n.*)
		      /$1 "$value"$2/sx;
    } else {
      $conf_dist =~ s/
		      (.*$label)
		      \s*
		      (\n.*)
		      /$1 "$value"$2/sx;
    }
  }

  # now create working myco.conf file
  open CONF_WORKING, '>conf/myco.conf';
  print CONF_WORKING $conf_dist;
  close CONF_WORKING;

  use Cwd;
  $ENV{MYCO_ROOT} = cwd unless $ENV{MYCO_ROOT};

  print <<'MSG';

Now creating and deploying the database...
MSG

  system 'bin/myco-deploy';
  
} else {
  
  print "\n***PLEASE NOTE***\n";
  print "\nRefer to Myco::Admin for instructions on setting up a database,
or else rerun Makefile.PL and select 'Y' when asked if you
want to run the test suite, and a database will be created
for you\n\n";
}

&Makefile->write;
&Meta->write;
