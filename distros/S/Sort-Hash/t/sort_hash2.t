use Test::More;    #tests => 8;
use Test::Warn;
use Test::Warnings;
use Test::Exception;

#use Carp::Always;

use 5.008;

BEGIN { use_ok(Sort::Hash); }

my %AlphaHash = (
    utopians    => 'transferrer',
    humiliation => 'alligators',
    Woodwards   => 'shift',
    cataclysmic => 'evaluative',
    deposition  => 'ruling',
    checksummed => 'Cuzco',
    VAXes       => 'practicality',
    Knox        => 'repress',
    adhering    => 'euphemisms',
    lends       => 'symphony',
);
my %IntegerHash = (
    Bela         => 1289,
    poses        => 6431,
    murmurer     => 3119,
    handcuffs    => 4274,
    drive        => 5612,
    Emmett       => 6709,
    gayness      => 9522,
    Ceylon       => 87,
    walked       => 441,
    digitization => 503
);

my %FloatHash = (
    Bela         => 128.9,
    poses        => 6431,
    murmurer     => 311.9,
    handcuffs    => 4.274,
    drive        => 561.2,
    Emmett       => 6709,
    gayness      => 95.22,
    Ceylon       => 87.00,
    walked       => 441,
    digitization => 503
);

my %MixedHash = (
    Jugoslavia => 'slate crater',
    validating => 'screeching',
    elks       => 'siphoning',
    Boarsh     => 'Boarsh impend Kirov.',
    treat      => 517,
    removals   => 211.06,
    Calais     => 'symmetrically',
    Boone      => 'Symmetricall thumbing the Boone Harp.',
);

my @AlphaHashResult = sort_hash( \%AlphaHash, 'alpha' );
my @AlphaHashExpect = (
    qw /humiliation checksummed adhering cataclysmic
        VAXes Knox deposition Woodwards lends utopians/
);
is( "@AlphaHashResult", "@AlphaHashExpect", 'sort of %AlphaHash' );

my @IntegerHashResult = sort_hash( \%IntegerHash );
my @IntegerHashExpect = (
    qw/Ceylon walked digitization Bela murmurer handcuffs
        drive poses Emmett gayness/
);
is( "@IntegerHashResult", "@IntegerHashExpect",
    'Default (Asc) sort for %IntegerHash' );
@IntegerHashResult = sort_hash( 'desc', \%IntegerHash );
@IntegerHashExpect = (
    qw/ gayness Emmett poses drive handcuffs murmurer Bela
        digitization walked Ceylon/
);
is( "@IntegerHashResult", "@IntegerHashExpect",
    'desc sort for %IntegerHash passed as hash' );

my @FloatHashExpect = (
    qw/handcuffs Ceylon gayness Bela murmurer walked digitization drive
        poses Emmett/
);
my @FloatHashResult_Numeric = sort_hash( \%FloatHash );
my @IntegerHashResult_Alpha = sort_hash( \%IntegerHash, 'alpha' );
my @FloatHashResult_Alpha   = sort_hash( 'alpha', \%FloatHash  );

my @MixedHashExpect
    = (qw/removals treat Boarsh validating elks Jugoslavia Boone Calais/);
my @MixedHashResult = sort_hash( \%MixedHash, 'alpha' );
is( "@MixedHashResult", "@MixedHashExpect", 'Mixed Hash Alpha Sort' );

is( "@FloatHashResult_Numeric", "@FloatHashExpect",
    'Numeric Sort of Hash with Floating Point Values' );
isnt( "@IntegerHashResult_Alpha", "@IntegerHashExpect",
          'Demonstrate that Alpha Sort of Integer Hash '
        . 'Will not return the correct result.' );
isnt( "@FloatHashResult_Alpha", "@FloatHashExpect",
          'Demonstrate that Alpha Sort of Floating Point Hash '
        . 'Will not return the correct result.' );

note('Testing Error conditions');
isnt( sort_hash( {} ), undef, 'Empty hash doesnt return undef' );
my @emptysorted = sort_hash( {} );
is( scalar @emptysorted,
    0, 'There are no values returned from sorting an empty hash.' );
dies_ok( sub { sort_hash( {}, 'noempty' ) },
    'With noempty, empty hashref dies instead of returning nothing' );

my $numeric_death = 'Attempt to Sort non-Numeric values in a Numeric Sort';
throws_ok(
    sub { sort_hash( \%MixedHash, qw /numeric/ ) },
    qr /$numeric_death/,
    "attempt to use numeric sort on mixed hash throws $numeric_death"
);

note('Test Warnings when nofatal is set');
warning_is { sort_hash( \%MixedHash, qw /numeric nofatal/ ) }
'Attempt to Sort non-Numeric values in a Numeric Sort',
    'Mixed Hash Attempt to Sort non-Numeric values in a Numeric Sort fails';

# note( q/next two tests will generate a warning by performin an invalid
# operation while silent is in effect, then test that there was no warning./);
my @sorted_bad = sort_hash( \%MixedHash, qw /numeric nofatal silent/ );
is( scalar(@sorted_bad), 0, 'no data was returned but silent is on' );
#had_no_warnings( 'no data was returned but silent is on' );
warning_is { sort_hash( \%MixedHash, qw /numeric nofatal silent/ ) }
        undef,
        'No warning when silent is on' ;

warning_is { sort_hash( \%MixedHash, qw /strictalpha nofatal/ ) }
'Attempt to Sort Numeric Value in Strict Alpha Sort',
    'Mixed Hash Attempt to Sort Numeric in Strict Alpha fails';

done_testing();
