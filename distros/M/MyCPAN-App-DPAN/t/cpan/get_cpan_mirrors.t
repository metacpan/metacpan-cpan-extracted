use strict;
use warnings;

use Test::More 'no_plan';
use Test::Without;

use Cwd;
use File::Spec::Functions;

my $class = 'MyCPAN::App::DPAN::CPANUtils';

use_ok( $class );
can_ok( $class, qw( get_cpan_mirrors pull_latest_whois ) );

my @mirrors = $class->get_cpan_mirrors;
diag( "Mirrors are @mirrors" );

run {
	my $logger = Local::Null::Logger->new;
	my $result = $class->pull_latest_whois( cwd(), $logger );
	ok( ! defined $result, "pull_latest_whois returns undef without LWP::Simple" );
	like( $logger->output, qr/You need LWP::Simple/, "Error message for missing LWP::Simple" );
	$logger->clear_output;
	} without 'LWP::Simple';

{
my $logger = Local::Null::Logger->new;
my $directory = catfile( qw(t notthere gone fictitous) );
ok( ! -e $directory, "Missing directory does not exist (good)" );
my $result = $class->pull_latest_whois( $directory, $logger );
ok( ! defined $result, "pull_latest_whois returns undef with bad directory" );
like( $logger->output, qr/does not exist/, "Error message for missing LWP::Simple" );
$logger->clear_output;
}

{
diag( "You need to be online and able to reach a CPAN mirror for this step" );
diag( "You can set the NOT_ONLINE environment variable to say you aren't" );
skip "You said you aren't online", 3 if defined $ENV{NOT_ONLINE};
my $logger = Local::Null::Logger->new;
my $result = $class->pull_latest_whois( cwd(), $logger );
ok( defined $result, "pull_latest_whois returns defined when it works" );
diag( $logger->output );
is( $result, 2, "pull_latest_whois returns the number of files it downloaded" );
$logger->clear_output;
}

BEGIN {
package Local::Null::Logger;
use Test::More;
use vars qw($AUTOLOAD);

my $scalar = '';
sub new          { bless \ $scalar, $_[0] }
sub warn         { $scalar .= $_[1] . "\n" }
sub info         { diag( $_[1] . "\n" ) }
sub output       { $scalar }
sub clear_output { $scalar = '' }
sub AUTOLOAD     { $scalar .= $_[1] }
sub DESTROY      { 1 }
}

1;
