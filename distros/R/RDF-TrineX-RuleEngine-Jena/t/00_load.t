use Test::More;
use File::Temp qw(tempfile);
use Test::Exception;
use Data::Dumper;
use File::Copy;

my $JENAROOT_sharefile = 'share/JENAROOT';

unless ( -s $JENAROOT_sharefile ) {
    plan skip_all => "No JENAROOT set in $JENAROOT_sharefile";
}
else {
    plan tests => 6;
}

use_ok('RDF::TrineX::RuleEngine::Jena');

my %OLD_ENV = ( JENAROOT => $ENV{JENAROOT} );
my ( $fh, $temp_fname ) = tempfile;
copy $JENAROOT_sharefile, $temp_fname;

{
    ok( my $r = RDF::TrineX::RuleEngine::Jena->new, "Load using $JENAROOT_sharefile" );

    $ENV{JENAROOT} = "" .$r->JENAROOT;
    unlink $JENAROOT_sharefile;
    ok( my $r2 = RDF::TrineX::RuleEngine::Jena->new, "Load using \$ENV{JENAROOT}" );

    $JENAROOT = $ENV{JENAROOT};
    delete $ENV{JENAROOT};
    throws_ok { RDF::TrineX::RuleEngine::Jena->new } qr'open shared file',
    'No way to determine JENAROOT';

    ok( RDF::TrineX::RuleEngine::Jena->new( JENAROOT => $JENAROOT ), "Load using explicit JENAROOT argument" );

    copy $temp_fname, $JENAROOT_sharefile;
}

{
    my $r = RDF::TrineX::RuleEngine::Jena->new;
    is( scalar $r->available_rulesets, 12, '12 available predefined rulesets' );
}
