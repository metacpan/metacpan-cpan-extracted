use strict;
use warnings;
use Test::More;
use File::Spec;
use Cwd;
use Papery::Pulp;

# generate full filenames
my $dir = File::Spec->catdir( 't', 'analyzer' );
my $src = cwd;

# minimum metadata
my %basic = ( _processors => {} );

# test data
my @files = (
    [   'zlonk.txt',
        { %basic, theme => 'batman', count => 3 },
        "zlott powie thwacke"
    ],
    [ 'bam.txt', {%basic}, "thwapp eee_yow ker_sploosh", ],
    [ 'kapow.txt', { %basic, theme => 'barbapapa', count => 0 } ],
);
@files = map { $_->[0] = File::Spec->catfile( $dir, $_->[0] ); $_ } @files;

plan tests => 3 * @files + 2;

# test success
for my $test (@files) {
    my ( $File, $Meta, $Text ) = @$test;
    my $pulp = Papery::Pulp->new( { %basic, __source => $src } );
    $pulp->analyze_file($File);

    # remove internal Papery variables
    delete $pulp->{meta}{$_} for grep {/^__/} keys %{ $pulp->{meta} };
    ok( delete $pulp->{meta}{_source}, "_source $File" );

    # testing one-liners to avoid \n issues
    chomp $pulp->{meta}{_text} if $pulp->{meta}{_text};
    is_deeply( delete $pulp->{meta}{_text}, $Text, "text $File" );
    is_deeply( $pulp->{meta},               $Meta, "meta $File" );
}

# test failure
my $pulp = Papery::Pulp->new( { %basic, __source => $src } );
ok( !eval { $pulp->analyze_file( 'notthere' ); 1 },
    'Fail with non-existent file' );
like( $@, qr/^Can't open notthere: /, 'Expected error message' );

