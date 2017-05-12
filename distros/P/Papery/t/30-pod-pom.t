use strict;
use warnings;
use Test::More;
use File::Spec;
use Cwd;
use Papery::Pulp;

my $can_pod_pom = eval 'use Papery::Processor::Pod::POM; 1;';

plan skip_all => 'Can\'t load Papery::Processor::Pod::POM'
    if !$can_pod_pom;

plan tests => 2;

# generate full filenames
my $dir = File::Spec->catdir( 't', 'processor' );
my $src = cwd;

# minimum metadata
my %basic = (
    _processors  => {},
    _processor   => 'Pod::POM',
    pod_pom_view => 'Pod::POM::View::Pod'
);

my $pulp = Papery::Pulp->new( { %basic, __source => $src } );
$pulp->analyze_file( File::Spec->catfile( $dir, 'zlonk.pod' ) );
$pulp->process();

my $pod = $pulp->{meta}{_text};
$pod =~ s/.*(?==head1)//s;
$pod =~ s/=cut.*//s;

is( $pulp->{meta}{_content}, $pod,        'Got the POD back' );
is( $pulp->{meta}{pod_meta}, 'some meta', 'Got the metadata' );

