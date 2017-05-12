#!perl

use strict;
use warnings;

use File::Basename;
use File::Path;
use File::Spec;
use Test::More;
use Cwd;
use Clone qw(clone);

use YAML::Any qw(LoadFile DumpFile);

use DBI;
use SQL::Parser;

use Report::Generator;

my $dir = File::Spec->catdir( getcwd(), 'test_output' );

rmtree $dir; END { rmtree $dir }
mkpath $dir;

my $examples = File::Spec->catdir( getcwd(), 'examples' );

my $example_yamls = File::Spec->catfile( $examples, '*.yml' );
foreach my $yml (glob($example_yamls))
{
    my $tgtfn = File::Spec->catfile( $dir, File::Basename::basename($yml) );
    my $testyml = LoadFile($yml);
    $testyml->{"Report::Generator::Render::TT2"}->{output} = File::Spec->catfile( $dir,
	$testyml->{"Report::Generator::Render::TT2"}->{output} );
    $testyml->{"Report::Generator::Render::TT2"}->{template} = File::Spec->catfile( $examples,
	$testyml->{"Report::Generator::Render::TT2"}->{template} );
    DumpFile( $tgtfn, $testyml );
}

my $output1 = File::Spec->catfile( $dir, 'demots.csv' );
my $output = File::Spec->catfile( $dir, 'demo.csv' );
my %cfg = (
     renderer => 'Report::Generator::Render::TT2',
     'Report::Generator::Render::TT2' => {
	 config => { ABSOLUTE => 1, INCLUDE_PATH => [File::Spec->catdir( getcwd(), 'share' ) ], },
	 output => $output1,
	 vars => { },
	 template => File::Spec->catfile( $examples, 'test1.tt2' ),
	 options => {},
     },
     post_processing => $^X . ' -e ' . quotemeta("use File::Copy 'move'; move('$output1', '$output');"),
);

my  $repgen = Report::Generator->new({cfg => clone(\%cfg)});
ok( $repgen->generate(), "Generate from \%cfg" ) or diag( $repgen->{error} );

my  $sysdbh = DBI->connect( "DBI:Sys:", undef, undef, {} );
my  $syssth = $sysdbh->prepare( 'SELECT * FROM alltables ORDER BY table_name' );
    $syssth->execute();
my  @sysrows = $syssth->fetchall_arrayref();

my  $csvdbh = DBI->connect( "DBI:CSV:", undef, undef, {
	f_dir    => $dir,
	f_ext    => '.csv/r',
	csv_null => 1,
    });
my  $csvsth = $csvdbh->prepare( 'SELECT * FROM demo ORDER BY table_name' );
    $csvsth->execute();
my  @csvrows = $csvsth->fetchall_arrayref();

is_deeply( \@csvrows, \@sysrows, "Generated CSV table matches" );

$cfg{'Report::Generator::Render::TT2'}->{vars}->{ADD_TIMESTAMP} = 1;
delete $cfg{post_processing};

    $repgen = Report::Generator->new({cfg => clone(\%cfg)});
ok( $repgen->generate(), "Generate from \%cfg with timestamps" ) or diag( $repgen->{error} );

    $csvsth = $csvdbh->prepare( 'SELECT DISTINCT timestamp FROM demots' );
    $csvsth->execute();
    @csvrows = $csvsth->fetchall_arrayref();

is( scalar @csvrows, 1, "Have a unique time stamp" );

    $repgen = Report::Generator->new({cfg => File::Spec->catfile( $dir, 'test2cfg.yml' ) });
ok( $repgen->generate(), "Generate from test2cfg.yml" ) or diag( $repgen->{error} );

SKIP:
{
    my $demosql = File::Spec->catfile( $dir, "demo.sql" );
    ok( -f $demosql, "file demo.sql exists" ) or skip( "Cannot prove SQL syntax without generated file", 1 );
    my $sqlparser = SQL::Parser->new( 'CSV', { PrintError => 0, RaiseError => 0, } );
    my $fh;
    my ( $proved_lines, $parsed_lines ) = ( 0, 0 );
    open( $fh, "<", $demosql );
    while( my $sqlline = <$fh> )
    {
	chomp $sqlline;
	next if( '' eq $sqlline );
	++$proved_lines;
	unless( $sqlparser->parse( $sqlline ) )
	{
	    diag( "Error parsing <$sqlline>: " . $sqlparser->{struct}->{errstr} );
	}
	else
	{
	    ++$parsed_lines;
	}
    }
    is( $proved_lines, $parsed_lines, "All SQL lines parsed" );
}

    $repgen = Report::Generator->new({cfg => File::Spec->catfile( $dir, 'test3cfg.yml' ) });
ok( $repgen->generate(), "Generate from test3cfg.yml" ) or diag( $repgen->{error} );

$@ = undef;
eval {
    require Template::Plugin::Latex;
};

unless( $@ )
{
	$repgen = Report::Generator->new({cfg => File::Spec->catfile( $dir, 'test4cfg.yml' ) });
    ok( $repgen->generate(), "Generate from test4cfg.yml" ) or diag( $repgen->{error} );
}

done_testing();
