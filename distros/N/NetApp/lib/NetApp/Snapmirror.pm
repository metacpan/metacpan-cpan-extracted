
package NetApp::Snapmirror;

our $VERSION = '500.002';
$VERSION = eval $VERSION;  ##  no critic: StringyEval

use strict;
use warnings;
use English;
use Carp;

use Class::Std;
use Params::Validate qw( :all );
use Regexp::Common;

use NetApp::Snapmirror::Source;
use NetApp::Snapmirror::Destination;

{

    my %filer_of		:ATTR( get => 'filer' );

    my %source_of		:ATTR( get => 'source' );
    my %destination_of		:ATTR( get => 'destination' );

    my %status_of		:ATTR( get => 'status' );
    my %progress_of		:ATTR( get => 'progress' );
    my %state_of		:ATTR( get => 'state' );
    my %lag_of			:ATTR( get => 'lag' );

    my %mirror_timestamp_of	:ATTR( get => 'mirror_timestamp' );
    my %base_snapshot_of	:ATTR( get => 'base_snapshot' );
    my %current_transfer_type_of
        :ATTR( get => 'current_transfer_type' );
    my %current_transfer_error_of
        :ATTR( get => 'current_transfer_error' );
    my %contents_of		:ATTR( get => 'contents' );
    my %last_transfer_type_of
        :ATTR( get => 'last_transfer_type' );
    my %last_transfer_size_of
        :ATTR( get => 'last_transfer_size' );
    my %last_transfer_duration_of
        :ATTR( get => 'last_transfer_duration' );
    my %last_transfer_from_of
        :ATTR( get => 'last_transfer_from' );

    sub BUILD {

        my ($self,$ident,$args_ref) = @_;

        my @args = %$args_ref;

        my (%args) 		= validate( @args, {
            filer		=> { isa	=> 'NetApp::Filer' },
            source		=> { type	=> HASHREF,
                                     optional	=> 1 },
            destination		=> { type	=> HASHREF },
            status		=> { type	=> SCALAR },
            progress		=> { type	=> SCALAR },
            state		=> { type	=> SCALAR },
            lag			=> { type	=> SCALAR },
            mirror_timestamp	=> { type	=> SCALAR },
            base_snapshot	=> { type	=> SCALAR },
            current_transfer_type => { type	=> SCALAR },
            current_transfer_error => { type	=> SCALAR },
            contents		=> { type	=> SCALAR },
            last_transfer_type	=> { type	=> SCALAR },
            last_transfer_size	=> { type	=> SCALAR },
            last_transfer_duration => { type	=> SCALAR },
            last_transfer_from	=> { type	=> SCALAR },
        });        

        $filer_of{$ident}	= $args{filer};

        if ( $args{source} ) {
            $source_of{$ident}	=
                NetApp::Snapmirror::Source->new( $args{source} );
        }

        $destination_of{$ident} =
            NetApp::Snapmirror::Destination->new( $args{destination} );

        $status_of{$ident}		= $args{status};
        $progress_of{$ident}		= $args{progress};
        $state_of{$ident}		= $args{state};
        $lag_of{$ident}			= $args{lag};
        $mirror_timestamp_of{$ident} 	= $args{mirror_timestamp};
        $base_snapshot_of{$ident} 	= $args{base_snapshot};
        $current_transfer_type_of{$ident} = $args{current_transfer_type};
        $current_transfer_error_of{$ident} = $args{current_transfer_error};
        $contents_of{$ident} 		= $args{contents};
        $last_transfer_type_of{$ident} 	= $args{last_transfer_type};
        $last_transfer_size_of{$ident}  = $args{last_transfer_size};
        $last_transfer_duration_of{$ident} = $args{last_transfer_duration};
        $last_transfer_from_of{$ident}  = $args{last_transfer_from};

    }

}

sub _parse_snapmirror_status {

    my $class		= shift;

    my (%args)		= validate( @_, {
        snapmirror	=> { type	=> HASHREF },
        line		=> { type	=> SCALAR },
    });

    my $snapmirror	= $args{snapmirror};
    my $line		= $args{line};

    my ($key,$value)	= split( /:\s+/, $line, 2 );

    # 'Last Transfer Type' => 'last_transfer_type'
    $key		=~ s/\s/_/g;
    $key		= lc($key);

    if ( $value eq '-' ) {
        $value		= '';
    }

    if ( $key eq 'source' || $key eq 'destination' ) {
        if ( my ($hostname,$volume) = split( /:/, $value ) ) {
            $snapmirror->{$key}	= {
                hostname	=> $hostname,
                volume		=> $volume,
            };
        }
    } else {
        $snapmirror->{$key}	= $value;
    }

    return $snapmirror;

}

1;
