# -*- perl -*-

use strict; use warnings;

# Note: we don't use Helper here. Should we?
use Test::More;
use English;

BEGIN {
    $ENV{PERL_RL} = 'Perl5';	# force to use Term::ReadLine::Perl5
    $ENV{LANG} = 'C';
    $ENV{'COLUMNS'} = 80;
    $ENV{'LINES'} = 25;
    # stop reading ~/.inputrc
    $ENV{'INPUTRC'} = '/dev/null';
}

sub run_filename_list($;$) {
    my ($pat, $no_test_exist) = @_;
    my @results  = Term::ReadLine::Perl5::readline::rl_filename_list($pat);
    unless ($no_test_exist) {
	foreach my $file (@results) {
	    ok(-e $file, "returned $file should exist")
	}
    }
    return @results;
}

use Cwd;
use Term::ReadLine::Perl5;


my $verbose = @ARGV && ($ARGV[0] eq 'verbose');
my @results;

note('rl_filename_list');

@results  = run_filename_list(cwd);
ok(@results, "should get a result expanding cwd");

@results  = run_filename_list(__FILE__);
cmp_ok(scalar @results, '>', 0, 'Get at least one expansion');
is($results[0], __FILE__, 'First entry should match what we passed in');

note('Assume that whoever is logged in to run this has a home directory');

if ($Term::ReadLine::Perl5::readline::have_getpwent) {
    my $name = getpwuid($<); my $tilde_name = '~' . $name;

    @results  = run_filename_list($tilde_name, 1);
    cmp_ok(scalar(@results), '>', 0, "Expansion for my login $tilde_name");

    my @results2  = run_filename_list('~');
    cmp_ok(scalar(@results), '>', 0, "Expansion for my login $tilde_name");

  SKIP: {
      skip 'Until BINGOS gets back to us', 1;
      # Home directory could have a trailing "/"; remove that;
      my $irs_save = $INPUT_RECORD_SEPARATOR; $INPUT_RECORD_SEPARATOR = '/';
      chomp $results[0]; chomp $results2[0];
      $INPUT_RECORD_SEPARATOR = $irs_save;

      # Home directory could be a symbolic link. Make sure each is a
      # directory
      unless ( -l $results[0] || -l $results2[0] ) {
	  is_deeply(\@results2, \@results,
		    "Expanding ~ should be the same as $tilde_name");
      }
    }
}

done_testing();
