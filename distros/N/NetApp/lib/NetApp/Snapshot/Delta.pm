
package NetApp::Snapshot::Delta;

our $VERSION = '500.002';
$VERSION = eval $VERSION;  ##  no critic: StringyEval

use strict;
use warnings;
use Carp;

use Class::Std;
use Params::Validate qw( :all );

{

    my %from_of			:ATTR( get => 'from' );
    my %to_of			:ATTR( get => 'to' );
    my %changed_of		:ATTR( get => 'changed' );
    my %time_of			:ATTR( get => 'time' );
    my %rate_of			:ATTR( get => 'rate' );
    my %summary_of		:ATTR( get => 'summary' );

    sub BUILD {

        my ($self,$ident,$args_ref) = @_;

        my @args = %$args_ref;

        my (%args) 	= validate( @args, {
            from	=> { type	=> SCALAR },
            to		=> { type	=> SCALAR },
            changed	=> { type	=> SCALAR },
            time	=> { type	=> SCALAR },
            rate	=> { type	=> SCALAR },
            summary	=> { type	=> SCALAR },
        });

        $from_of{$ident}	= $args{from};
        $to_of{$ident}		= $args{to};
        $changed_of{$ident}	= $args{changed};
        $time_of{$ident}	= $args{time};
        $rate_of{$ident}	= $args{rate};
        $summary_of{$ident}	= $args{summary};

    }

    sub is_summary {
        return shift->get_summary;
    }

}

sub _parse_snap_delta {

    my $class		= shift;
    my $line		= shift;

    $line		=~ s/Active File System/active/g;

    my @line		= split /\s+/, $line;

    my $from		= shift @line;
    my $to		= shift @line;
    my $changed		= shift @line;
    my $time		= shift @line;
    my $next		= shift @line;
    my $rate;

    if ( $next		=~ /^\d{2}:\d{2}$/ ) {
        $time		.= " $next";
        $rate		= shift @line;
    } else {
        $rate		= $next;
    }

    if ( @line || ! defined $from || ! defined $to ||
             ! defined $changed || ! defined $time || ! defined $rate ) {
        croak("Unable to parse snapshot delta: $line\n");
    }

    return {
        from		=> $from,
        to		=> $to,
        changed		=> $changed,
        time		=> $time,
        rate		=> $rate,
    };

}

1;
