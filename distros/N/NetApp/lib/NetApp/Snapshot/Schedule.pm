
package NetApp::Snapshot::Schedule;

our $VERSION = '500.002';
$VERSION = eval $VERSION;  ##  no critic: StringyEval

use strict;
use warnings;
use Carp;

use Class::Std;
use Params::Validate qw( :all );

{

    my %parent_of		:ATTR( get => 'parent' );
    my %weekly_of		:ATTR( get => 'weekly' );
    my %daily_of		:ATTR( get => 'daily' );
    my %hourly_of		:ATTR( get => 'hourly' );
    my %hourlist_of		:ATTR;

    sub BUILD {

        my ($self,$ident,$args_ref) = @_;

        my @args = %$args_ref;

        my (%args) 	= validate( @args, {
            parent	=> { type	=> OBJECT },
            weekly	=> { type	=> SCALAR },
            daily	=> { type	=> SCALAR },
            hourly	=> { type	=> SCALAR },
            hourlist	=> { type	=> ARRAYREF,
                             default	=> [],
                             optional	=> 1 },
        });

        $parent_of{$ident}	= $args{parent};
        $weekly_of{$ident}	= $args{weekly};
        $daily_of{$ident}	= $args{daily};
        $hourly_of{$ident}	= $args{hourly};
        $hourlist_of{$ident}	= $args{hourlist};

    }

    sub get_hourlist {
        return @{ $hourlist_of{ident shift} };
    }

}

sub _parse_snap_sched {

    my $class		= shift;
    my $line		= shift;

    my ($weekly,$daily,$hourly,$hourlist) = (split( /[@\s]+/, $line ))[2..5];

    if ( $hourlist ) {
        $hourlist	= [ split( /,/, $hourlist ) ];
    } else {
        $hourlist	= [];
    }

    if ( $weekly !~ /^\d+$/ || $daily !~ /^\d+$/ || $hourly !~ /^\d+$/ ) {
        croak("Unable to parse snap sched: $line\n");
    }

    return {
        weekly		=> $weekly,
        daily		=> $daily,
        hourly		=> $hourly,
        hourlist	=> $hourlist,
    };

}

1;
