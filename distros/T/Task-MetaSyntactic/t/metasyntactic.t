use strict;
use warnings;
use Test::More;
use File::Path qw( make_path );

plan skip_all => 'these tests are for release candidate testing'
    if !$ENV{RELEASE_TESTING};

plan skip_all => "CPAN::Common::Index::Mirror required for this test"
    if !eval "use CPAN::Common::Index::Mirror; 1";

plan tests    => 1;

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
    grep $_->{package} !~ /^Acme::MetaSyntactic::test_wlb_meta$/,
    $index->search_packages( { package => qr{^Acme::MetaSyntactic::[a-z]} } );

# get the current prereqs
my %pack2dist = qw( Acme-MetaSyntactic-xkcdcommon1949 Crypt-XKCDCommon1949 );
my @current   = sort
    map exists $pack2dist{$_} ? $pack2dist{$_} : $_,
    map { s/::/-/g; $_ }
    grep /^Acme::MetaSyntactic/,
    split m{$/}, `dzil listdeps`;

# compare both lists
my $ok = is_deeply( \@current, \@latest, "The prereq list matches CPAN" );

if ( !$ok ) {
    %seen = ();
    $seen{$_}++ for @latest;
    $seen{$_}-- for @current;
    diag "\nThe list of Acme::CPANAuthors modules on CPAN has changed:";
    diag( $seen{$_} > 0 ? "+ $_" : "- $_" )
        for grep $seen{$_}, sort keys %seen;
}

