
# $Id$

use strict;
use warnings;
use Test::More tests => 44;
use Env qw($TEST_VERBOSE);

use_ok 'Perl::Critic::Policy::logicLAB::RequireVersionFormat';

require Perl::Critic;

my $critic = Perl::Critic->new(
    '-profile'       => 't/example.conf',
    '-single-policy' => 'logicLAB::RequireVersionFormat'
);
{
    my $str = q[$VERSION = '0.0.1'];
    
    my @violations = $critic->critique( \$str );
    
    is(scalar @violations, 0);
}

$critic = Perl::Critic->new(
    '-profile'       => '',
    '-single-policy' => 'logicLAB::RequireVersionFormat'
);
{
    my @p = $critic->policies;
    is( scalar @p, 1, 'single policy RequireVersionFormat' );

    my $policy = $p[0];
}


#some examples lifted from:
#http://search.cpan.org/~elliotjs/Perl-Critic-1.105/lib/Perl/Critic/Policy/Modules/RequireVersionVar.pm

my @lines = <DATA>;
my $i = 1;
foreach (@lines) {
    my ($want_count, $str) = split /\t/;
    my @violations = $critic->critique( \$str );
    foreach (@violations) {
        is( $_->description, q{"$VERSION" variable not conforming} );
        
        if (0) {
            warn "$str: $_->description\n";
        }
    }
    is( scalar @violations, $want_count, "$i: statement: $str" );

    if ($TEST_VERBOSE) {
        if ($want_count) {
            warn "$str does not conform\n";
        } else {
            warn "$str conforms\n";
        }
    }

    $i++;
}

exit 0;

__DATA__
0	our $VERSION = "0.01";}
0	$VERSION = "0.01";
0	our $VERSION = '0.01_1';
0	$VERSION = '0.01_1';
0	our $VERSION = '0.01';
0	$VERSION = '0.01';
0	our $VERSION = 0.01;
0	$VERSION = 0.01;
0	our $VERSION = 1.0611;
0	$MyPackage::VERSION = 1.061;
0	use vars qw($VERSION);
0	use version; our $VERSION = qv(1.0611);
0	Readonly our $VERSION = 1.0;
0	Readonly::Scalar our $VERSION = 1.0;
1	our ($VERSION) = '$Revision$' =~ m{ \$Revision: \s+ (\S+) }x;
0	our $VERSION = $Other::VERSION;
1	our $VERSION = "0.0.1";
1	$VERSION = "0.0.1";
1	our $VERSION = '0.0.1';
1	$VERSION = '0.0.1';
1	our $VERSION = 0.0.1;
1	$VERSION = 0.0.1;
1	our $VERSION = 1.0.611;
1	$MyPackage::VERSION = 1.0.61;
1	use version; our $VERSION = qv(1.0.611);
1	Readonly our $VERSION = 1.0.1;
1	our $VERSION = "0.01a";
1	$VERSION = "0.01a";
