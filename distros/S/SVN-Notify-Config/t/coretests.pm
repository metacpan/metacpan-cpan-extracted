#!/usr/bin/perl 
use Test::More;
use Test::Deep;
use YAML qw/LoadFile Load Dump/;
use SVN::Notify;
use Cwd;
use Config;
my $SECURE_PERL_PATH = $Config{perlpath};
if ($^O ne 'VMS') {
    $SECURE_PERL_PATH.= $Config{_exe}
	unless $SECURE_PERL_PATH =~ m/$Config{_exe}$/i;
}
my $PWD = getcwd;
my $USER = $ENV{USER};
my $SVNLOOK  = $ENV{SVNLOOK}  || SVN::Notify->find_exe('svnlook');
my $SVNADMIN = $ENV{SVNADMIN} || SVN::Notify->find_exe('svnadmin');
my $SENDMAIL = SVN::Notify->find_exe('sendmail');

if ( !defined($SVNLOOK) ) {
    plan skip_all => "Cannot find svnlook!\n".
    "Please start the tests like this:\n".
    "  SVNLOOK=/path/to/svnlook make test";
}
elsif ( !defined($SVNADMIN) ) {
    plan skip_all => "Cannot find svnadmin!\n".
    "Please start the tests like this:\n".
    "  SVNADMIN=/path/to/svnadmin make test";
}
else {
    plan no_plan;
}

my $repos_path = "$PWD/t/test-repos";

my @results = ();

sub reset_all_tests {
    create_test_repos();
}

sub initialize_results {
    @results = LoadFile("$PWD/t/".shift);
    foreach my $result ( @results ) {
	next if $result =~ /empty/;
	$result = [$result] unless ref($result) eq 'ARRAY';
    }
}

# Create a repository fill it with sample values the first time through
sub create_test_repos {
    unless ( -d $repos_path ) {
	system(<<"") == 0 or die "system failed: $?";
$SVNADMIN create $repos_path

	system(<<"") == 0 or die "system failed: $?";
$SVNADMIN load --quiet $repos_path < ${repos_path}.dump

    }
}

sub run_tests {
    my $command = shift;
    my $TESTER;
    my $rsync_test = 0;

    for (my $rev = 1; $rev <= $#results; $rev++) {
	my %args = @_;
	# Common to all tests
	$args{'repos-path'} = $repos_path;
	$args{'revision'} = $rev;

	my $change = $results[$rev];
	next unless $change;
	
	_test(
	    $change, 
	    $command, 
	    %args
	);
    }

}

sub _test {
    my ($expected, $command, %args) = @_;
    my $test;

    $ENV{'TZ'} = 'EST5EDT'; # fix for RT#22704
    open $TESTER, '-|', _build_command($command, %args);
    while (<$TESTER>) {
	next if /--- YAML/;
	$test .= $_;
    }
    close $TESTER;

    my @test = Load($test);

    if ( @test ) {
	for (my $i=0; $i <= $#test; $i++) {
	    cmp_deeply($test[$i], superhashof($expected->[$i]), 
	    "All object properties match at rev: " . $args{revision});
	}
    } 
    elsif ( $expected =~ /empty/ ) {
	pass "No changes at rev: " . $args{revision};
    }
    else { # failure path
	fail "Failed to produce expected results at rev: " .
	$args{revision};
    }
}

sub _build_command {
    my ($command, %args) = @_;
    $command =~ s/^perl/$SECURE_PERL_PATH/;
    my @commandline = split " ", $command;

    push @commandline, $args{'repos-path'}, $args{'revision'};
    return @commandline;
}

1; # magic return
