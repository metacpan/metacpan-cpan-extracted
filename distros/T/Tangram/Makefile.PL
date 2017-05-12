use strict;

use ExtUtils::MakeMaker;

my %required =
    (
     'Set::Object' => 1.10,
     "Test::More" => 0,
     #"Date::Manip" => 0,
     "Time::Piece" => 0,
     "Class::Date" => 0,
     #"DateTime" => 0,
     "Scalar::Util" => 1.14,
     "Data::Lazy" => 0.6,
     DBI => 0,
    );

my %required_soft = map{$_=>1} qw( Class::Accessor::Assert Class::Tangram Class::Tangram::Generator YAML Time::Piece Class::Date );
my %required_hard = map{$_=>1} qw( Set::Object Scalar::Util  DBI Data::Lazy );

my ($skip_tests, $bomb_out);
while (my ($module, $min_ver) = each %required) {

    my $mod_ver = "$module".($min_ver ? " $min_ver" : "");
    eval "use $mod_ver;";
    if($@) {
	if (exists $required_hard{$module}) {
	    $bomb_out = 1;
	    print STDERR ("$mod_ver not found.\n");
	} elsif ( exists $required_soft{$module} ) {
	    print STDERR ("$mod_ver not found.  Some tests and/or "
			  ."functionality may be missing.\n");
	} else {
	    $skip_tests = 1;
	    print STDERR ("$mod_ver not found.  You will not be able "
			  ."to run the test suite.\n");
	}
    }
}

do { $skip_tests = 1; goto NOTESTS } if $skip_tests or $bomb_out;

use lib '.';

sub yes
{
    print ' (Y/n) ';
    return <STDIN> =~ /^(Y(e(s)?)?|A(YE|II+!*))?\n?$/i;
}

sub yeah_no  # it's an antipodean thing
{
    print ' (N/y) ';
    return <STDIN> =~ /^(Y(e(s)?)?|A(YE|II+!*))\n?$/i;

}

print q{Do you plan to run the test suite?
(you will need to set up an *EMPTY* database)};

do { $skip_tests = 1; goto NOTESTS } unless yes();

my $configured;

if ($ENV{TANGRAM_CONFIG})
{
   print qq{
You have set TANGRAM_CONFIG to $ENV{TANGRAM_CONFIG}.
Should I use it?};
   $configured = yes();
   unless ($ENV{TANGRAM_CONFIG} eq "t/CONFIG") {
      open TCONF, "$ENV{TANGRAM_CONFIG}"
	  or die "failed to open $ENV{TANGRAM_CONFIG} for reading; $!";
      unlink "t/CONFIG";
      open CONFIG, ">t/CONFIG"
	  or die "failed to open t/CONFIG for writing; $!";
      while (<TCONF>) { print CONFIG }
      close TCONF;
      close CONFIG;
   }
}

if (!$configured && -e 't/CONFIG')
{
   print q{
It looks like there is a 't/CONFIG' file already. It probably contains
connection information from a previous installation. Should I use it?};
   $configured = yes();
}

unless ($configured)
{
   print q{
Please give me the login and password for accessing the test database.
I must be able to create and drop tables in that database.};

   print "\n1) DBI connect string (omit the \'DBI:\' part): ";
   my $cs = <STDIN>;
   chop $cs;

   $cs = "dbi:$cs" unless $cs =~ /^dbi\:/i;

   my ($use_tx, $use_subsel, $table_type) = (1, 1);

   if ($cs =~ m/:mysql:/i) {
       print q{
You have selected the MySQL back-end.  Normally, subselects and
transactions are disabled for this database.  However, if you are
using MySQL-Max, or some other MySQL version with InnoDB support
compiled in and configured, you can enable the transaction support for
the test suite.  If you want to use it in your programs, you'll have
to set no_tx = 0 in the options to Tangram::Storage->connect() (or
hope that the auto-detection of the feature works), and table_type =
InnoDB in the Schema.  See Tangram::Schema and Tangram::Storage for
more information.

Alternatively, if you are running MySQL 4.1 or later, you can enable
sub-select tests.  It is not possible to use sub-selects with InnoDB
table types.

Use InnoDB tables};
       unless (yeah_no()) {
	   $use_tx = 0;

	   print "Use sub-selects";
	   unless (yeah_no()) {
	       $use_subsel = 0;
	   }
       } else {
	   $table_type = "InnoDB";
       }
   }

   my ($user, $passwd);
   if ( $cs =~ /:sqlite:/i ) {
       print q{
You have selected the SQLite back-end.  Sub-selects will be disabled.
};
       $use_subsel = 0;
       $user = $passwd = "";
   } else {

       print "2) Login: ";
       $user = <STDIN>;
       chop $user;

       print "3) Password: ";
       $passwd = <STDIN>;
       chop $passwd;

   }
   
   print <<'MSG';

Thank you. I am going to save this information to 't/CONFIG'.
If you have given me sensitive information, make sure to destroy
the file when the tests have been completed.
MSG

   open CONFIG, '>t/CONFIG' or die "Cannot create 't/CONFIG', reason: $!";
   print CONFIG "$cs\n$user\n$passwd\ntx_do = $use_tx\nsubselects = $use_subsel\n".($table_type?"table_type = $table_type\n":"");
   close CONFIG;
}

NOTESTS:
my $tests;
if ( $skip_tests ) {
    print "TEST SUITE IS DISABLED\n";
    $tests = "t/no_tests.t";
} else {
    eval "use Test::Manifest";


    if ( $@ ) {
	open TESTS, "<t/test_manifest" or die $!;
	$tests = join " ", map { chomp; "t/$_" } <TESTS>;
	close TESTS;
    }

    else {
	* ExtUtils::MM_Any::test_via_harness = sub
	    {
		my($self, $perl, $tests) = @_;

		return (qq|\t$perl "-MTest::Manifest" | .
			qq|"-e" "run_t_manifest(\$(TEST_VERBOSE), |.
			qq|'\$(INST_LIB)', | .
			qq|'\$(INST_ARCHLIB)')"\n|);
	    };
    }
}

# all this ... just to skip delivering one file!
use File::Find;
my %PM;
find(sub {
       m/\.(pod|pm)$/ && do {
	 my $src = $File::Find::name;
	 (my $targ = $src) =~ s{lib}{\$(INST_LIBDIR)};
         ($PM{$src} = $targ);
       };
    }, "lib");

WriteMakefile(
	      'NAME'	=> 'Tangram',
	      'VERSION_FROM' => 'lib/Tangram.pm', # finds $VERSION
	      PREREQ_PM => \%required,
	      PM => \%PM,
	      test => { TESTS => $tests },
);
