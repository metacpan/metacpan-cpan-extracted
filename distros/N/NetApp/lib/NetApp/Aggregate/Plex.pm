
package NetApp::Aggregate::Plex;

our $VERSION = '500.002';
$VERSION = eval $VERSION;  ##  no critic: StringyEval

use strict;
use warnings;
use English;
use Carp;

use Class::Std;
use Params::Validate qw( :all );
use Regexp::Common;

{

    my %name_of		:ATTR( get => 'name' );
    my %state_of	:ATTR;

    my %raidgroups_of	:ATTR;

    sub BUILD {

        my ($self,$ident,$args_ref) = @_;

        my @args = %$args_ref;

        my (%args) 	= validate( @args, {
            name	=> { type	=> SCALAR },
            state	=> { type	=> HASHREF },
            raidgroups	=> { type	=> ARRAYREF },
        });

        $name_of{$ident}	= $args{name};
        $state_of{$ident}	= $args{state};

        $raidgroups_of{$ident}	= [];

        foreach my $raidgroup ( @{ $args{raidgroups} } ) {
            push @{ $raidgroups_of{$ident} },
                NetApp::Aggregate::RAIDGroup->new( $raidgroup );
        }

    }

    sub get_raidgroups {
        my $self	= shift;
        my $ident	= ident $self;
        return @{ $raidgroups_of{$ident} };
    }

    sub get_states {
        return keys %{ $state_of{ident shift} };
    }

    sub get_state {
        
        my $self     	= shift;
        my $ident	= ident $self;
        my $state	= shift;

        return $state_of{$ident}->{$state};

    }

}

1;
