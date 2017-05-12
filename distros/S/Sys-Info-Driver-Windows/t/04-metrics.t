#/usr/bin/env perl
use strict;
use warnings;
use Test::More qw(no_plan);
use Sys::Info::Driver::Windows qw( :all);
use Data::Dumper;

use constant EXPECT_SM_TABLETPC    => 86;
use constant EXPECT_SM_MEDIACENTER => 87;
use constant EXPECT_SM_STARTER     => 88;
use constant EXPECT_SM_SERVERR2    => 89;

is( SM_TABLETPC   , EXPECT_SM_TABLETPC   , 'Test SM_TABLETPC'    );
is( SM_MEDIACENTER, EXPECT_SM_MEDIACENTER, 'Test SM_MEDIACENTER' );
is( SM_STARTER    , EXPECT_SM_STARTER    , 'Test SM_STARTER'     );
is( SM_SERVERR2   , EXPECT_SM_SERVERR2   , 'Test SM_SERVERR2'    );

foreach my $const ( SM_TABLETPC, SM_MEDIACENTER, SM_SERVERR2, SM_STARTER ) {
    # ok if this does not die :)
    GetSystemMetrics( $const );
    ok(1, "Able to call GetSystemMetrics( $const )");
}

ok( my %si = GetSystemInfo(), 'Able to get system information' );

my $sid = Data::Dumper->new( [ \%si ], [ '*SYSTEM_INFO' ] );
diag $sid->Dump;

diag sprintf "CPU: %s Family %s Model %s Stepping %s\n",
            @si{qw/
                wProcessorArchitecture2
                wProcessorLevel
                wProcessorModel
                wProcessorStepping
            /};

diag sprintf "Minimum Application Address: %lx\n", $si{lpMinimumApplicationAddress};
diag sprintf "Maximum Application Address: %lx\n", $si{lpMaximumApplicationAddress};

my %feat = CPUFeatures();
my $d    = Data::Dumper->new([\%feat],['*FEATURES']);

diag $d->Dump;

ok( defined $feat{$_}, "$_ CPU Feature defined" )
    for qw(
        APICPhysicalID
        BrandIndex
        BrandString
        CLFLUSHcachelinesize
        CPLQualifiedDebugStore
        Count
        CpuFeatures
        ExIds
        Extendedfamily
        Extendedmodel
        Family
        FeatureFlags
        FeatureInfo
        Flags
        Ids
        KFBits
        L2Associativity
        L2CacheLineSize
        L2CacheSizeK
        MONITOR_MWAIT
        Model
        ProcessorType
        SSE3NewInstructions
        SteppingID
        String
        ThermalMonitor2
        ____ebx
        ____ecx
    );

ok( 1, 'The END' );

1;

__END__
