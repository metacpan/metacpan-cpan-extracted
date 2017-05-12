use strict;
use warnings;
use Test::More;
use File::Spec;
use File::Path qw(make_path);

plan skip_all => 'these tests are for release candidate testing'
    if !$ENV{RELEASE_TESTING};

for my $prereq ( 'CPAN::Common::Index::Mirror', 'Config::INI::Reader' )
{
    eval "use $prereq; 1"
        or plan skip_all => "$prereq required for testing authors list";
}

# assume Task-CPANAuthors-Regional lives next door
# or close enough
my $dist_ini     = 'dist.ini';
my ($regional_ini) = grep -e,
    map File::Spec->catfile( @$_, 'Task-CPANAuthors-Regional' => 'dist.ini' ),
    map [ ( File::Spec->updir ) x $_ ], 1 .. 5;

plan skip_all => "Could not find dist.ini for Task-CPANAuthors"
    if !-e $dist_ini;

plan skip_all => "Could not find dist.ini for Task-CPANAuthors-Regional"
    if !$regional_ini;

plan tests => 1;

# handle the CPAN::Common::Index::Mirror cache
my $cache_dir = File::Spec->catdir( File::Spec->tmpdir, "cpan-$<" );
make_path $cache_dir unless -e $cache_dir;
my $index = CPAN::Common::Index::Mirror->new( { cache => $cache_dir } );
my $cache = $index->cached_package;
if ( time - ( stat $cache )[9] > 24 * 60 * 60 ) {
    diag "Refreshing index cache (@{[ ~~ localtime +( stat $cache )[9] ]})";
    $index->refresh_index;
}
diag "Reading packages from $cache";

my %seen;
my @latest = sort grep !$seen{$_}++,
    map { $_->{uri} =~ m{cpan:///distfile/.*/(.*)-[^-]*$} }
    $index->search_packages( { package => qr{^Acme::CPANAuthors::} } );

# get both lists
my @current;

diag "Reading modules from $dist_ini";
push @current, grep /^Acme::CPANAuthors/,
    keys %{ Config::INI::Reader->read_file($dist_ini)->{Prereqs} };

diag "Reading regional modules from $regional_ini";
push @current, grep /^Acme::CPANAuthors::/,
    keys %{ Config::INI::Reader->read_file($regional_ini)->{Prereqs} };

@current = sort map { s/::/-/g; $_ } @current;

# compare both lists
my $ok = is_deeply( \@current, \@latest, "The list matches CPAN" );

if ( !$ok ) {
    %seen = ();
    $seen{$_}++ for @latest;
    $seen{$_}-- for @current;
    diag "\nThe list of Acme::CPANAuthors modules on CPAN has changed:";
    diag( $seen{$_} > 0 ? "+ $_" : "- $_" )
        for grep $seen{$_}, sort keys %seen;
}
