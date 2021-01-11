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

my $dist_ini     = 'dist.ini';

plan skip_all => "Could not find dist.ini for Task-Git-Repository"
    if !-e $dist_ini;

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
my @latest = sort
    map $_->{package},
    grep !$seen{ $_->{uri} }++,
    $index->search_packages( { package => qr{^Git::Repository::Plugin::} } );

# get both lists
my @current;

diag "Reading modules from $dist_ini";
push @current, grep /^Git::Repository::Plugin::/,
    keys %{ Config::INI::Reader->read_file($dist_ini)->{Prereqs} };

@current = sort @current;

# compare both lists
my $ok = is_deeply( \@current, \@latest, "The list matches CPAN" );

if ( !$ok ) {
    %seen = ();
    $seen{$_}++ for @latest;
    $seen{$_}-- for @current;
    diag "\nThe list of Git::Repository::Plugin:: modules on CPAN has changed:";
    diag( $seen{$_} > 0 ? "+ $_" : "- $_" )
        for grep $seen{$_}, sort keys %seen;
}
