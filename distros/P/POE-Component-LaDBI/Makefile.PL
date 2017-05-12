use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

require v5.6.0;

use strict;
use Data::Dumper;

our $BASE_CFG_FN;
our $NO_DB_TESTS_FN;
require "ladbi_config.pl";

if (read_answer_yes("Do you want to test this module against a Database?"))
  {
    unlink($NO_DB_TESTS_FN);
    my $build_config_p = 1;
    my ($cfg);

    if (-e $BASE_CFG_FN) {
      print "A config file was found...\n";
      if (-r $BASE_CFG_FN) {
	if ($cfg = read_config_file($BASE_CFG_FN)) {
	  if (config_ok($cfg)) {
	    print display_config($cfg);
	    $build_config_p = 0 if read_answer_yes("Do you want to use the current config?")
	  } else {
	    print "...but it was not a valid config\n";
	  }
	}
      } else {
	print "...but it wasn't readable\n";
      }
    }

    build_config_file($BASE_CFG_FN) if $build_config_p;
  }
else
  {
    create_file($NO_DB_TESTS_FN)
      or die "Failed to create empty file $NO_DB_TESTS_FN";
  }



#exit 0;

WriteMakefile(
    'NAME'		=> 'POE::Component::LaDBI',
    'VERSION_FROM'	=> 'lib/POE/Component/LaDBI.pm', # finds $VERSION
    'PREREQ_PM'		=> {
			    DBI => '1.20',
			    POE => '0.18'
                           },
    'realclean'         => { FILES => 'NO_DB_TESTS config.pcf *.log' },
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'lib/POE/Component/LaDBI.pm', 
       AUTHOR     => 'A. U. Thor <a.u.thor@a.galaxy.far.far.away>') : ()),
);

exit 0;

sub build_config_file {
  my ($fn) = @_;
  my ($cfg);

  print "\nBUILDING CONFIG FILE\n";
  do {

    print <<"EOM1";

Enter the DSN. This is the same as the data source value you would pass
to a DBI->connect() call. It needs to specify a database where the
username (next prompt) can create a table, modify that table, and delete
that table (the table will be named 'ladbi_test'. All the values
will be stored in file named $BASE_CFG_FN.
Example: DSN => dbi:Pg:dbname=test
EOM1
    $cfg->{DSN}    = read_answer_nonzero("DSN    => ");

    print <<"EOM2";

Enter the username to access the database.
EOM2
    $cfg->{USER}   = read_answer_nonzero("USER   => ");

    print <<"EOM3";

Enter the password for the above username. Remember to delete the file
$BASE_CFG_FN after the tests run.
EOM3
  READ_PASSWD:
    $cfg->{PASSWD} = read_answer("PASSWD => ");
    if (length($cfg->{PASSWD}) == 0) {
      goto READ_PASSWD
	unless read_answer_yes("Your password is empty, is that OK?");
    }

  } until config_ok($cfg);
  print "\n";

  open(CFG, ">$fn")
    or die "Failed to open $fn to write config";

  print CFG Dumper($cfg);

  close(CFG);

}

sub config_ok {
  my ($cfg) = @_;
  return unless ref($cfg) eq 'HASH';
  # allow PASSWD to be empty
  for my $k (qw(DSN USER)) {
    return unless exists $cfg->{$k};
    my $v = $cfg->{$k};
    $v =~ s/^\s*//;
    $v =~ s/\s*$//;
    return unless length($v) > 0;
  }
  return 1;
}

sub display_config {
  my ($cfg) = @_;
  return <<"EOD";
DSN        = "$cfg->{DSN}"
USER       = "$cfg->{USER}"
PASSWD     = "$cfg->{PASSWD}"
EOD
}

sub read_config_file {
  my ($fn) = @_;
  my ($cfg);
  if (-r $fn)
    {
      eval { $cfg = do $fn; };
      if ($@) {
	warn "failed to parse current config file, $fn\n";
	return;
      }

      return $cfg;
    }
  warn "file, $fn, is not readable\n";
  return;
}


sub get_answer {
  my $ans = <STDIN>;
  chomp $ans;
  $ans;
}

sub read_answer_yes {
  my ($question) = @_;
  chomp $question;
  while (1) {
    print $question, " [Y/n] ";
    my $ans = get_answer();
    $ans =~ s/\s//g;
    return 1 unless length($ans) > 0;
    if ($ans =~ /^[Yy]/) {
      return 1;
    }
    if ($ans =~ /^[Nn]/) {
      return 0;
    }
  }
}

sub read_answer {
  my ($prompt) = @_;
  chomp $prompt;
  print $prompt;
  my $ans = get_answer();
  $ans =~ s/^\s*//;
  $ans =~ s/\s*$//;
  return $ans;
}

sub read_answer_nonzero {
  my ($prompt) = @_;
  chomp $prompt;
  my ($ans);
  while (!$ans) {
    print $prompt;
    $ans = get_answer();
    $ans =~ s/^\s*//;
    $ans =~ s/\s*$//;
  }
  return $ans;
}

sub create_file {
  my ($fn) = @_;
  open(TMP_FH, ">$fn") or return;
  close(TMP_FH);
  return 1;
}
