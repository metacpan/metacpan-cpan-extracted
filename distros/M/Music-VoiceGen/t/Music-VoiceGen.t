#!perl

use strict;
use warnings;

use Test::Most;    # plan is down at bottom
my $deeply = \&eq_or_diff;

use Music::VoiceGen;

# pitches and intervals or possibilities must be supplied
dies_ok( sub { Music::VoiceGen->new }, 'no params set' );

# like so...
{
    my $vg =
      Music::VoiceGen->new( pitches => [qw/1 2 3/], intervals => [qw/1 2 3 4/] );
    isa_ok( $vg, 'Music::VoiceGen' );

    $deeply->( $vg->pitches,   [qw/1 2 3/],   "pitches just set" );
    $deeply->( $vg->intervals, [qw/1 2 3 4/], "intervals just set" );
    # Form: pitch1 => { choice1 => weight1, ... }, pitch2...
    $deeply->(
        $vg->possibles,
        { 1 => { 2 => 1, 3 => 1 }, 2 => { 3 => 1 } },
        "pitch destination odds"
    );

    # updates wipe out pitches & intervals by default
    $vg->update( { cat => { cat => 1 } }, preserve_pitches => 1 );
    $deeply->( $vg->possibles, { cat => { cat => 1 } }, "new pitch odds" );
    $deeply->( $vg->pitches,   [qw/1 2 3/],   "pitches still set" );
    $deeply->( $vg->intervals, [qw/1 2 3 4/], "intervals still set" );

    $vg->update( { dog => { dog => 1 } } );
    $deeply->( $vg->pitches,   [], "pitches reset" );
    $deeply->( $vg->intervals, [], "intervals reset" );
}

# or, the other way...
{
    my $ovg =
      Music::VoiceGen->new(
        possibles => { 1 => { 2 => 1, 3 => 1 }, 2 => { 3 => 1 } } );

    $deeply->( $ovg->pitches,   [], "pitches not set" );
    $deeply->( $ovg->intervals, [], "intervals not set" );
    $deeply->(
        $ovg->possibles,
        { 1 => { 2 => 1, 3 => 1 }, 2 => { 3 => 1 } },
        "pitch destination odds"
    );
}

# custom weighting of pitches and intervals
{
    my $wvg = Music::VoiceGen->new(
        pitches   => [qw/1 2 3/],
        intervals => [qw/1 -1/],
        weightfn  => sub { $_[2] < 0 ? 7 : 5 },
    );
    $deeply->(
        $wvg->possibles,
        {   1 => { 2 => 5 },
            2 => { 3 => 5, 1 => 7 },
            3 => { 2 => 7 },
        },
        "custom weights"
    );
}

# default context: like a goldfish, or a smart-phone user
{
    my $cvg = Music::VoiceGen->new( possibles => { 1 => { 1 => 1 } } );
    $deeply->( $cvg->context, [], "no context is set" );

    $cvg->rand;
    $deeply->( $cvg->context, [1], "context first" );
    # an earlier implementation could end up with n+1 or even n+m extra
    # context entries, but that should no longer be possible (unless
    # _context is directly manipulated).
    $cvg->rand;
    $deeply->( $cvg->context, [1], "context second" );
    $cvg->rand;
    $deeply->( $cvg->context, [1], "context third" );
}

# a fairly deterministic setup but good for testing things with 'rand'
# in their name (whether the randomness is random enough will depend
# on what Math::Random::Discrete does)
{
    my @cycle = qw/0 1 2/;
    my @got;
    my $bvg = Music::VoiceGen->new(
        MAX_CONTEXT => 3,
        possibles   => {
            0 => { 1 => 5 },
            1 => { 2 => 5 },
            2 => { 0 => 5 },
        },
    );

    push @got, $bvg->rand;
    cmp_deeply( $got[0], any(@cycle), "one of these" );
    $deeply->( $bvg->context, \@got, "context of the first one" );

    push @got, $bvg->rand;
    is( $got[1], ( $got[0] + 1 ) % 3, "the next one" );
    $deeply->( $bvg->context, \@got, "context first and second" );

    push @got, $bvg->rand;
    is( $got[2], ( $got[0] + 2 ) % 3, "and the next" );
    $deeply->( $bvg->context, \@got, "context with all three" );

    push @got, $bvg->rand;
    is( $got[3], ( $got[0] + 3 ) % 3, "and another..." );
    $deeply->( $bvg->context, [ @got[ 1 .. 3 ] ], "context of last three" );

    push @got, $bvg->rand;
    is( $got[4], ( $got[0] + 4 ) % 3, "who keeps doing these things??" );
    $deeply->( $bvg->context, [ @got[ 2 .. 4 ] ], "context still last three" );
}

# actual use of context with depth
{
    my $voice = Music::VoiceGen->new(
        MAX_CONTEXT => 3,
        possibles   => {
            60         => { 65 => 1 },
            "60.65"    => { 67 => 1 },
            65         => { -1 => 1 },
            "60.65.67" => { 65 => 1 },
        },
    );
    $voice->context(60);

    my @pitches;
    my $i = 10;
    while ( $i-- > 0 ) {
        push @pitches, $voice->rand;
        last if $pitches[-1] == -1;
    }
    $deeply->( \@pitches, [qw/65 67 65 -1/], "a cycle" );
}

# startfn, contextfn
{
    my $fvg = Music::VoiceGen->new(
        pitches     => [ 1 .. 100 ],
        intervals   => [-1],
        MAX_CONTEXT => 8,
        startfn     => sub { die "what does this little red button do?" },
    );
    throws_ok { $fvg->rand } qr/what does this little red button do\?/, 'boom';

    $fvg->startfn( sub { 42 } );
    is( $fvg->rand, 42, 'a proper start' );

    $fvg->contextfn(
        sub {
            my ( $choice, $mrd, $count ) = @_;
            return 9 + $count, 0;
        }
    );
    $fvg->context( [9] );
    $fvg->update(
        {   "9"       => { 42 => 1 },
            "9.10"    => { 42 => 1 },
            "10"      => { 42 => 1 },
            "9.10.11" => { 42 => 1 },
            "10.11"   => { 42 => 1 },
            "11"      => { 42 => 1 },
        }
    );
    is( $fvg->rand, 10, 'Custom Context IV' );
    is( $fvg->rand, 11, 'Custom Context V' );
    is( $fvg->rand, 12, 'Custom Context VI' );
}

# subsets!
{
    my $svg = Music::VoiceGen->new( possibles => { 1 => { 1 => 1 } } );
    my ( @subsets, %possibles );
    $svg->subsets(
        2, 4,
        sub {
            push @subsets, \@_;
            #           $possibles{ join ".", @_[0..$#_-1] }{$_[-1]}++;
        },
        [qw/65 67 69 60 62/],
    );
    $deeply->(
        \@subsets,
        [   [qw/65 67/],    [qw/65 67 69/],    [qw/65 67 69 60/], [qw/67 69/],
            [qw/67 69 60/], [qw/67 69 60 62/], [qw/69 60/],       [qw/69 60 62/],
            [qw/60 62/],
        ],
        "expected subsets"
    );
    #   use Data::Dumper; diag Dumper \%possibles;
}

plan tests => 35;
